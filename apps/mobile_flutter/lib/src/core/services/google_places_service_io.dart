import 'package:dio/dio.dart';

import '../models/google_place_models.dart';
import 'app_config.dart';

class GooglePlacesService {
  GooglePlacesService({required AppConfig config})
    : _apiKey = config.googleMapsApiKey,
      _dio = Dio(
        BaseOptions(
          baseUrl: 'https://maps.googleapis.com/maps/api/place',
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

  final String _apiKey;
  final Dio _dio;

  bool get available => _apiKey.isNotEmpty;

  Future<List<GooglePlacePrediction>> searchPlaces(String query) async {
    final normalized = query.trim();
    if (!available || normalized.length < 2) {
      return const [];
    }
    final response = await _dio.get<Map<String, dynamic>>(
      '/autocomplete/json',
      queryParameters: {
        'key': _apiKey,
        'input': normalized,
        'types': 'establishment',
        'components': 'country:us',
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final status = data['status'] as String? ?? '';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw StateError(data['error_message'] as String? ?? status);
    }
    return (data['predictions'] as List<dynamic>? ?? const [])
        .map((item) {
          final json = item as Map<String, dynamic>;
          final formatting =
              json['structured_formatting'] as Map<String, dynamic>? ??
              const {};
          return GooglePlacePrediction(
            placeId: json['place_id'] as String? ?? '',
            mainText:
                formatting['main_text'] as String? ??
                json['description'] as String? ??
                '',
            secondaryText: formatting['secondary_text'] as String? ?? '',
            description: json['description'] as String? ?? '',
          );
        })
        .where((item) => item.placeId.isNotEmpty)
        .toList();
  }

  Future<GooglePlaceDetails?> fetchPlaceDetails(String placeId) async {
    if (!available || placeId.isEmpty) {
      return null;
    }
    final response = await _dio.get<Map<String, dynamic>>(
      '/details/json',
      queryParameters: {
        'key': _apiKey,
        'place_id': placeId,
        'fields': [
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
          'address_components',
        ].join(','),
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final status = data['status'] as String? ?? '';
    if (status != 'OK') {
      throw StateError(data['error_message'] as String? ?? status);
    }
    final result = data['result'] as Map<String, dynamic>? ?? const {};
    final geometry = result['geometry'] as Map<String, dynamic>? ?? const {};
    final location = geometry['location'] as Map<String, dynamic>? ?? const {};
    final latitude = (location['lat'] as num?)?.toDouble();
    final longitude = (location['lng'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      return null;
    }
    return GooglePlaceDetails(
      placeId: result['place_id'] as String? ?? placeId,
      name: result['name'] as String? ?? '',
      formattedAddress: result['formatted_address'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      types: (result['types'] as List<dynamic>? ?? const []).cast<String>(),
      website: result['website'] as String?,
      phoneNumber: result['formatted_phone_number'] as String?,
      googleMapsUrl: result['url'] as String?,
      rating: (result['rating'] as num?)?.toDouble(),
      userRatingsTotal: (result['user_ratings_total'] as num?)?.toInt(),
      businessStatus: result['business_status'] as String?,
      raw: result,
    );
  }
}
