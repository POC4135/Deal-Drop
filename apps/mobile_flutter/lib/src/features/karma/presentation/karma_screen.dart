import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/app_models.dart';
import '../../karma/application/karma_providers.dart';

class KarmaScreen extends ConsumerWidget {
  const KarmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(karmaSnapshotProvider);
    final contributions = ref.watch(contributionHistoryProvider);
    final leaderboard = ref.watch(leaderboardProvider);
    final window = ref.watch(leaderboardWindowProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(karmaSnapshotProvider);
          ref.invalidate(contributionHistoryProvider);
          ref.invalidate(leaderboardProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _KarmaHeader(
                    onProfile: () => context.push('/account/profile'),
                  ),
                  const SizedBox(height: 12),
                  snapshot.when(
                    data: (value) => _KarmaSummary(value: value),
                    error: (error, _) => _InlineError(message: '$error'),
                    loading: () => const _SectionLoading(height: 148),
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Badges'),
                  const SizedBox(height: 10),
                  snapshot.when(
                    data: (value) => _BadgeStrip(badges: value.badges),
                    error: (error, _) => _InlineError(message: '$error'),
                    loading: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(title: 'Leaderboard'),
                  const SizedBox(height: 10),
                  _LeaderboardWindowControl(window: window, ref: ref),
                  const SizedBox(height: 10),
                  leaderboard.when(
                    data: (payload) => _LeaderboardList(
                      items: payload.items,
                      currentUserId: snapshot.valueOrNull?.userId ?? '',
                    ),
                    error: (error, _) => _InlineError(message: '$error'),
                    loading: () => const _SectionLoading(height: 156),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(title: 'Recent activity'),
                  const SizedBox(height: 10),
                  contributions.when(
                    data: (items) =>
                        _ContributionList(items: items.take(5).toList()),
                    error: (error, _) => _InlineError(message: '$error'),
                    loading: () => const _SectionLoading(height: 120),
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

class _KarmaHeader extends StatelessWidget {
  const _KarmaHeader({required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Karma', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 3),
              Text(
                'Your impact, rank, and latest rewards',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onProfile,
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ],
    );
  }
}

class _KarmaSummary extends StatelessWidget {
  const _KarmaSummary({required this.value});

  final KarmaSnapshot value;

  @override
  Widget build(BuildContext context) {
    final pointsText = NumberFormat.decimalPattern().format(value.points);
    final progress = value.nextLevelPoints == 0
        ? 1.0
        : (1 - (value.nextLevelPoints / (value.points + value.nextLevelPoints)))
              .clamp(0.05, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DealDropPalette.divider),
        boxShadow: DealDropShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pointsText,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),
              _SummaryMetric(label: 'Pending', value: '${value.pendingPoints}'),
              const SizedBox(width: 8),
              _SummaryMetric(
                label: 'Streak',
                value: '${value.currentStreakDays}d',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  value.verifiedContributor
                      ? 'Verified contributor'
                      : 'Build toward verified status',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '${value.nextLevelPoints} pts to next tier',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: DealDropPalette.warmSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(
                DealDropPalette.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DealDropPalette.warmSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 1),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip({required this.badges});

  final List<BadgeModel> badges;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: badges.map((badge) => _BadgeDot(badge: badge)).toList(),
    );
  }
}

class _BadgeDot extends StatelessWidget {
  const _BadgeDot({required this.badge});

  final BadgeModel badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${badge.title}: ${badge.description}',
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badge.unlocked
                    ? DealDropPalette.goldSoft
                    : DealDropPalette.warmSurface,
                border: Border.all(
                  color: badge.unlocked
                      ? DealDropPalette.gold
                      : DealDropPalette.divider,
                ),
              ),
              child: Icon(
                badge.unlocked
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_outline_rounded,
                size: 21,
                color: badge.unlocked
                    ? DealDropPalette.goldDeep
                    : DealDropPalette.muted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DealDropPalette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardWindowControl extends StatelessWidget {
  const _LeaderboardWindowControl({required this.window, required this.ref});

  final String window;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['daily', 'weekly', 'all_time']
            .map(
              (value) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: window == value,
                  label: Text(value.replaceAll('_', ' ')),
                  onSelected: (_) =>
                      ref.read(leaderboardWindowProvider.notifier).state =
                          value,
                  showCheckmark: false,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.items, required this.currentUserId});

  final List<LeaderboardEntryModel> items;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return _ListSurface(
      children: items
          .map(
            (entry) =>
                _LeaderboardRow(entry: entry, currentUserId: currentUserId),
          )
          .toList(),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.currentUserId});

  final LeaderboardEntryModel entry;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = entry.userId == currentUserId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser ? DealDropPalette.goldSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isCurrentUser
                    ? DealDropPalette.goldDeep
                    : DealDropPalette.muted,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: isCurrentUser
                ? DealDropPalette.sky
                : DealDropPalette.warmSurface,
            child: Text(
              entry.displayName.substring(0, 1),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            NumberFormat.decimalPattern().format(entry.points),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ContributionList extends StatelessWidget {
  const _ContributionList({required this.items});

  final List<ContributionRecordModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'Your confirmations and updates will appear here.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return _ListSurface(
      children: items.map((item) => _ContributionRow(item: item)).toList(),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.item});

  final ContributionRecordModel item;

  @override
  Widget build(BuildContext context) {
    final finalized = item.pointsStatus == 'finalized';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: finalized
                  ? const Color(0xFFDDF7EE)
                  : DealDropPalette.warmSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              finalized ? Icons.bolt_rounded : Icons.schedule_rounded,
              size: 18,
              color: finalized
                  ? DealDropPalette.success
                  : DealDropPalette.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.venueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  item.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.pointsDelta >= 0 ? '+' : ''}${item.pointsDelta}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: finalized
                  ? DealDropPalette.success
                  : DealDropPalette.goldDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSurface extends StatelessWidget {
  const _ListSurface({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DealDropPalette.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
