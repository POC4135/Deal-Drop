import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_providers.dart';

final offlineQueueProvider = FutureProvider((ref) async {
  return ref.watch(repositoryProvider).flushOfflineQueue();
});
