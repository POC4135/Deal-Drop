import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'api_client.dart';

class AnalyticsService {
  AnalyticsService(this._client);

  final DealDropApiClient _client;

  final List<Map<String, dynamic>> _buffer = <Map<String, dynamic>>[];

  Future<void> track(
    String name, {
    String? screen,
    Map<String, dynamic> properties = const {},
  }) async {
    final event = <String, dynamic>{
      'name': name,
      'screen': screen,
      'happenedAt': DateTime.now().toUtc().toIso8601String(),
      'properties': properties,
    };
    _buffer.add(event);
    developer.log('analytics:$name', name: 'dealdrop.analytics', error: properties);
    if (_buffer.length >= 6 || kDebugMode) {
      await flush();
    }
  }

  Future<void> flush() async {
    if (_buffer.isEmpty) {
      return;
    }
    final payload = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    try {
      await _client.postJson(
        '/v1/telemetry/events',
        body: {'events': payload},
      );
    } on ApiException {
      _buffer.insertAll(0, payload);
    }
  }
}
