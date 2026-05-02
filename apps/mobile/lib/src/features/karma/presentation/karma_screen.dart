import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../data/api_karma_repository.dart';
import '../domain/karma_models.dart';

final karmaRepositoryProvider = Provider<ApiKarmaRepository>(
  (ref) => ApiKarmaRepository(ref.watch(apiClientProvider)),
);

final karmaSnapshotProvider = FutureProvider<KarmaSnapshot>((ref) async {
  return ref.watch(karmaRepositoryProvider).snapshot();
});

class KarmaScreen extends ConsumerWidget {
  const KarmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final karmaAsync = ref.watch(karmaSnapshotProvider);

    return karmaAsync.when(
      loading: () => const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SafeArea(
        child: Center(
          child: Text('Could not load karma data.',
              style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
      data: (snapshot) => _KarmaContent(snapshot: snapshot),
    );
  }
}

class _KarmaContent extends StatelessWidget {
  const _KarmaContent({required this.snapshot});

  final KarmaSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final pointsText = NumberFormat.decimalPattern().format(snapshot.points);

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
                      child: Text('Your Karma', style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    const Icon(Icons.notifications_none_rounded, color: DealDropPalette.goldDeep),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DealDropPalette.goldDeep, DealDropPalette.gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              pointsText,
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (snapshot.verifiedContributor)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: DealDropPalette.mint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Verified contributor',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: DealDropPalette.mintDeep,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pending: ${snapshot.pendingPoints} pts',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Monthly giveaway progress',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: snapshot.progress,
                          minHeight: 12,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '1,660 points remaining for the monthly Tech Bundle giveaway',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.92),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text('Achievement Badges', style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DealDropPalette.lilac,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${snapshot.badges.length} unlocked',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6E4EB9),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.badges.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final badge = snapshot.badges[index];
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
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: badge.locked ? DealDropPalette.warmSurface : badge.tint,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              badge.icon,
                              color: badge.locked ? DealDropPalette.muted : DealDropPalette.ink,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            badge.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: badge.locked ? DealDropPalette.muted : DealDropPalette.ink,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(badge.subtitle, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: DealDropPalette.warmSurface,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Atlanta Pulse', style: Theme.of(context).textTheme.headlineMedium),
                          ),
                          Text(
                            'VIEW ALL',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF6E4EB9),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      for (var index = 0; index < snapshot.leaderboard.length; index++) ...[
                        _LeaderboardRow(entry: snapshot.leaderboard[index]),
                        if (index < snapshot.leaderboard.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final baseDecoration = BoxDecoration(
      color: entry.isCurrentUser ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      boxShadow: entry.isCurrentUser ? DealDropShadows.card : null,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: baseDecoration,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: entry.isCurrentUser ? DealDropPalette.goldDeep : DealDropPalette.muted,
                  ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: entry.isCurrentUser
                ? DealDropPalette.sky
                : DealDropPalette.goldSoft,
            child: Text(
              entry.name.substring(0, 1),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(entry.title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            NumberFormat.decimalPattern().format(entry.points),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: DealDropPalette.ink,
                ),
          ),
        ],
      ),
    );
  }
}
