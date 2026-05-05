import 'dart:async';
import 'dart:js_interop';

import 'package:google_maps/google_maps_places.dart' as places;
import 'package:web/web.dart' as web;

import '../models/google_place_models.dart';
import 'app_config.dart';
import 'google_maps_loader.dart';

class GooglePlacesService {
  GooglePlacesService({required AppConfig config}) : _config = config;

  final AppConfig _config;
  places.AutocompleteService? _autocompleteService;
  places.PlacesService? _placesService;

  bool get available => _config.googleMapsKeyConfigured;

  Future<List<GooglePlacePrediction>> searchPlaces(String query) async {
    final normalized = query.trim();
    if (!available || normalized.length < 2) {
      return const [];
    }
    await _ensurePlacesRuntime();
    final service = _autocompleteService;
    if (service == null) {
      throw StateError('Google Maps Places library is not available.');
    }

    final response = await service
        .getPlacePredictions(
          places.AutocompletionRequest(
            input: normalized,
            componentRestrictions: places.ComponentRestrictions(
              country: 'us'.toJS,
            ),
            types: ['establishment'].jsify() as JSArray<JSString>,
          ),
        )
        .timeout(const Duration(seconds: 8));

    return response.predictions
        .map(
          (prediction) => GooglePlacePrediction(
            placeId: prediction.placeId,
            mainText: prediction.structuredFormatting.mainText,
            secondaryText: prediction.structuredFormatting.secondaryText,
            description: prediction.description,
          ),
        )
        .where((item) => item.placeId.isNotEmpty)
        .toList();
  }

  Future<GooglePlaceDetails?> fetchPlaceDetails(String placeId) async {
    if (!available || placeId.isEmpty) {
      return null;
    }
    await _ensurePlacesRuntime();
    final service = _placesService;
    if (service == null) {
      throw StateError('Google Maps Places library is not available.');
    }

    final completer = Completer<GooglePlaceDetails?>();
    service.getDetails(
      places.PlaceDetailsRequest(
        placeId: placeId,
        fields:
            [
                  'place_id',
                  'name',
                  'formatted_address',
                  'geometry',
                  'types',
                  'website',
                  'formatted_phone_number',
                  'url',
                  'rating',
                  'user_ratings_total',
                  'business_status',
                ].jsify()
                as JSArray<JSString>,
      ),
      ((places.PlaceResult? place, places.PlacesServiceStatus status) {
        if (status != places.PlacesServiceStatus.OK || place == null) {
          completer.completeError(StateError('$status'));
          return;
        }
        final location = place.geometry?.location;
        if (location == null) {
          completer.complete(null);
          return;
        }
        final raw = <String, dynamic>{
          'placeId': place.placeId,
          'name': place.name,
          'formattedAddress': place.formattedAddress,
          'latitude': location.lat,
          'longitude': location.lng,
          'types': place.types,
          'website': place.website,
          'phoneNumber': place.formattedPhoneNumber,
          'googleMapsUrl': place.url,
          'rating': place.rating,
          'userRatingsTotal': place.userRatingsTotal,
          'businessStatus': '${place.businessStatus}',
        };
        completer.complete(
          GooglePlaceDetails(
            placeId: place.placeId ?? placeId,
            name: place.name ?? '',
            formattedAddress: place.formattedAddress ?? '',
            latitude: location.lat.toDouble(),
            longitude: location.lng.toDouble(),
            types: place.types ?? const [],
            website: place.website,
            phoneNumber: place.formattedPhoneNumber,
            googleMapsUrl: place.url,
            rating: place.rating?.toDouble(),
            userRatingsTotal: place.userRatingsTotal?.toInt(),
            businessStatus: place.businessStatus == null
                ? null
                : '${place.businessStatus}',
            raw: raw,
          ),
        );
      }).toJS,
    );
    return completer.future.timeout(const Duration(seconds: 8));
  }

  Future<void> _ensurePlacesRuntime() async {
    await ensureGoogleMapsLoaded(_config);
    _autocompleteService ??= places.AutocompleteService();
    _placesService ??= places.PlacesService(web.document.createElement('div'));
  }
}
