import 'package:flutter/material.dart';

import '../../models/proxy_models.dart';
import '../../services/connection_manager.dart';
import '../../services/profile_repository.dart';

class AppState extends ChangeNotifier {
  AppState({
    ProfileRepository? profileRepository,
    ConnectionManager? connectionManager,
  })  : _profiles = ProfileRepository(),
        _connection = ConnectionManager() {
    _init();
  }

  final ProfileRepository _profiles;
  final ConnectionManager _connection;

  List<ProxyProfile> profiles = [];
  ConnectionInfo connection = const ConnectionInfo();
  ProxyProfile? selectedProfile;
  bool loading = true;

  Future<void> _init() async {
    await _profiles.ensureDefaults();
    profiles = await _profiles.loadProfiles();
    selectedProfile = profiles.isNotEmpty ? profiles.first : null;
    loading = false;

    _connection.stream.listen((info) {
      connection = info;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> connect() async {
    if (selectedProfile == null) return;
    await _connection.connect(selectedProfile!);
  }

  Future<void> disconnect() async {
    await _connection.disconnect();
  }

  Future<void> toggleConnection() async {
    if (connection.isConnected || connection.isBusy) {
      await disconnect();
    } else {
      await connect();
    }
  }

  void selectProfile(ProxyProfile profile) {
    selectedProfile = profile;
    notifyListeners();
  }

  Future<void> saveProfile(ProxyProfile profile) async {
    final exists = profiles.any((p) => p.id == profile.id);
    if (exists) {
      await _profiles.updateProfile(profile);
      profiles = await _profiles.loadProfiles();
    } else {
      await _profiles.addProfile(profile);
      profiles = await _profiles.loadProfiles();
    }
    selectedProfile = profile;
    notifyListeners();
  }

  Future<void> deleteProfile(ProxyProfile profile) async {
    if (connection.activeProfile?.id == profile.id) {
      await disconnect();
    }
    await _profiles.deleteProfile(profile.id);
    profiles = await _profiles.loadProfiles();
    if (selectedProfile?.id == profile.id) {
      selectedProfile = profiles.isNotEmpty ? profiles.first : null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _connection.dispose();
    super.dispose();
  }
}
