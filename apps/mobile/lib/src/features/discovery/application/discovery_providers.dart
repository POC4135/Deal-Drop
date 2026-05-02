import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../data/api_deals_repository.dart';
import '../data/seed_deals_repository.dart';
import '../domain/deal.dart';

final dealsRepositoryProvider = Provider<DealsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiDealsRepository(client);
});

final discoveryFilterProvider =
    StateProvider<DiscoveryFilter>((ref) => DiscoveryFilter.all);

final discoverySearchProvider = StateProvider<String>((ref) => '');

/// Fetches all deals from the API once; filtering is applied client-side
/// so that toggling filters/search doesn't re-fetch.
final allDealsProvider = FutureProvider<List<Deal>>((ref) async {
  final repository = ref.watch(dealsRepositoryProvider);
  return repository.listDeals();
});

final filteredDealsProvider = Provider<AsyncValue<List<Deal>>>((ref) {
  final dealsAsync = ref.watch(allDealsProvider);
  final filter = ref.watch(discoveryFilterProvider);
  final searchTerm = ref.watch(discoverySearchProvider).trim().toLowerCase();

  return dealsAsync.whenData((allDeals) {
    final deals = allDeals.where((deal) {
      final matchesFilter = switch (filter) {
        DiscoveryFilter.all => true,
        DiscoveryFilter.nearMe => deal.distanceMiles <= 0.8,
        DiscoveryFilter.topRated => deal.rating >= 4.7,
        DiscoveryFilter.fresh =>
          deal.trustBand == TrustBand.recentlyUpdated ||
              deal.trustBand == TrustBand.founderVerified,
      };

      final matchesSearch = searchTerm.isEmpty ||
          deal.venueName.toLowerCase().contains(searchTerm) ||
          deal.cuisine.toLowerCase().contains(searchTerm) ||
          deal.neighborhood.toLowerCase().contains(searchTerm) ||
          deal.valueHook.toLowerCase().contains(searchTerm);

      return matchesFilter && matchesSearch;
    }).toList();

    if (filter == DiscoveryFilter.nearMe) {
      deals.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
    } else if (filter == DiscoveryFilter.topRated) {
      deals.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return deals;
  });
});

final dealProvider = FutureProvider.family<Deal?, String>((ref, dealId) async {
  final deals = await ref.watch(allDealsProvider.future);
  try {
    return deals.firstWhere((d) => d.id == dealId);
  } catch (_) {
    return null;
  }
});

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);

final savedDealsProvider = Provider<AsyncValue<List<Deal>>>((ref) {
  final dealsAsync = ref.watch(allDealsProvider);
  final savedIds = ref.watch(favoritesControllerProvider).valueOrNull ?? {};
  return dealsAsync.whenData(
    (deals) => deals.where((deal) => savedIds.contains(deal.id)).toList(),
  );
});

class FavoritesController extends AsyncNotifier<Set<String>> {
  static const _key = 'saved_listing_ids';

  @override
  Future<Set<String>> build() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<void> toggle(String dealId) async {
    final current = Set<String>.from(state.valueOrNull ?? <String>{});
    if (current.contains(dealId)) {
      current.remove(dealId);
    } else {
      current.add(dealId);
    }

    state = AsyncData(current);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, current.toList()..sort());
  }
}
