import 'package:flutter/material.dart';

class KarmaBadge {
  const KarmaBadge({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final bool locked;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.title,
    required this.points,
    this.isCurrentUser = false,
  });

  final int rank;
  final String name;
  final String title;
  final int points;
  final bool isCurrentUser;
}

class KarmaSnapshot {
  const KarmaSnapshot({
    required this.points,
    required this.pendingPoints,
    required this.progress,
    required this.verifiedContributor,
    required this.badges,
    required this.leaderboard,
  });

  final int points;
  final int pendingPoints;
  final double progress;
  final bool verifiedContributor;
  final List<KarmaBadge> badges;
  final List<LeaderboardEntry> leaderboard;
}
