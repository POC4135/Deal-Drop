import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_models.dart';
import '../../../core/services/app_providers.dart';

final profileProvider = FutureProvider<AppProfile>((ref) {
  return ref.watch(repositoryProvider).fetchProfile();
});

final notificationsProvider = FutureProvider<NotificationsPayload>((ref) {
  return ref.watch(repositoryProvider).fetchNotifications();
});

final preferencesProvider = FutureProvider<PreferencesModel>((ref) {
  return ref.watch(repositoryProvider).fetchPreferences();
});
