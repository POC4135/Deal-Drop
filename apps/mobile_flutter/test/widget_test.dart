import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dealdropapp/src/app/dealdrop_app.dart';
import 'package:dealdropapp/src/core/models/app_models.dart';
import 'package:dealdropapp/src/core/services/api_client.dart';
import 'package:dealdropapp/src/core/services/analytics_service.dart';
import 'package:dealdropapp/src/core/services/app_config.dart';
import 'package:dealdropapp/src/core/services/app_providers.dart';
import 'package:dealdropapp/src/core/services/dealdrop_repository.dart';
import 'package:dealdropapp/src/core/services/local_store.dart';

class FakeDealDropRepository extends DealDropRepository {
  FakeDealDropRepository(SharedPreferences preferences)
      : super(
          apiClient: DealDropApiClient(
            config: AppConfig.fromEnvironment(),
            sessionReader: () async => null,
          ),
          localStore: LocalStore(preferences),
          analytics: AnalyticsService(
            DealDropApiClient(
              config: AppConfig.fromEnvironment(),
              sessionReader: () async => null,
            ),
          ),
        );

  @override
  AuthSessionModel? loadSession() => null;

  @override
  Future<FeedPayload> fetchHomeFeed() async {
    return FeedPayload(
      sections: [
        FeedSectionModel(
          id: 'live-now',
          title: 'Live now',
          subtitle: 'Fresh, high-confidence finds around you',
          items: [
            Deal.fromDetailJson({
              'id': 'lst_test',
              'venueId': 'ven_test',
              'venueName': 'Test Taco',
              'title': 'Taco Tuesday',
              'neighborhood': 'Midtown',
              'categoryLabel': 'Cheap eats',
              'scheduleLabel': 'Tonight • 5PM-9PM',
              'trustBand': 'founder_verified',
              'freshnessText': 'Updated 20 mins ago',
              'valueNote': 'Street tacos from \$4.99.',
              'affordabilityLabel': 'Under \$10',
              'distanceMiles': 0.6,
              'rating': 4.8,
              'cuisine': 'Mexican',
              'latitude': 33.780,
              'longitude': -84.387,
              'confidenceScore': 0.94,
              'lastUpdatedAt': DateTime.now().toIso8601String(),
              'tags': ['cheap-eats'],
              'saved': false,
              'venueAddress': '123 Midtown Ave',
              'description': 'Great tacos.',
              'conditions': 'Dine-in only',
              'sourceNote': 'Founder verified',
              'offers': [
                {
                  'id': 'off_1',
                  'title': 'Street Taco',
                  'originalPrice': 8.99,
                  'dealPrice': 4.99,
                  'currency': 'USD',
                }
              ],
              'freshUntilAt': DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
              'recheckAfterAt': DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
              'proofCount': 1,
              'trustSummary': {
                'band': 'founder_verified',
                'explanation': 'Verified directly by DealDrop.',
                'confidenceScore': 0.94,
                'freshUntilAt': DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
                'recheckAfterAt': DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
                'proofCount': 1,
                'recentConfirmations': 2,
                'disputeCount': 0,
              },
            }),
          ],
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<FiltersMetadataModel> fetchFilters() async {
    return FiltersMetadataModel(
      neighborhoods: const ['Midtown'],
      tags: const ['cheap-eats'],
      cuisines: const ['Mexican'],
      trustBands: const [TrustBand.founderVerified],
    );
  }

  @override
  Future<Set<String>> currentFavoriteIds() async => <String>{};

  @override
  Future<List<Deal>> fetchSavedDeals() async => const [];
}

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          repositoryProvider.overrideWithValue(FakeDealDropRepository(preferences)),
        ],
        child: const DealDropApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('guest can enter the deals shell from the welcome screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('Continue as guest'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Atlanta, GA'), findsOneWidget);
    expect(find.text('Deals'), findsWidgets);
  });

  testWidgets('guest sees auth gate on karma tab', (tester) async {
    await pumpApp(tester);

    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karma').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Sign in to see your Karma'), findsOneWidget);
  });
}
