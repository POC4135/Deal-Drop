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

final mapBoundsProvider = StateProvider<MapBounds?>((ref) => null);

final mapListingsProvider = FutureProvider<List<MapDeal>>((ref) async {
  final bounds = ref.watch(mapBoundsProvider);
  if (bounds == null) {
    return const [];
  }
  return ref
      .watch(repositoryProvider)
      .fetchMapListings(
        north: bounds.north,
        south: bounds.south,
        east: bounds.east,
        west: bounds.west,
        zoom: bounds.zoom,
        trustBand: bounds.trustBand,
      );
});
