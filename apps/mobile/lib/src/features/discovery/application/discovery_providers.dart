import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_deals_repository.dart';
import '../domain/deal.dart';

final dealsRepositoryProvider = Provider<DealsRepository>((ref) {
  return SeedDealsRepository();
});

final discoveryFilterProvider =
    StateProvider<DiscoveryFilter>((ref) => DiscoveryFilter.all);

final discoverySearchProvider = StateProvider<String>((ref) => '');

final filteredDealsProvider = Provider<List<Deal>>((ref) {
  final repository = ref.watch(dealsRepositoryProvider);
  final filter = ref.watch(discoveryFilterProvider);
  final searchTerm = ref.watch(discoverySearchProvider).trim().toLowerCase();

  final deals = repository.listDeals().where((deal) {
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

final dealProvider = Provider.family<Deal?, String>((ref, dealId) {
  final deals = ref.watch(dealsRepositoryProvider).listDeals();
  for (final deal in deals) {
    if (deal.id == dealId) {
      return deal;
    }
  }
  return null;
});

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);

final savedDealsProvider = Provider<List<Deal>>((ref) {
  final deals = ref.watch(dealsRepositoryProvider).listDeals();
  final savedIds = ref.watch(favoritesControllerProvider).valueOrNull ?? {};
  return deals.where((deal) => savedIds.contains(deal.id)).toList();
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
