import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class LocalStore {
  const LocalStore(this._preferences);

  final SharedPreferences _preferences;

  static const _sessionKey = 'session_json';
  static const _guestFavoritesKey = 'guest_favorite_ids';
  static const _offlineQueueKey = 'offline_mutations';
  static const _onboardingSeenKey = 'onboarding_seen';
  static const _cachePrefix = 'cache:';

  Future<void> setOnboardingSeen(bool value) async {
    await _preferences.setBool(_onboardingSeenKey, value);
  }

  bool getOnboardingSeen() => _preferences.getBool(_onboardingSeenKey) ?? false;

  Future<void> saveSession(AuthSessionModel session) async {
    await _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  AuthSessionModel? loadSession() {
    final value = _preferences.getString(_sessionKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return AuthSessionModel.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> clearSession() async {
    await _preferences.remove(_sessionKey);
  }

  Future<void> clearCachedData() async {
    final keys = _preferences
        .getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .toList();
    for (final key in keys) {
      await _preferences.remove(key);
    }
  }

  Set<String> loadGuestFavorites() {
    return (_preferences.getStringList(_guestFavoritesKey) ?? const <String>[])
        .toSet();
  }

  Future<void> saveGuestFavorites(Set<String> values) async {
    final normalized = values.toList()..sort();
    await _preferences.setStringList(_guestFavoritesKey, normalized);
  }

  List<OfflineMutation> loadOfflineQueue() {
    final raw = _preferences.getString(_offlineQueueKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return decoded.map(OfflineMutation.fromJson).toList();
  }

  Future<void> saveOfflineQueue(List<OfflineMutation> items) async {
    await _preferences.setString(
      _offlineQueueKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> cacheJson(String key, Object value) async {
    await _preferences.setString('$_cachePrefix$key', jsonEncode(value));
  }

  Map<String, dynamic>? readCachedJson(String key) {
    final raw = _preferences.getString('$_cachePrefix$key');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>>? readCachedJsonList(String key) {
    final raw = _preferences.getString('$_cachePrefix$key');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
