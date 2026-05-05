import 'app_config.dart';
import 'google_maps_loader_stub.dart'
    if (dart.library.html) 'google_maps_loader_web.dart';

Future<void> ensureGoogleMapsLoaded(AppConfig config) {
  return ensureGoogleMapsLoadedForPlatform(config);
}

bool get googleMapsRuntimeAvailable {
  return isGoogleMapsRuntimeAvailableForPlatform();
}
