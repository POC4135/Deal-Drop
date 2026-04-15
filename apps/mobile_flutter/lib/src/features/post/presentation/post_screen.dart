import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/app_models.dart';
import '../../karma/application/karma_providers.dart';
import '../application/post_providers.dart';

class PostScreen extends ConsumerWidget {
  const PostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(contributionHistoryProvider);
    final offlineQueue = ref.watch(offlineQueueProvider);
    const actions = [
      _ContributionAction(
        title: 'Suggest a new deal',
        description: 'Add a new local listing for moderator review.',
        icon: Icons.add_circle_outline_rounded,
        slug: 'suggest-deal',
        tint: DealDropPalette.goldSoft,
      ),
      _ContributionAction(
        title: 'Suggest an update',
        description: 'Fix timing, pricing, restrictions, or location issues.',
        icon: Icons.edit_outlined,
        slug: 'suggest-update',
        tint: DealDropPalette.sky,
      ),
      _ContributionAction(
        title: 'Confirm still active',
        description:
            'Boost confidence for a listing you just verified in person.',
        icon: Icons.verified_rounded,
        slug: 'confirm-active',
        tint: Color(0xFFDDF7EE),
      ),
      _ContributionAction(
        title: 'Report expired',
        description:
            'Flag stale or conflicting offers before more users waste time.',
        icon: Icons.report_gmailerrorred_rounded,
        slug: 'report-expired',
        tint: Color(0xFFFFE5CC),
      ),
    ];

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DealDropPalette.goldDeep, DealDropPalette.gold],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: DealDropShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'QUALITY CONTRIBUTIONS ONLY',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Keep Atlanta fresh',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Nothing hits the public feed directly. Fast, high-signal submissions move trust and points the quickest.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                for (final action in actions) ...[
                  _ActionCard(
                    action: action,
                    onTap: () => context.push('/contribute/${action.slug}'),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                offlineQueue.when(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E6),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${items.length} contribution action${items.length == 1 ? '' : 's'} waiting to retry when the connection stabilizes.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.invalidate(offlineQueueProvider);
                                  ref.invalidate(contributionHistoryProvider);
                                  ref.invalidate(karmaSnapshotProvider);
                                },
                                child: const Text('Retry now'),
                              ),
                            ],
                          ),
                        ),
                  error: (_, _) => const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),
                Text(
                  'Recent contribution activity',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                contributions.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return Text(
                        'Your contribution history will appear here once you confirm, update, or submit listings.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }
                    return Column(
                      children: items
                          .take(4)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ContributionHistoryRow(item: item),
                            ),
                          )
                          .toList(),
                    );
                  },
                  error: (error, _) => Text('$error'),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.onTap});

  final _ContributionAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: DealDropShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: action.tint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(action.icon, color: DealDropPalette.ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DealDropPalette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionHistoryRow extends StatelessWidget {
  const _ContributionHistoryRow({required this.item});

  final ContributionRecordModel item;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status) {
      'approved' => DealDropPalette.success,
      'rejected' => const Color(0xFFAF3150),
      'under_review' => DealDropPalette.warning,
      _ => DealDropPalette.goldDeep,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: DealDropShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.venueName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.status.replaceAll('_', ' '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.summary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            '${item.pointsDelta >= 0 ? '+' : ''}${item.pointsDelta} pts • ${item.pointsStatus}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ContributionAction {
  const _ContributionAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.slug,
    required this.tint,
  });

  final String title;
  final String description;
  final IconData icon;
  final String slug;
  final Color tint;
}
