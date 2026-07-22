import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

import '../models/proxy_models.dart';

typedef TrafficCallback = void Function(int sent, int received);

/// Local SOCKS5 server that tunnels traffic through a Shadowsocks server.
class ShadowsocksService {
  ShadowsocksService(this._profile, {this.onTraffic});

  final ProxyProfile _profile;
  final TrafficCallback? onTraffic;

  ServerSocket? _server;
  late final ShadowsocksCipher _cipher;

  int get localPort => _profile.localPort;

  Future<void> start() async {
    final method = _profile.method ?? 'aes-256-gcm';
    final password = _profile.password ?? '';
    _cipher = ShadowsocksCipher(method, password);

    _server = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      _profile.localPort,
      shared: true,
    );

    unawaited(_server!.listen(_handleClient).asFuture());
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  Future<void> _handleClient(Socket client) async {
    final reader = _SocketReader(client);
    try {
      final handshake = await reader.readExact(2);
      if (handshake[0] != 0x05) {
        client.close();
        return;
      }

      final nMethods = handshake[1];
      await reader.readExact(nMethods);
      client.add([0x05, 0x00]);

      final request = await reader.readExact(4);
      if (request[1] != 0x01) {
        client.add(_socksReply(0x07));
        client.close();
        return;
      }

      late String host;
      late int port;

      switch (request[3]) {
        case 0x01:
          final addr = await reader.readExact(4);
          host = addr.map((b) => '$b').join('.');
        case 0x03:
          final len = (await reader.readExact(1))[0];
          host = utf8.decode(await reader.readExact(len));
        case 0x04:
          final addr = await reader.readExact(16);
          host = _formatIpv6(addr);
        default:
          client.add(_socksReply(0x08));
          client.close();
          return;
      }

      final portBytes = await reader.readExact(2);
      port = (portBytes[0] << 8) | portBytes[1];

      client.add(_socksReply(0x00));

      final remote = await Socket.connect(_profile.host, _profile.port);
      final targetPayload = _buildTargetAddress(host, port);
      final encrypted = _cipher.encrypt(targetPayload);
      remote.add(encrypted);

      reader.finishHandshake();
      await _relay(reader, remote);
    } catch (_) {
      client.close();
    } finally {
      reader.dispose();
    }
  }

  Uint8List _buildTargetAddress(String host, int port) {
    final buffer = BytesBuilder();
    if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) {
      buffer.addByte(0x01);
      buffer.add(_parseIpv4(host));
    } else if (host.contains(':')) {
      buffer.addByte(0x04);
      buffer.add(_parseIpv6(host));
    } else {
      final hostBytes = utf8.encode(host);
      buffer.addByte(0x03);
      buffer.addByte(hostBytes.length);
      buffer.add(hostBytes);
    }
    buffer.addByte((port >> 8) & 0xFF);
    buffer.addByte(port & 0xFF);
    return buffer.toBytes();
  }

  Uint8List _parseIpv4(String host) {
    return Uint8List.fromList(host.split('.').map(int.parse).toList());
  }

  Uint8List _parseIpv6(String host) {
    final expanded = _expandIpv6(host);
    final parts = expanded.split(':');
    final bytes = <int>[];
    for (final part in parts) {
      final value = int.parse(part, radix: 16);
      bytes.add((value >> 8) & 0xFF);
      bytes.add(value & 0xFF);
    }
    return Uint8List.fromList(bytes);
  }

  String _expandIpv6(String host) {
    if (!host.contains('::')) return host;
    final sides = host.split('::');
    final left = sides[0].isEmpty ? <String>[] : sides[0].split(':');
    final right = sides.length > 1 && sides[1].isNotEmpty
        ? sides[1].split(':')
        : <String>[];
    final missing = 8 - left.length - right.length;
    final middle = List.filled(missing, '0000');
    return [...left, ...middle, ...right].map((p) => p.padLeft(4, '0')).join(':');
  }

  String _formatIpv6(Uint8List bytes) {
    final parts = <String>[];
    for (var i = 0; i < bytes.length; i += 2) {
      parts.add(((bytes[i] << 8) | bytes[i + 1]).toRadixString(16));
    }
    return parts.join(':');
  }

  Uint8List _socksReply(int status) {
    return Uint8List.fromList([0x05, status, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
  }

  Future<void> _relay(_SocketReader reader, Socket remote) async {
    final completer = Completer<void>();
    var sent = 0;
    var received = 0;
    final remoteDecoder = _cipher.createStreamDecoder();

    reader.stream.listen(
      (data) {
        final encrypted = _cipher.encrypt(Uint8List.fromList(data));
        remote.add(encrypted);
        sent += data.length;
        onTraffic?.call(sent, received);
      },
      onDone: () => remote.close(),
      onError: (_) => remote.close(),
    );

    remote.listen(
      (data) {
        final decrypted = remoteDecoder.process(data);
        reader.socket.add(decrypted);
        received += decrypted.length;
        onTraffic?.call(sent, received);
      },
      onDone: () => reader.socket.close(),
      onError: (_) => reader.socket.close(),
    );

    reader.socket.done.then((_) {
      if (!completer.isCompleted) completer.complete();
    });
    remote.done.then((_) {
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future;
  }
}

/// Buffers socket reads so handshake and relay share one subscription.
class _SocketReader {
  _SocketReader(this.socket) {
    _sub = socket.listen(
      _onData,
      onDone: () {
        _controller.close();
        for (final waiter in _waiters) {
          if (!waiter.completer.isCompleted) {
            waiter.completer.completeError(
              const SocketException('Connection closed'),
            );
          }
        }
        _waiters.clear();
      },
      onError: (e) {
        _controller.addError(e);
        for (final waiter in _waiters) {
          if (!waiter.completer.isCompleted) {
            waiter.completer.completeError(e);
          }
        }
        _waiters.clear();
      },
    );
  }

  final Socket socket;
  final _buffer = BytesBuilder();
  final _waiters = <_ReadWaiter>[];
  final _controller = StreamController<List<int>>();
  late final StreamSubscription<Uint8List> _sub;
  bool _handshakeDone = false;

  Stream<List<int>> get stream => _controller.stream;

  Future<Uint8List> readExact(int length) {
    if (_handshakeDone) {
      throw StateError('Cannot readExact after handshake');
    }
    final waiter = _ReadWaiter(length);
    _waiters.add(waiter);
    _drainWaiters();
    return waiter.completer.future;
  }

  void finishHandshake() {
    _handshakeDone = true;
    if (_buffer.isNotEmpty) {
      _controller.add(_buffer.toBytes());
      _buffer.clear();
    }
  }

  void _onData(Uint8List data) {
    if (!_handshakeDone) {
      _buffer.add(data);
      _drainWaiters();
      return;
    }
    _controller.add(data);
  }

  void _drainWaiters() {
    for (final waiter in List<_ReadWaiter>.from(_waiters)) {
      if (_buffer.length < waiter.length) continue;

      final bytes = _buffer.toBytes();
      final result = Uint8List.fromList(bytes.sublist(0, waiter.length));
      _buffer.clear();
      if (bytes.length > waiter.length) {
        _buffer.add(bytes.sublist(waiter.length));
      }

      _waiters.remove(waiter);
      if (!waiter.completer.isCompleted) {
        waiter.completer.complete(result);
      }
    }
  }

  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}

class _ReadWaiter {
  _ReadWaiter(this.length);
  final int length;
  final completer = Completer<Uint8List>();
}

/// Shadowsocks AEAD cipher implementation.
class ShadowsocksCipher {
  ShadowsocksCipher(this.method, this.password) {
    _key = _evpBytesToKey(password, _saltLength);
  }

  final String method;
  final String password;
  late final Uint8List _key;
  final _random = Random.secure();

  static const _saltLength = 32;

  Uint8List encrypt(Uint8List plaintext) {
    if (method.contains('gcm')) {
      return _encryptAead(plaintext);
    }
    throw UnsupportedError('Cipher $method is not supported yet.');
  }

  StreamDecoder createStreamDecoder() => _AeadStreamDecoder(method, _key);

  Uint8List _encryptAead(Uint8List plaintext) {
    final salt = _randomBytes(_saltLength);
    final subkey = _hkdfSha1(salt, _key, 'ss-subkey'.codeUnits, 32);
    final nonce = Uint8List(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(subkey),
          128,
          nonce,
          Uint8List.fromList([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        ),
      );

    final output = Uint8List(cipher.getOutputSize(plaintext.length));
    var len = cipher.processBytes(plaintext, 0, plaintext.length, output, 0);
    len += cipher.doFinal(output, len);

    final tag = output.sublist(len - 16);
    final encrypted = output.sublist(0, len - 16);

    final lengthBuf = Uint8List(2)
      ..buffer.asByteData().setUint16(0, encrypted.length + 16, Endian.big);

    final result = BytesBuilder();
    result.add(salt);
    result.add(lengthBuf);
    result.add(encrypted);
    result.add(tag);
    return result.toBytes();
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List.generate(length, (_) => _random.nextInt(256)),
    );
  }

  Uint8List _evpBytesToKey(String password, int keyLen) {
    final result = <int>[];
    var prev = <int>[];
    while (result.length < keyLen) {
      final data = <int>[...prev, ...utf8.encode(password)];
      prev = md5.convert(data).bytes;
      result.addAll(prev);
    }
    return Uint8List.fromList(result.sublist(0, keyLen));
  }

  Uint8List _hkdfSha1(
    Uint8List salt,
    Uint8List ikm,
    List<int> info,
    int length,
  ) {
    final hmac = Hmac(sha1, salt);
    final prk = Uint8List.fromList(hmac.convert(ikm).bytes);
    final hmacPrk = Hmac(sha1, prk);
    final okm = <int>[];
    var t = <int>[];
    var counter = 1;
    while (okm.length < length) {
      final input = [...t, ...info, counter];
      t = hmacPrk.convert(input).bytes;
      okm.addAll(t);
      counter++;
    }
    return Uint8List.fromList(okm.sublist(0, length));
  }
}

class StreamDecoder {
  Uint8List process(Uint8List data) => data;
}

class _AeadStreamDecoder extends StreamDecoder {
  _AeadStreamDecoder(this.method, this.masterKey);

  final String method;
  final Uint8List masterKey;
  Uint8List? _subkey;
  final _buffer = BytesBuilder();
  int _nonceCounter = 0;

  @override
  Uint8List process(Uint8List data) {
    _buffer.add(data);
    final output = BytesBuilder();

    while (true) {
      final bytes = _buffer.toBytes();
      if (_subkey == null) {
        if (bytes.length < 32) return output.toBytes();
        final salt = Uint8List.fromList(bytes.sublist(0, 32));
        _subkey = _hkdfSha1(salt, masterKey, 'ss-subkey'.codeUnits, 32);
        _buffer.clear();
        _buffer.add(bytes.sublist(32));
        continue;
      }

      final buf = _buffer.toBytes();
      if (buf.length < 2) return output.toBytes();

      final length = ByteData.sublistView(Uint8List.fromList(buf.sublist(0, 2)))
          .getUint16(0, Endian.big);
      final frameSize = 2 + length;
      if (buf.length < frameSize) return output.toBytes();

      final frame = Uint8List.fromList(buf.sublist(2, frameSize));
      _buffer.clear();
      _buffer.add(buf.sublist(frameSize));

      final ciphertext = frame.sublist(0, frame.length - 16);
      final tag = frame.sublist(frame.length - 16);
      final nonce = Uint8List(12);
      ByteData.sublistView(nonce).setUint32(8, _nonceCounter, Endian.big);
      _nonceCounter++;

      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(_subkey!),
            128,
            nonce,
            Uint8List.fromList([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
          ),
        );

      final input = BytesBuilder()..add(ciphertext)..add(tag);
      final inputBytes = input.toBytes();
      final decrypted = Uint8List(cipher.getOutputSize(inputBytes.length));
      var len = cipher.processBytes(
        inputBytes,
        0,
        inputBytes.length,
        decrypted,
        0,
      );
      len += cipher.doFinal(decrypted, len);
      output.add(decrypted.sublist(0, len));
    }
  }

  Uint8List _hkdfSha1(
    Uint8List salt,
    Uint8List ikm,
    List<int> info,
    int length,
  ) {
    final hmac = Hmac(sha1, salt);
    final prk = Uint8List.fromList(hmac.convert(ikm).bytes);
    final hmacPrk = Hmac(sha1, prk);
    final okm = <int>[];
    var t = <int>[];
    var counter = 1;
    while (okm.length < length) {
      final input = [...t, ...info, counter];
      t = hmacPrk.convert(input).bytes;
      okm.addAll(t);
      counter++;
    }
    return Uint8List.fromList(okm.sublist(0, length));
  }
}
