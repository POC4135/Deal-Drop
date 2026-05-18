import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_providers.dart';

final listingImagesProvider = FutureProvider.family<List<String>, String>((ref, listingId) {
  return ref.watch(repositoryProvider).fetchListingImages(listingId);
});
