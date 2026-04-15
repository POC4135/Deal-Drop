import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';

import '../domain/karma_models.dart';

class SeedKarmaRepository {
  const SeedKarmaRepository();

  KarmaSnapshot snapshot() {
    return const KarmaSnapshot(
      points: 8340,
      pendingPoints: 180,
      progress: 0.83,
      verifiedContributor: true,
      badges: [
        KarmaBadge(
          title: 'Daily Streak',
          subtitle: '14 days',
          icon: Icons.local_fire_department_rounded,
          tint: DealDropPalette.goldSoft,
        ),
        KarmaBadge(
          title: 'First Deal',
          subtitle: 'Posted on day 1',
          icon: Icons.adjust_rounded,
          tint: DealDropPalette.mint,
        ),
        KarmaBadge(
          title: 'Verified',
          subtitle: 'Trust score 98%',
          icon: Icons.verified_rounded,
          tint: DealDropPalette.sky,
        ),
        KarmaBadge(
          title: 'Explorer',
          subtitle: '50 area visits',
          icon: Icons.explore_outlined,
          tint: DealDropPalette.lilac,
          locked: true,
        ),
      ],
      leaderboard: [
        LeaderboardEntry(rank: 12, name: 'Joon Choi', title: 'Rising Star', points: 8340, isCurrentUser: true),
        LeaderboardEntry(rank: 1, name: 'Sarah Chen', title: 'Deal Master', points: 14820),
        LeaderboardEntry(rank: 2, name: 'Marcus Johnson', title: 'Eco Scout', points: 12100),
        LeaderboardEntry(rank: 3, name: 'Alex Rivera', title: 'Local Legend', points: 11540),
      ],
    );
  }
}
