import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/app_models.dart';
import '../../../core/services/app_providers.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../discovery/presentation/widgets/deal_card.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(dealProvider(listingId));
    return Scaffold(
      body: SafeArea(
        child: dealAsync.when(
          data: (deal) => _DetailBody(deal: deal),
          error: (error, _) => Center(child: Text('$error')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref.watch(nearbyAlternativesProvider(deal));
    return CustomScrollView(
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
                    icon: deal.saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    onTap: () async {
                      try {
                        await ref
                            .read(repositoryProvider)
                            .toggleFavorite(deal.id, save: !deal.saved);
                      } finally {
                        ref.invalidate(dealProvider(deal.id));
                        ref.invalidate(savedIdsProvider);
                        ref.invalidate(savedDealsProvider);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [deal.tone.accent, deal.tone.surfaceTint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          label: deal.categoryLabel.toUpperCase(),
                          background: Colors.white.withValues(alpha: 0.18),
                          foreground: Colors.white,
                        ),
                        _Pill(
                          label: deal.affordabilityLabel,
                          background: Colors.white.withValues(alpha: 0.18),
                          foreground: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      deal.venueName,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: Colors.white, fontSize: 34),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      deal.valueHook,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroMetric(
                            label: 'Confidence',
                            value: '${(deal.confidenceScore * 100).round()}%',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeroMetric(
                            label: 'Last updated',
                            value: deal.lastUpdatedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    label: deal.trustBand.label,
                    background: deal.trustBand.tint,
                    foreground: deal.trustBand.foreground,
                    icon: deal.trustBand.icon,
                  ),
                  _Pill(
                    label: deal.scheduleLabel,
                    background: Colors.white,
                    foreground: DealDropPalette.body,
                    icon: Icons.schedule_rounded,
                  ),
                  _Pill(
                    label:
                        '${deal.distanceMiles.toStringAsFixed(1)} mi • ${deal.neighborhood}',
                    background: Colors.white,
                    foreground: DealDropPalette.body,
                    icon: Icons.place_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                deal.valueNote,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: DealDropPalette.ink),
              ),
              const SizedBox(height: 20),
              _DetailSection(
                title: 'Trust and freshness',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          deal.trustBand.icon,
                          color: deal.trustBand.foreground,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            deal.trustSummary.explanation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Trust label', value: deal.trustBand.label),
                    _InfoRow(label: 'Freshness', value: deal.freshnessText),
                    _InfoRow(
                      label: 'Last updated',
                      value: deal.lastUpdatedText,
                    ),
                    _InfoRow(
                      label: 'Proof count',
                      value: '${deal.trustSummary.proofCount} evidence items',
                    ),
                    _InfoRow(
                      label: 'Recent confirmations',
                      value: '${deal.trustSummary.recentConfirmations}',
                    ),
                    _InfoRow(
                      label: 'Disputes',
                      value: '${deal.trustSummary.disputeCount}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DetailSection(
                title: 'Offer details',
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < deal.offers.length;
                      index++
                    ) ...[
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '\$${deal.offers[index].dealPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: DealDropPalette.success),
                          ),
                        ],
                      ),
                      if (index < deal.offers.length - 1)
                        const Divider(height: 22),
                    ],
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Restrictions', value: deal.conditions),
                    _InfoRow(label: 'Address', value: deal.venueAddress),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDirections(context, deal),
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(
                        '/contribute/confirm-active?listingId=${deal.id}',
                      ),
                      icon: const Icon(Icons.verified_rounded),
                      label: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/contribute/report-expired?listingId=${deal.id}',
                      ),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Report issue'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/contribute/suggest-update?listingId=${deal.id}',
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Suggest update'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DetailSection(
                title: 'Source note',
                child: Text(
                  deal.sourceNote,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 18),
              _DetailSection(
                title: 'Nearby alternatives',
                child: nearby.when(
                  data: (items) {
                    final filtered = items
                        .where((item) => item.id != deal.id)
                        .take(2)
                        .toList();
                    if (filtered.isEmpty) {
                      return Text(
                        'No nearby alternatives yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }
                    return Column(
                      children: filtered
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: DealCard(
                                deal: item,
                                onTap: () =>
                                    context.push('/listing/${item.id}'),
                                onSavePressed: () async {
                                  await ref
                                      .read(repositoryProvider)
                                      .toggleFavorite(
                                        item.id,
                                        save: !item.saved,
                                      );
                                  ref.invalidate(savedIdsProvider);
                                  ref.invalidate(savedDealsProvider);
                                },
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  error: (_, _) => Text(
                    'Nearby alternatives are unavailable right now.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _openDirections(BuildContext context, Deal deal) async {
    final destination = deal.venueAddress.isNotEmpty
        ? '${deal.venueName}, ${deal.venueAddress}'
        : '${deal.latitude},${deal.longitude}';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open directions right now.')),
      );
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

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
            width: 110,
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
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
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

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
