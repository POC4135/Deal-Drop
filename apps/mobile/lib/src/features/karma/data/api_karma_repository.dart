import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../domain/karma_models.dart';

// Empty snapshot shown when the user hasn't signed in yet.
const _guestSnapshot = KarmaSnapshot(
  points: 0,
  pendingPoints: 0,
  progress: 0,
  verifiedContributor: false,
  badges: [],
  leaderboard: [],
);

class ApiKarmaRepository {
  const ApiKarmaRepository(this._client);

  final ApiClient _client;

  Future<KarmaSnapshot> snapshot() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/v1/users/me/karma');
      final body = response.data!;

    final badgesJson =
        (body['badges'] as List<dynamic>).cast<Map<String, dynamic>>();
    final leaderboardJson =
        (body['leaderboard'] as List<dynamic>).cast<Map<String, dynamic>>();

    return KarmaSnapshot(
      points: (body['points'] as num).toInt(),
      pendingPoints: (body['pendingPoints'] as num).toInt(),
      progress: (body['progress'] as num).toDouble(),
      verifiedContributor: body['verifiedContributor'] as bool,
      badges: badgesJson.map(_mapBadge).toList(),
      leaderboard: leaderboardJson.map(_mapLeaderboardEntry).toList(),
    );
    } on DioException catch (e) {
      // Not signed in or token expired — show empty guest state.
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return _guestSnapshot;
      }
      rethrow;
    }
  }
}

KarmaBadge _mapBadge(Map<String, dynamic> b) {
  final slug = b['slug'] as String;
  return KarmaBadge(
    title: b['title'] as String,
    subtitle: b['description'] as String? ?? '',
    icon: _iconForSlug(slug),
    tint: _tintForSlug(slug),
  );
}

LeaderboardEntry _mapLeaderboardEntry(Map<String, dynamic> e) {
  return LeaderboardEntry(
    rank: (e['rank'] as num).toInt(),
    name: e['displayName'] as String,
    title: e['badgeTitle'] as String? ?? 'Member',
    points: (e['totalPoints'] as num).toInt(),
    isCurrentUser: e['isCurrentUser'] as bool? ?? false,
  );
}

IconData _iconForSlug(String slug) => switch (slug) {
      'first-confirmation' => Icons.adjust_rounded,
      'streak-3' || 'streak-7' || 'streak-30' => Icons.local_fire_department_rounded,
      'first-contribution' || 'contributions-5' || 'contributions-25' =>
        Icons.edit_note_rounded,
      'top-contributor' => Icons.emoji_events_rounded,
      'verified-contributor' => Icons.verified_rounded,
      'early-adopter' => Icons.rocket_launch_rounded,
      _ => Icons.star_rounded,
    };

Color _tintForSlug(String slug) => switch (slug) {
      'first-confirmation' || 'first-contribution' => DealDropPalette.mint,
      'streak-3' || 'streak-7' || 'streak-30' => DealDropPalette.goldSoft,
      'contributions-5' || 'contributions-25' => DealDropPalette.sky,
      'top-contributor' => DealDropPalette.goldSoft,
      'verified-contributor' => DealDropPalette.sky,
      'early-adopter' => DealDropPalette.lilac,
      _ => DealDropPalette.mint,
    };
