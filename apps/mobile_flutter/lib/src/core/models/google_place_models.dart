class GooglePlacePrediction {
  const GooglePlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });

  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;
}

class GooglePlaceDetails {
  const GooglePlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.types,
    this.website,
    this.phoneNumber,
    this.googleMapsUrl,
    this.rating,
    this.userRatingsTotal,
    this.businessStatus,
    this.raw = const {},
  });

  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final List<String> types;
  final String? website;
  final String? phoneNumber;
  final String? googleMapsUrl;
  final double? rating;
  final int? userRatingsTotal;
  final String? businessStatus;
  final Map<String, dynamic> raw;

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'formattedAddress': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
      'types': types,
      if (website != null) 'website': website,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (googleMapsUrl != null) 'googleMapsUrl': googleMapsUrl,
      if (rating != null) 'rating': rating,
      if (userRatingsTotal != null) 'userRatingsTotal': userRatingsTotal,
      if (businessStatus != null) 'businessStatus': businessStatus,
      'raw': raw,
    };
  }
}
