import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/proxy_models.dart';

typedef TrafficCallback = void Function(int sent, int received);

/// Local HTTP proxy that forwards traffic to an upstream HTTP proxy server.
class HttpProxyService {
  HttpServer? _server;
  final ProxyProfile _profile;
  final TrafficCallback? onTraffic;

  HttpProxyService(this._profile, {this.onTraffic});

  int get localPort => _profile.localPort;

  Future<void> start() async {
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      _profile.localPort,
      shared: true,
    );

    unawaited(_server!.listen(_handleRequest).asFuture());
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method == 'CONNECT') {
        await _handleConnect(request);
      } else {
        await _handleHttp(request);
      }
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.badGateway
        ..write('Proxy error: $e')
        ..close();
    }
  }

  Future<void> _handleConnect(HttpRequest request) async {
    final target = request.uri.authority;
    if (target.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final parts = target.split(':');
    final host = parts[0];
    final port = parts.length > 1 ? int.parse(parts[1]) : 443;

    final upstream = await Socket.connect(_profile.host, _profile.port);
    _writeConnectRequest(upstream, host, port);

    request.response.statusCode = HttpStatus.ok;
    await request.response.flush();

    final clientSocket = await request.response.detachSocket();
    await _relay(clientSocket, upstream);
  }

  Future<void> _handleHttp(HttpRequest request) async {
    final client = HttpClient();
    client.findProxy = (_) => 'PROXY ${_profile.host}:${_profile.port}';

    if (_profile.username != null && _profile.password != null) {
      final credentials = base64Encode(
        utf8.encode('${_profile.username}:${_profile.password}'),
      );
      client.addProxyCredentials(
        _profile.host,
        _profile.port,
        '',
        HttpClientBasicCredentials(_profile.username!, _profile.password!),
      );
      request.headers.set('Proxy-Authorization', 'Basic $credentials');
    }

    final uri = request.requestedUri;
    final proxyRequest = await client.openUrl(request.method, uri);

    request.headers.forEach((name, values) {
      if (!_hopByHopHeaders.contains(name.toLowerCase())) {
        for (final value in values) {
          proxyRequest.headers.set(name, value);
        }
      }
    });

    await request.pipe(proxyRequest);
    final proxyResponse = await proxyRequest.close();

    request.response.statusCode = proxyResponse.statusCode;
    proxyResponse.headers.forEach((name, values) {
      for (final value in values) {
        request.response.headers.add(name, value);
      }
    });

    await proxyResponse.pipe(request.response);
  }

  void _writeConnectRequest(Socket socket, String host, int port) {
    final buffer = StringBuffer('CONNECT $host:$port HTTP/1.1\r\n');
    buffer.write('Host: $host:$port\r\n');

    if (_profile.username != null && _profile.password != null) {
      final credentials = base64Encode(
        utf8.encode('${_profile.username}:${_profile.password}'),
      );
      buffer.write('Proxy-Authorization: Basic $credentials\r\n');
    }

    buffer.write('\r\n');
    socket.write(buffer.toString());
  }

  Future<void> _relay(Socket a, Socket b) async {
    final completer = Completer<void>();
    var sent = 0;
    var received = 0;

    void pump(Stream<Uint8List> from, Socket to, {required bool outbound}) {
      from.listen(
        (data) {
          to.add(data);
          if (outbound) {
            sent += data.length;
          } else {
            received += data.length;
          }
          onTraffic?.call(sent, received);
        },
        onDone: () => to.close(),
        onError: (_) => to.close(),
        cancelOnError: true,
      );
    }

    pump(a, b, outbound: true);
    pump(b, a, outbound: false);

    a.done.then((_) {
      if (!completer.isCompleted) completer.complete();
    });
    b.done.then((_) {
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future;
  }

  static const _hopByHopHeaders = {
    'connection',
    'keep-alive',
    'proxy-authenticate',
    'proxy-authorization',
    'te',
    'trailers',
    'transfer-encoding',
    'upgrade',
  };
}
