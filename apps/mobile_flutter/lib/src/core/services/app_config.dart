import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.telemetryEnabled,
    required this.googleMapsKeyConfigured,
  });

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final bool telemetryEnabled;
  final bool googleMapsKeyConfigured;

  bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static AppConfig fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment('DEALDROP_API_BASE_URL');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabasePublishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
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
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
      telemetryEnabled: true,
      googleMapsKeyConfigured: mapsKey.isNotEmpty,
    );
  }
}
