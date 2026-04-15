import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/services/dealdrop_repository.dart';

final leaderboardWindowProvider = StateProvider<String>((ref) => 'weekly');

final karmaSnapshotProvider = FutureProvider<KarmaSnapshot>((ref) {
  final window = ref.watch(leaderboardWindowProvider);
  return ref.watch(repositoryProvider).fetchKarma(window: window);
});

final leaderboardProvider = FutureProvider<LeaderboardPayload>((ref) {
  final window = ref.watch(leaderboardWindowProvider);
  return ref.watch(repositoryProvider).fetchLeaderboard(window: window);
});

final contributionHistoryProvider = FutureProvider<List<ContributionRecordModel>>((ref) {
  return ref.watch(repositoryProvider).fetchContributions();
});
