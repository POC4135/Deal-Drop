import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.telemetryEnabled,
    required this.googleMapsKeyConfigured,
  });

  final String apiBaseUrl;
  final bool telemetryEnabled;
  final bool googleMapsKeyConfigured;

  static AppConfig fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment('DEALDROP_API_BASE_URL');
    const mapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

    String baseUrl;
    if (configuredBaseUrl.isNotEmpty) {
      baseUrl = configuredBaseUrl;
    } else if (kIsWeb) {
      baseUrl = 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:3000';
    } else {
      baseUrl = 'http://localhost:3000';
    }

    return AppConfig(
      apiBaseUrl: baseUrl,
      telemetryEnabled: true,
      googleMapsKeyConfigured: mapsKey.isNotEmpty,
    );
  }
}
