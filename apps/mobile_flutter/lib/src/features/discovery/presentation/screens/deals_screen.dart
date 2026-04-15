import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/app_models.dart';
import '../../../../core/services/app_providers.dart';
import '../../../account/application/account_providers.dart';
import '../../application/discovery_providers.dart';
import '../widgets/deal_card.dart';

class DealsScreen extends ConsumerStatefulWidget {
  const DealsScreen({super.key});

  @override
  ConsumerState<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends ConsumerState<DealsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).track('screen_view', screen: 'deals');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final filteredSections = ref.watch(filteredFeedSectionsProvider);
    final savedIds = ref.watch(savedIdsProvider);
    final selectedFilter = ref.watch(discoveryFilterProvider);
    final notifications = auth.valueOrNull?.isAuthenticated == true
        ? ref.watch(notificationsProvider).valueOrNull
        : null;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dealsFeedProvider);
          ref.invalidate(savedIdsProvider);
          ref.invalidate(notificationsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Atlanta, GA', style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Fast local value with trust you can read in a glance.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      _RoundActionButton(
                        icon: notifications?.unreadCount != null && notifications!.unreadCount > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        onTap: () => context.push('/account/notifications'),
                      ),
                      const SizedBox(width: 10),
                      _AvatarButton(
                        initials: _initials(auth.valueOrNull?.profile?.displayName ?? 'Guest'),
                        onTap: () => context.push('/account/profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => context.push('/search'),
                    borderRadius: BorderRadius.circular(22),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: DealDropPalette.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: DealDropPalette.muted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search venues, neighborhoods, and offer types',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const Icon(Icons.tune_rounded, color: DealDropPalette.ink),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 42,
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
                          onSelected: (_) => ref.read(discoveryFilterProvider.notifier).state = filter,
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SpotlightBanner(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
            filteredSections.when(
              data: (sections) {
                if (sections.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _EmptyState(
                        title: 'No deals match this view yet',
                        body: 'Try a broader filter or search another neighborhood.',
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final section = sections[index];
                        final currentSavedIds = savedIds.valueOrNull ?? const <String>{};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 26),
                          child: _FeedSection(
                            section: section,
                            savedIds: currentSavedIds,
                          ),
                        );
                      },
                      childCount: sections.length,
                    ),
                  ),
                );
              },
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ErrorState(
                    message: '$error',
                    onRetry: () => ref.invalidate(dealsFeedProvider),
                  ),
                ),
              ),
              loading: () => const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _SectionSkeleton(),
                    SizedBox(height: 20),
                    _SectionSkeleton(),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'G';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _FeedSection extends ConsumerWidget {
  const _FeedSection({
    required this.section,
    required this.savedIds,
  });

  final FeedSectionModel section;
  final Set<String> savedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(section.subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        ...section.items.map(
          (deal) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: DealCard(
              deal: deal.copyWith(saved: savedIds.contains(deal.id)),
              onTap: () => context.push('/listing/${deal.id}'),
              onSavePressed: () async {
                final currentlySaved = savedIds.contains(deal.id);
                try {
                  await ref.read(repositoryProvider).toggleFavorite(deal.id, save: !currentlySaved);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved for retry once the connection returns.')),
                    );
                  }
                } finally {
                  ref.invalidate(savedIdsProvider);
                  ref.invalidate(savedDealsProvider);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightBanner extends StatelessWidget {
  const _SpotlightBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  'Fresh This Week',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'These are the listings moving fastest right now, not just the cheapest ones.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
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
        width: 52,
        height: 52,
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DealDropPalette.divider),
        ),
        child: Center(
          child: Text(
            initials,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: DealDropPalette.goldDeep),
          ),
        ),
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: DealDropShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: DealDropShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40),
            const SizedBox(height: 14),
            Text('Feed unavailable', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
