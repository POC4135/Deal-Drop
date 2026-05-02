import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../discovery/application/discovery_providers.dart';
import '../../discovery/domain/deal.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(dealProvider(listingId));
    final savedIds = ref.watch(favoritesControllerProvider).valueOrNull ?? {};

    return dealAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(appBar: AppBar(), body: const Center(child: Text('Listing not found'))),
      data: (deal) {
        if (deal == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Listing not found')));
        }
        return _buildDetail(context, ref, deal, savedIds);
      },
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Deal deal, Set<String> savedIds) {
    final isSaved = savedIds.contains(deal.id);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  Row(
                    children: [
                      _TopIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      _TopIconButton(
                        icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                        onTap: () =>
                            ref.read(favoritesControllerProvider.notifier).toggle(deal.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 230,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          deal.tone.accent,
                          deal.tone.surfaceTint,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 24,
                          top: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              deal.categoryLabel.toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Icon(
                              deal.icon,
                              size: 96,
                              color: Colors.white.withOpacity(0.88),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          bottom: 24,
                          right: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deal.venueName,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      color: Colors.white,
                                      fontSize: 32,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                deal.valueHook,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        label: deal.trustBand.label,
                        background: deal.trustBand.tint,
                        foreground: deal.trustBand.foreground,
                      ),
                      _Pill(
                        label: deal.scheduleLabel,
                        background: Colors.white,
                        foreground: DealDropPalette.body,
                      ),
                      _Pill(
                        label: '${deal.distanceMiles.toStringAsFixed(1)} mi • ${deal.neighborhood}',
                        background: Colors.white,
                        foreground: DealDropPalette.body,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    deal.valueNote,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: DealDropPalette.ink,
                        ),
                  ),
                  const SizedBox(height: 22),
                  _DetailSection(
                    title: 'Active offers',
                    child: Column(
                      children: [
                        for (var index = 0; index < deal.offers.length; index++) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  deal.offers[index].title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                '\$${deal.offers[index].originalPrice.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '\$${deal.offers[index].dealPrice.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: DealDropPalette.success,
                                    ),
                              ),
                            ],
                          ),
                          if (index < deal.offers.length - 1)
                            const Divider(height: 24),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DetailSection(
                    title: 'Trust and freshness',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: 'Trust label', value: deal.trustBand.label),
                        _InfoRow(label: 'Freshness', value: deal.freshnessText),
                        _InfoRow(label: 'Last updated', value: deal.lastUpdatedText),
                        _InfoRow(label: 'Source', value: deal.sourceNote),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DetailSection(
                    title: 'Conditions',
                    child: Text(
                      deal.conditions,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/contribute/confirm-active'),
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('Confirm'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/contribute/report-expired'),
                          icon: const Icon(Icons.flag_outlined),
                          label: const Text('Report'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/contribute/suggest-update'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Suggest update'),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: DealDropShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DealDropPalette.muted,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DealDropPalette.ink,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DealDropPalette.divider),
        ),
        child: Icon(icon, color: DealDropPalette.ink),
      ),
    );
  }
}
