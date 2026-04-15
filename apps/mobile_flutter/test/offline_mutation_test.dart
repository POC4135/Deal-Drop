import 'package:flutter_test/flutter_test.dart';

import 'package:dealdropapp/src/core/models/app_models.dart';

void main() {
  test('offline mutation preserves actor scope during serialization', () {
    final mutation = OfflineMutation(
      id: 'offline-1',
      type: 'favorite_add',
      payload: const {'listingId': 'lst_123'},
      createdAt: DateTime.parse('2026-04-15T12:00:00.000Z'),
      retryCount: 2,
      actorUserId: 'usr_alex',
    );

    final roundTrip = OfflineMutation.fromJson(mutation.toJson());

    expect(roundTrip.actorUserId, 'usr_alex');
    expect(roundTrip.type, 'favorite_add');
    expect(roundTrip.retryCount, 2);
    expect(roundTrip.payload['listingId'], 'lst_123');
  });
}
