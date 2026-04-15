import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/services/app_providers.dart';

enum DiscoveryFilter { all, liveNow, tonight, cheapEats, fresh }

extension DiscoveryFilterX on DiscoveryFilter {
  String get label => switch (this) {
        DiscoveryFilter.all => 'All',
        DiscoveryFilter.liveNow => 'Live now',
        DiscoveryFilter.tonight => 'Tonight',
        DiscoveryFilter.cheapEats => 'Cheap eats',
        DiscoveryFilter.fresh => 'Fresh',
      };
}

final discoveryFilterProvider = StateProvider<DiscoveryFilter>((ref) => DiscoveryFilter.all);

final filtersMetadataProvider = FutureProvider<FiltersMetadataModel>((ref) {
  return ref.watch(repositoryProvider).fetchFilters();
});

final dealsFeedProvider = FutureProvider<FeedPayload>((ref) {
  return ref.watch(repositoryProvider).fetchHomeFeed();
});

final filteredFeedSectionsProvider = Provider<AsyncValue<List<FeedSectionModel>>>((ref) {
  final feed = ref.watch(dealsFeedProvider);
  final selectedFilter = ref.watch(discoveryFilterProvider);
  return feed.whenData((payload) {
    if (selectedFilter == DiscoveryFilter.all) {
      return payload.sections;
    }

    final wantedIds = switch (selectedFilter) {
      DiscoveryFilter.liveNow => {'live-now'},
      DiscoveryFilter.tonight => {'tonight'},
      DiscoveryFilter.cheapEats => {'cheap-eats'},
      DiscoveryFilter.fresh => {'fresh-this-week'},
      DiscoveryFilter.all => <String>{},
    };

    return payload.sections
        .where((section) => wantedIds.contains(section.id))
        .toList();
  });
});

final savedIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(repositoryProvider).currentFavoriteIds();
});

final savedDealsProvider = FutureProvider<List<Deal>>((ref) {
  return ref.watch(repositoryProvider).fetchSavedDeals();
});

final dealProvider = FutureProvider.family<Deal, String>((ref, dealId) async {
  return ref.watch(repositoryProvider).fetchListingDetail(dealId);
});

final nearbyAlternativesProvider = FutureProvider.family<List<Deal>, Deal>((ref, deal) {
  return ref.watch(repositoryProvider).fetchNearbyDeals(
        latitude: deal.latitude,
        longitude: deal.longitude,
      );
});
