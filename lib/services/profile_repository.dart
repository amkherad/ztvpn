import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/proxy_models.dart';

/// Persists proxy profiles to local storage.
class ProfileRepository {
  static const _storageKey = 'zero_trust_profiles';

  Future<List<ProxyProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map((item) => ProxyProfile.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<void> saveProfiles(List<ProxyProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = profiles.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> addProfile(ProxyProfile profile) async {
    final profiles = await loadProfiles();
    profiles.add(profile);
    await saveProfiles(profiles);
  }

  Future<void> updateProfile(ProxyProfile profile) async {
    final profiles = await loadProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
      await saveProfiles(profiles);
    }
  }

  Future<void> deleteProfile(String id) async {
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == id);
    await saveProfiles(profiles);
  }

  List<ProxyProfile> defaultProfiles() {
    return [
      ProxyProfile(
        name: 'Local HTTP Proxy',
        type: ProxyType.httpProxy,
        host: '127.0.0.1',
        port: 8080,
        localPort: 10808,
        systemProxy: true,
      ),
      ProxyProfile(
        name: 'Shadowsocks Server',
        type: ProxyType.shadowsocks,
        host: 'example.com',
        port: 8388,
        password: 'your-password',
        method: 'aes-256-gcm',
        localPort: 10808,
        systemProxy: true,
      ),
    ];
  }

  Future<void> ensureDefaults() async {
    final profiles = await loadProfiles();
    if (profiles.isEmpty && kDebugMode) {
      await saveProfiles(defaultProfiles());
    }
  }
}
