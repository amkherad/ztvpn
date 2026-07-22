import 'dart:io';

import '../models/proxy_models.dart';

/// Configures OS-level proxy settings to route system traffic
/// through the local proxy listener.
class SystemProxyService {
  bool _enabled = false;
  int? _port;

  bool get isEnabled => _enabled;
  int? get port => _port;

  Future<void> enable(int port, {required ProxyType type}) async {
    if (Platform.isLinux) {
      await _enableLinux(port, type: type);
    } else if (Platform.isWindows) {
      await _enableWindows(port);
    } else if (Platform.isMacOS) {
      await _enableMacOS(port, type: type);
    } else {
      throw UnsupportedError(
        'System-wide proxy is only supported on desktop platforms.',
      );
    }
    _enabled = true;
    _port = port;
  }

  Future<void> disable() async {
    if (!_enabled) return;

    if (Platform.isLinux) {
      await _disableLinux();
    } else if (Platform.isWindows) {
      await _disableWindows();
    } else if (Platform.isMacOS) {
      await _disableMacOS();
    }

    _enabled = false;
    _port = null;
  }

  Future<void> _enableLinux(int port, {required ProxyType type}) async {
    const host = '127.0.0.1';
    await _run('gsettings', [
      'set',
      'org.gnome.system.proxy',
      'mode',
      'manual',
    ]);

    if (type == ProxyType.shadowsocks) {
      await _run('gsettings', [
        'set',
        'org.gnome.system.proxy.socks',
        'host',
        host,
      ]);
      await _run('gsettings', [
        'set',
        'org.gnome.system.proxy.socks',
        'port',
        '$port',
      ]);
    } else {
      await _run('gsettings', [
        'set',
        'org.gnome.system.proxy.http',
        'host',
        host,
      ]);
      await _run('gsettings', [
        'set',
        'org.gnome.system.proxy.http',
        'port',
        '$port',
      ]);
      await _run('gsettings', [
        'set',
        'org.gnome.system.proxy.https',
        'host',
        host,
      ]);
      await _run('gsettings', [
        'set',
        'org.gnome.system.proxy.https',
        'port',
        '$port',
      ]);
    }

    await _run('gsettings', [
      'set',
      'org.gnome.system.proxy',
      'ignore-hosts',
      "['localhost', '127.0.0.0/8', '::1']",
    ]);
  }

  Future<void> _disableLinux() async {
    await _run('gsettings', [
      'set',
      'org.gnome.system.proxy',
      'mode',
      'none',
    ]);
  }

  Future<void> _enableWindows(int port) async {
    await _run('reg', [
      'add',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v',
      'ProxyEnable',
      '/t',
      'REG_DWORD',
      '/d',
      '1',
      '/f',
    ]);
    await _run('reg', [
      'add',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v',
      'ProxyServer',
      '/t',
      'REG_SZ',
      '/d',
      '127.0.0.1:$port',
      '/f',
    ]);
    await _run('netsh', [
      'winhttp',
      'set',
      'proxy',
      '127.0.0.1:$port',
    ]);
  }

  Future<void> _disableWindows() async {
    await _run('reg', [
      'add',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v',
      'ProxyEnable',
      '/t',
      'REG_DWORD',
      '/d',
      '0',
      '/f',
    ]);
    await _run('netsh', ['winhttp', 'reset', 'proxy']);
  }

  Future<void> _enableMacOS(int port, {required ProxyType type}) async {
    final services = await _getMacNetworkServices();
    for (final service in services) {
      if (type == ProxyType.shadowsocks) {
        await _run('networksetup', [
          '-setsocksfirewallproxy',
          service,
          '127.0.0.1',
          '$port',
        ]);
      } else {
        await _run('networksetup', [
          '-setwebproxy',
          service,
          '127.0.0.1',
          '$port',
        ]);
        await _run('networksetup', [
          '-setsecurewebproxy',
          service,
          '127.0.0.1',
          '$port',
        ]);
      }
    }
  }

  Future<void> _disableMacOS() async {
    final services = await _getMacNetworkServices();
    for (final service in services) {
      await _run('networksetup', ['-setwebproxystate', service, 'off']);
      await _run('networksetup', ['-setsecurewebproxystate', service, 'off']);
      await _run('networksetup', ['-setsocksfirewallproxystate', service, 'off']);
    }
  }

  Future<List<String>> _getMacNetworkServices() async {
    final result = await Process.run('networksetup', ['-listallnetworkservices']);
    if (result.exitCode != 0) return ['Wi-Fi'];

    return (result.stdout as String)
        .split('\n')
        .skip(1)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('*'))
        .toList();
  }

  Future<void> _run(String command, List<String> args) async {
    final result = await Process.run(command, args);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to configure system proxy ($command): ${result.stderr}',
      );
    }
  }
}
