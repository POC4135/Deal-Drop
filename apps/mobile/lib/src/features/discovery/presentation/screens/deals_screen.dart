import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/discovery_providers.dart';
import '../../domain/deal.dart';
import '../widgets/deal_card.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(filteredDealsProvider);
    final deals = dealsAsync.valueOrNull ?? [];
    final isLoading = dealsAsync.isLoading;
    final favorites = ref.watch(favoritesControllerProvider).valueOrNull ?? {};
    final selectedFilter = ref.watch(discoveryFilterProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined, color: DealDropPalette.goldDeep),
                          const SizedBox(width: 8),
                          Text('Atlanta, GA', style: theme.textTheme.titleLarge),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: DealDropPalette.muted),
                        ],
                      ),
                    ),
                    _RoundActionButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () => context.push('/account/notifications'),
                    ),
                    const SizedBox(width: 10),
                    _AvatarButton(
                      initials: 'JC',
                      onTap: () => context.push('/account/profile'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            ref.read(discoverySearchProvider.notifier).state = value,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Search deals...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: DealDropPalette.divider),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.tune_rounded, color: DealDropPalette.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: DiscoveryFilter.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = DiscoveryFilter.values[index];
                      final selected = filter == selectedFilter;

                      return ChoiceChip(
                        selected: selected,
                        label: Text(filter.label),
                        onSelected: (_) =>
                            ref.read(discoveryFilterProvider.notifier).state = filter,
                        showCheckmark: false,
                        selectedColor: DealDropPalette.gold,
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          color: selected ? Colors.white : DealDropPalette.body,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                const _CollectionBanner(
                  title: 'Worth it right now',
                  subtitle:
                      'Curated Atlanta picks with high confidence and fast decision value.',
                ),
                const SizedBox(height: 22),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (dealsAsync.hasError)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: DealDropShadows.card,
                    ),
                    child: Text(
                      'Could not load deals. Check your connection and try again.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                else if (deals.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: DealDropShadows.card,
                    ),
                    child: Text(
                      'No deals match this filter yet. Clear search or switch to a broader view.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                for (final deal in deals) ...[
                  DealCard(
                    deal: deal,
                    isSaved: favorites.contains(deal.id),
                    onTap: () => context.push('/listing/${deal.id}'),
                    onSavePressed: () =>
                        ref.read(favoritesControllerProvider.notifier).toggle(deal.id),
                  ),
                  const SizedBox(height: 20),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionBanner extends StatelessWidget {
  const _CollectionBanner({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DealDropPalette.goldDeep, DealDropPalette.gold],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: DealDropShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.88),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: DealDropPalette.goldSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: DealDropPalette.goldDeep),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.initials,
    required this.onTap,
  });

  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DealDropPalette.divider),
        ),
        child: Center(
          child: Text(
            initials,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: DealDropPalette.goldDeep,
                ),
          ),
        ),
      ),
    );
  }
}
