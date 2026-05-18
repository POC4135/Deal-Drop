import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/services/app_providers.dart';

typedef MapBounds = ({
  double north,
  double south,
  double east,
  double west,
  double? zoom,
  TrustBand? trustBand,
});

enum MapCategoryFilter { all, food, drink }

extension MapCategoryFilterX on MapCategoryFilter {
  String get label => switch (this) {
    MapCategoryFilter.all => 'All',
    MapCategoryFilter.food => 'Food',
    MapCategoryFilter.drink => 'Drinks',
  };

  bool matches(MapDeal deal) {
    if (this == MapCategoryFilter.all) return true;
    const foodTags = {
      'lunch', 'dinner', 'tacos', 'pizza', 'ramen', 'food', 'brunch',
      'breakfast', 'burger', 'sandwich', 'sushi', 'thai', 'indian', 'mexican',
      'italian', 'chinese', 'quick-bite', 'cheap-eats', 'comfort-food', 'student',
    };
    const drinkTags = {
      'drinks', 'happy-hour', 'bar', 'cocktails', 'beer', 'wine', 'spirits', 'small-plates',
    };
    final tags = deal.tags.map((t) => t.toLowerCase()).toSet();
    final titleLower = deal.title.toLowerCase();
    final venueLower = deal.venueName.toLowerCase();
    if (this == MapCategoryFilter.drink) {
      return tags.any(drinkTags.contains) ||
          drinkTags.any((t) => titleLower.contains(t) || venueLower.contains(t));
    }
    // food: anything with food tags OR non-drink venues
    return tags.any(foodTags.contains) ||
        foodTags.any((t) => titleLower.contains(t) || venueLower.contains(t)) ||
        (!tags.any(drinkTags.contains) && !drinkTags.any((t) => titleLower.contains(t)));
  }
}

enum MapDistanceFilter { any, half, one, two, five }

extension MapDistanceFilterX on MapDistanceFilter {
  String get label => switch (this) {
    MapDistanceFilter.any => 'Any dist.',
    MapDistanceFilter.half => '0.5 mi',
    MapDistanceFilter.one => '1 mi',
    MapDistanceFilter.two => '2 mi',
    MapDistanceFilter.five => '5 mi',
  };

  double? get radiusMiles => switch (this) {
    MapDistanceFilter.any => null,
    MapDistanceFilter.half => 0.5,
    MapDistanceFilter.one => 1.0,
    MapDistanceFilter.two => 2.0,
    MapDistanceFilter.five => 5.0,
  };
}

class UserPosition {
  const UserPosition({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}

final mapBoundsProvider = StateProvider<MapBounds?>((ref) => null);
final mapCategoryFilterProvider = StateProvider<MapCategoryFilter>((ref) => MapCategoryFilter.all);
final mapDistanceFilterProvider = StateProvider<MapDistanceFilter>((ref) => MapDistanceFilter.any);
final userPositionProvider = StateProvider<UserPosition?>((ref) => null);

final mapListingsProvider = FutureProvider<List<MapDeal>>((ref) async {
  final bounds = ref.watch(mapBoundsProvider);
  if (bounds == null) return const [];

  final raw = await ref.watch(repositoryProvider).fetchMapListings(
    north: bounds.north,
    south: bounds.south,
    east: bounds.east,
    west: bounds.west,
    zoom: bounds.zoom,
    trustBand: bounds.trustBand,
  );

  final categoryFilter = ref.watch(mapCategoryFilterProvider);
  final distanceFilter = ref.watch(mapDistanceFilterProvider);
  final userPos = ref.watch(userPositionProvider);

  var filtered = raw.where(categoryFilter.matches).toList();

  final radius = distanceFilter.radiusMiles;
  if (radius != null && userPos != null) {
    filtered = filtered.where((deal) {
      final dist = _haversineMiles(
        userPos.latitude, userPos.longitude,
        deal.latitude, deal.longitude,
      );
      return dist <= radius;
    }).toList();
  }

  return filtered;
});

double _haversineMiles(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusMiles = 3958.8;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMiles * c;
}

double _toRad(double deg) => deg * math.pi / 180;
