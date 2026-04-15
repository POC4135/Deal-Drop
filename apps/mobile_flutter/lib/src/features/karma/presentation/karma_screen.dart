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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your Karma',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/account/profile'),
                        icon: const Icon(Icons.person_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  snapshot.when(
                    data: (value) => _KarmaHero(value: value),
                    error: (error, _) => Text('$error'),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Badges',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  snapshot.when(
                    data: (value) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: value.badges.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.12,
                          ),
                      itemBuilder: (context, index) {
                        final badge = value.badges[index];
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: DealDropShadows.card,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: badge.unlocked
                                      ? DealDropPalette.goldSoft
                                      : DealDropPalette.warmSurface,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  badge.unlocked
                                      ? Icons.workspace_premium_rounded
                                      : Icons.lock_outline_rounded,
                                  color: badge.unlocked
                                      ? DealDropPalette.goldDeep
                                      : DealDropPalette.muted,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                badge.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                badge.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    error: (error, _) => Text('$error'),
                    loading: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Leaderboard',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['daily', 'weekly', 'all_time']
                        .map(
                          (value) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: window == value,
                              label: Text(value.replaceAll('_', ' ')),
                              onSelected: (_) =>
                                  ref
                                          .read(
                                            leaderboardWindowProvider.notifier,
                                          )
                                          .state =
                                      value,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  leaderboard.when(
                    data: (payload) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DealDropPalette.warmSurface,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        children: payload.items
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _LeaderboardRow(
                                  entry: entry,
                                  currentUserId:
                                      snapshot.valueOrNull?.userId ?? '',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    error: (error, _) => Text('$error'),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Contribution history',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  contributions.when(
                    data: (items) => Column(
                      children: items
                          .take(5)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: DealDropShadows.card,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: item.pointsStatus == 'finalized'
                                            ? const Color(0xFFDDF7EE)
                                            : DealDropPalette.warmSurface,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        item.pointsStatus == 'finalized'
                                            ? Icons.bolt_rounded
                                            : Icons.schedule_rounded,
                                        color: item.pointsStatus == 'finalized'
                                            ? DealDropPalette.success
                                            : DealDropPalette.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.venueName,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.summary,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${item.pointsDelta >= 0 ? '+' : ''}${item.pointsDelta}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color:
                                                item.pointsStatus == 'finalized'
                                                ? DealDropPalette.success
                                                : DealDropPalette.goldDeep,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    error: (error, _) => Text('$error'),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
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

class _KarmaHero extends StatelessWidget {
  const _KarmaHero({required this.value});

  final KarmaSnapshot value;

  @override
  Widget build(BuildContext context) {
    final pointsText = NumberFormat.decimalPattern().format(value.points);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DealDropPalette.goldDeep, DealDropPalette.gold],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: DealDropShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current balance',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pointsText,
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (value.verifiedContributor)
                _HeroChip(label: 'Verified contributor'),
              _HeroChip(label: '${value.pendingPoints} pending'),
              _HeroChip(label: '${value.currentStreakDays} day streak'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${value.nextLevelPoints} points to ${value.level == 'Neighborhood Anchor' ? 'max level' : 'the next tier'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.nextLevelPoints == 0
                  ? 1
                  : (1 -
                            (value.nextLevelPoints /
                                (value.points + value.nextLevelPoints)))
                        .clamp(0.05, 1),
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You helped roughly ${value.impactUsersHelped} users avoid stale or overpriced picks.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isCurrentUser ? DealDropShadows.card : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isCurrentUser
                    ? DealDropPalette.goldDeep
                    : DealDropPalette.muted,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: isCurrentUser
                ? DealDropPalette.sky
                : DealDropPalette.goldSoft,
            child: Text(
              entry.displayName.substring(0, 1),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(entry.title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            NumberFormat.decimalPattern().format(entry.points),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}
