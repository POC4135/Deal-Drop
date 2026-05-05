import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class LocalStore {
  LocalStore(
    this._preferences, {
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  }) : _secureStorage = secureStorage;

  final SharedPreferences _preferences;
  final FlutterSecureStorage _secureStorage;
  AuthSessionModel? _session;

  static const _sessionKey = 'session_json';
  static const _deviceIdKey = 'device_id';
  static const _guestFavoritesKey = 'guest_favorite_ids';
  static const _offlineQueueKey = 'offline_mutations';
  static const _onboardingSeenKey = 'onboarding_seen';
  static const _cachePrefix = 'cache:';

  Future<void> initialize() async {
    final secureValue = await _secureStorage.read(key: _sessionKey);
    if (secureValue != null && secureValue.isNotEmpty) {
      _session = AuthSessionModel.fromJson(
        jsonDecode(secureValue) as Map<String, dynamic>,
      );
      await _preferences.remove(_sessionKey);
      return;
    }

    final legacyValue = _preferences.getString(_sessionKey);
    if (legacyValue == null || legacyValue.isEmpty) {
      return;
    }
    _session = AuthSessionModel.fromJson(
      jsonDecode(legacyValue) as Map<String, dynamic>,
    );
    await _secureStorage.write(key: _sessionKey, value: legacyValue);
    await _preferences.remove(_sessionKey);
  }

  Future<void> setOnboardingSeen(bool value) async {
    await _preferences.setBool(_onboardingSeenKey, value);
  }

  bool getOnboardingSeen() => _preferences.getBool(_onboardingSeenKey) ?? false;

  Future<void> saveSession(AuthSessionModel session) async {
    final encoded = jsonEncode(session.toJson());
    _session = session;
    await _secureStorage.write(key: _sessionKey, value: encoded);
    await _preferences.remove(_sessionKey);
  }

  AuthSessionModel? loadSession() => _session;

  Future<void> clearSession() async {
    _session = null;
    await _secureStorage.delete(key: _sessionKey);
    await _preferences.remove(_sessionKey);
  }

  Future<String> deviceId() async {
    final stored = await _secureStorage.read(key: _deviceIdKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final generated = _generateDeviceId();
    await _secureStorage.write(key: _deviceIdKey, value: generated);
    return generated;
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

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return [
      value.substring(0, 8),
      value.substring(8, 12),
      value.substring(12, 16),
      value.substring(16, 20),
      value.substring(20),
    ].join('-');
  }
}
