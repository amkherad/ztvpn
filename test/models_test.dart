import 'package:flutter_test/flutter_test.dart';
import 'package:zero_trust_client/models/proxy_models.dart';

void main() {
  test('ProxyProfile serializes and deserializes', () {
    final profile = ProxyProfile(
      name: 'Test',
      type: ProxyType.shadowsocks,
      host: '1.2.3.4',
      port: 8388,
      password: 'secret',
      method: 'aes-256-gcm',
    );

    final restored = ProxyProfile.fromJson(profile.toJson());
    expect(restored.name, profile.name);
    expect(restored.type, profile.type);
    expect(restored.host, profile.host);
    expect(restored.port, profile.port);
  });

  test('ProxyType resolves from id', () {
    expect(ProxyType.fromId('http'), ProxyType.httpProxy);
    expect(ProxyType.fromId('ss'), ProxyType.shadowsocks);
  });
}
