// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'app_config.dart';

Future<void>? _pendingLoad;
bool _loaded = false;

Future<void> ensureGoogleMapsLoadedForPlatform(AppConfig config) {
  if (!config.googleMapsKeyConfigured) {
    return Future<void>.value();
  }
  return _pendingLoad ??= _loadGoogleMaps(config);
}

Future<void> _loadGoogleMaps(AppConfig config) {
  final existing = html.document.getElementById('google-maps-js');
  if (existing is html.ScriptElement) {
    return existing.onLoad.first.then((_) {});
  }

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..id = 'google-maps-js'
    ..async = true
    ..defer = true
    ..src =
        'https://maps.googleapis.com/maps/api/js'
        '?key=${Uri.encodeComponent(config.googleMapsApiKey)}'
        '&libraries=places';

  script.onLoad.first.then((_) {
    _loaded = true;
    if (!completer.isCompleted) {
      completer.complete();
    }
  });
  script.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });

  html.document.head?.append(script);
  return completer.future;
}

bool isGoogleMapsRuntimeAvailableForPlatform() => _loaded;
