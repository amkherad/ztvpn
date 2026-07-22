import 'dart:async';
import 'dart:io';

import '../models/proxy_models.dart';
import 'http_proxy_service.dart';
import 'shadowsocks_service.dart';
import 'system_proxy_service.dart';

/// Orchestrates proxy services, system proxy configuration, and connection state.
class ConnectionManager {
  ConnectionManager({
    SystemProxyService? systemProxyService,
  }) : _systemProxy = systemProxyService ?? SystemProxyService();

  final SystemProxyService _systemProxy;
  final _controller = StreamController<ConnectionInfo>.broadcast();

  ConnectionInfo _info = const ConnectionInfo();
  HttpProxyService? _httpProxy;
  ShadowsocksService? _shadowsocks;
  Timer? _trafficTimer;

  Stream<ConnectionInfo> get stream => _controller.stream;
  ConnectionInfo get info => _info;

  void _emit(ConnectionInfo info) {
    _info = info;
    _controller.add(info);
  }

  Future<void> connect(ProxyProfile profile) async {
    if (_info.isBusy || _info.isConnected) {
      await disconnect();
    }

    _emit(_info.copyWith(
      status: ConnectionStatus.connecting,
      activeProfile: profile,
      clearError: true,
    ));

    try {
      final localPort = await _findAvailablePort(profile.localPort);

      final activeProfile = profile.copyWith(localPort: localPort);

      switch (profile.type) {
        case ProxyType.httpProxy:
          _httpProxy = HttpProxyService(
            activeProfile,
            onTraffic: _onTraffic,
          );
          await _httpProxy!.start();
        case ProxyType.shadowsocks:
          _shadowsocks = ShadowsocksService(
            activeProfile,
            onTraffic: _onTraffic,
          );
          await _shadowsocks!.start();
      }

      if (profile.systemProxy && _isDesktop) {
        await _systemProxy.enable(localPort, type: profile.type);
      }

      _trafficTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _emit(_info),
      );

      _emit(_info.copyWith(
        status: ConnectionStatus.connected,
        activeProfile: activeProfile,
        localAddress: '127.0.0.1:$localPort',
        connectedSince: DateTime.now(),
        bytesSent: 0,
        bytesReceived: 0,
        clearError: true,
      ));
    } catch (e) {
      await _cleanup();
      _emit(_info.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
        clearProfile: true,
      ));
    }
  }

  Future<void> disconnect() async {
    if (_info.status == ConnectionStatus.disconnected) return;

    _emit(_info.copyWith(status: ConnectionStatus.disconnecting));

    await _cleanup();

    _emit(const ConnectionInfo(status: ConnectionStatus.disconnected));
  }

  Future<void> _cleanup() async {
    _trafficTimer?.cancel();
    _trafficTimer = null;

    if (_systemProxy.isEnabled) {
      await _systemProxy.disable();
    }

    await _httpProxy?.stop();
    await _shadowsocks?.stop();
    _httpProxy = null;
    _shadowsocks = null;
  }

  void _onTraffic(int sent, int received) {
    _emit(_info.copyWith(bytesSent: sent, bytesReceived: received));
  }

  Future<int> _findAvailablePort(int preferred) async {
    for (var port = preferred; port < preferred + 100; port++) {
      try {
        final socket = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          port,
          shared: true,
        );
        await socket.close();
        return port;
      } catch (_) {
        continue;
      }
    }
    throw Exception('No available local port found.');
  }

  bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  void dispose() {
    _trafficTimer?.cancel();
    _controller.close();
    _cleanup();
  }
}
