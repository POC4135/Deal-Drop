import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/app_models.dart';
import 'analytics_service.dart';
import 'api_client.dart';
import 'app_config.dart';
import 'local_store.dart';

class SubmissionOutcome {
  const SubmissionOutcome({
    required this.queuedOffline,
    this.referenceId,
    this.duplicateCandidateIds = const [],
  });

  final bool queuedOffline;
  final String? referenceId;
  final List<String> duplicateCandidateIds;
}

class LeaderboardPayload {
  const LeaderboardPayload({required this.window, required this.items});

  final String window;
  final List<LeaderboardEntryModel> items;
}

class DealDropRepository {
  DealDropRepository({
    required DealDropApiClient apiClient,
    required LocalStore localStore,
    required AnalyticsService analytics,
    required AppConfig config,
  }) : _apiClient = apiClient,
       _localStore = localStore,
       _analytics = analytics,
       _config = config;

  final DealDropApiClient _apiClient;
  final LocalStore _localStore;
  final AnalyticsService _analytics;
  final AppConfig _config;

  Future<AuthPayload> signIn({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> response;
    try {
      response = _config.supabaseConfigured
          ? await _signInWithSupabase(email: email, password: password)
          : await _apiClient.postJson(
              '/v1/auth/sign-in',
              body: {'email': email, 'password': password},
            );
    } on ApiException {
      final fallback = _devSeedAuthPayload(email: email, password: password);
      if (!_config.supabaseConfigured && fallback != null) {
        await _localStore.clearCachedData();
        await _localStore.saveSession(fallback.session);
        await syncGuestFavorites();
        await _analytics.track(
          'auth_sign_in_success',
          screen: 'auth',
          properties: {'userId': fallback.session.userId, 'mode': 'dev_seed'},
        );
        return fallback;
      }
      rethrow;
    }
    final auth = AuthPayload.fromJson(response);
    await _localStore.clearCachedData();
    await _localStore.saveSession(auth.session);
    await syncGuestFavorites();
    await _analytics.track(
      'auth_sign_in_success',
      screen: 'auth',
      properties: {'userId': auth.session.userId},
    );
    return auth;
  }

  Future<AuthPayload> signUp({
    required String email,
    required String password,
    required String displayName,
    required String homeNeighborhood,
  }) async {
    final response = _config.supabaseConfigured
        ? await _signUpWithSupabase(
            email: email,
            password: password,
            displayName: displayName,
            homeNeighborhood: homeNeighborhood,
          )
        : await _apiClient.postJson(
            '/v1/auth/sign-up',
            body: {
              'email': email,
              'password': password,
              'displayName': displayName,
              'homeNeighborhood': homeNeighborhood,
            },
          );
    final auth = AuthPayload.fromJson(response);
    await _localStore.clearCachedData();
    await _localStore.saveSession(auth.session);
    await syncGuestFavorites();
    await _analytics.track(
      'auth_sign_up_success',
      screen: 'auth',
      properties: {'userId': auth.session.userId},
    );
    return auth;
  }

  AuthSessionModel? loadSession() => _localStore.loadSession();

  Future<void> signOut() async {
    if (_config.supabaseConfigured) {
      await supabase.Supabase.instance.client.auth.signOut();
    }
    await _localStore.clearSession();
    await _localStore.clearCachedData();
    await _analytics.track('auth_sign_out', screen: 'profile');
  }

  Future<Map<String, dynamic>> _signInWithSupabase({
    required String email,
    required String password,
  }) async {
    final response = await supabase.Supabase.instance.client.auth
        .signInWithPassword(email: email, password: password);
    if (response.session == null) {
      throw const ApiException(
        'Email confirmation is required before signing in.',
        statusCode: 401,
      );
    }
    return _apiClient.postJson('/v1/auth/bootstrap', authenticated: true);
  }

  Future<Map<String, dynamic>> _signUpWithSupabase({
    required String email,
    required String password,
    required String displayName,
    required String homeNeighborhood,
  }) async {
    final response = await supabase.Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        'home_neighborhood': homeNeighborhood,
      },
    );
    if (response.session == null) {
      throw const ApiException(
        'Check your email to confirm your account before signing in.',
        statusCode: 401,
      );
    }
    return _apiClient.postJson(
      '/v1/auth/bootstrap',
      authenticated: true,
      body: {'displayName': displayName, 'homeNeighborhood': homeNeighborhood},
    );
  }

  bool get isAuthenticated => _localStore.loadSession() != null;

  Future<FeedPayload> fetchHomeFeed() async {
    try {
      final response = await _apiClient.getJson('/v1/feed/home');
      await _localStore.cacheJson('feed-home', response);
      return _decorateFeed(FeedPayload.fromJson(response));
    } on ApiException {
      final cached = _localStore.readCachedJson('feed-home');
      if (cached != null) {
        return _decorateFeed(FeedPayload.fromJson(cached));
      }
      return _fallbackHomeFeed();
    }
  }

  Future<FiltersMetadataModel> fetchFilters() async {
    try {
      final response = await _apiClient.getJson('/v1/filters/metadata');
      await _localStore.cacheJson('filters', response);
      return FiltersMetadataModel.fromJson(response);
    } on ApiException {
      final cached = _localStore.readCachedJson('filters');
      if (cached != null) {
        return FiltersMetadataModel.fromJson(cached);
      }
      return _fallbackFilters();
    }
  }

  Future<SearchPayload> search({
    required String query,
    String? neighborhood,
    TrustBand? trustBand,
    String? sort,
  }) async {
    final response = await _apiClient.getJson(
      '/v1/search',
      queryParameters: {
        'q': query,
        if (neighborhood != null && neighborhood.isNotEmpty)
          'neighborhood': neighborhood,
        if (trustBand != null) 'trustBand': trustBandToApi(trustBand),
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      },
    );
    return _decorateSearch(SearchPayload.fromJson(response));
  }

  Future<Deal> fetchListingDetail(String listingId) async {
    try {
      final response = await _apiClient.getJson('/v1/listings/$listingId');
      await _localStore.cacheJson('listing-$listingId', response);
      return _decorateDeal(Deal.fromDetailJson(response));
    } on ApiException {
      final cached = _localStore.readCachedJson('listing-$listingId');
      if (cached != null) {
        return _decorateDeal(Deal.fromDetailJson(cached));
      }
      final fallback = _fallbackDealById(listingId);
      if (fallback != null) {
        return _decorateDeal(fallback);
      }
      rethrow;
    }
  }

  Future<Venue> fetchVenue(String venueId) async {
    final response = await _apiClient.getJson('/v1/venues/$venueId');
    return Venue.fromJson(response);
  }

  Future<List<Deal>> fetchNearbyDeals({
    required double latitude,
    required double longitude,
    double radiusMiles = 2.5,
  }) async {
    final response = await _apiClient.getJson(
      '/v1/listings/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusMiles': radiusMiles,
      },
    );
    final items = (response['items'] as List<dynamic>? ?? const [])
        .map((item) => Deal.fromCardJson(item as Map<String, dynamic>))
        .map(_decorateDeal)
        .toList();
    return items;
  }

  Future<List<MapDeal>> fetchMapListings({
    required double north,
    required double south,
    required double east,
    required double west,
    double? zoom,
    TrustBand? trustBand,
  }) async {
    final queryParameters = <String, dynamic>{
      'north': north,
      'south': south,
      'east': east,
      'west': west,
    };
    if (zoom != null) {
      queryParameters['zoom'] = zoom;
    }
    if (trustBand != null) {
      queryParameters['trustBand'] = trustBandToApi(trustBand);
    }
    final response = await _apiClient.getJsonList(
      '/v1/listings/map-bounds',
      queryParameters: queryParameters,
    );
    final favorites = await currentFavoriteIds();
    return response
        .map((item) => MapDeal.fromJson(item as Map<String, dynamic>))
        .map(
          (item) => MapDeal(
            listingId: item.listingId,
            venueId: item.venueId,
            venueName: item.venueName,
            latitude: item.latitude,
            longitude: item.longitude,
            trustBand: item.trustBand,
            title: item.title,
            neighborhood: item.neighborhood,
            confidenceScore: item.confidenceScore,
            affordabilityLabel: item.affordabilityLabel,
            saved: favorites.contains(item.listingId),
          ),
        )
        .toList();
  }

  Future<Set<String>> currentFavoriteIds() async {
    if (!isAuthenticated) {
      return _localStore.loadGuestFavorites();
    }
    final saved = await fetchSavedDeals();
    return saved.map((deal) => deal.id).toSet();
  }

  Future<List<Deal>> fetchSavedDeals() async {
    if (!isAuthenticated) {
      final favorites = _localStore.loadGuestFavorites();
      final feed = await fetchHomeFeed();
      final known = {
        for (final item in feed.sections.expand((section) => section.items))
          item.id: item,
      };
      return favorites
          .map((id) => known[id])
          .whereType<Deal>()
          .map((deal) => deal.copyWith(saved: true))
          .toList();
    }
    final response = await _apiClient.getJsonList(
      '/v1/me/saved',
      authenticated: true,
    );
    return response
        .map((item) => Deal.fromCardJson(item as Map<String, dynamic>))
        .map((deal) => deal.copyWith(saved: true))
        .toList();
  }

  Future<void> toggleFavorite(String listingId, {required bool save}) async {
    final authenticated = isAuthenticated;
    if (!authenticated) {
      final favorites = _localStore.loadGuestFavorites();
      if (save) {
        favorites.add(listingId);
      } else {
        favorites.remove(listingId);
      }
      await _localStore.saveGuestFavorites(favorites);
      await _analytics.track(
        save ? 'favorite_added_guest' : 'favorite_removed_guest',
        screen: 'deals',
        properties: {'listingId': listingId},
      );
      return;
    }

    try {
      if (save) {
        await _apiClient.postNoContent(
          '/v1/favorites/$listingId',
          authenticated: true,
          idempotent: true,
        );
      } else {
        await _apiClient.delete(
          '/v1/favorites/$listingId',
          authenticated: true,
        );
      }
      await _analytics.track(
        save ? 'favorite_added' : 'favorite_removed',
        screen: 'deals',
        properties: {'listingId': listingId},
      );
    } on ApiException {
      await _enqueueMutation(
        type: save ? 'favorite_add' : 'favorite_remove',
        payload: {'listingId': listingId},
      );
      rethrow;
    }
  }

  Future<void> syncGuestFavorites() async {
    if (!isAuthenticated) {
      return;
    }
    final guestFavorites = _localStore.loadGuestFavorites();
    if (guestFavorites.isEmpty) {
      return;
    }
    await _apiClient.postJson(
      '/v1/favorites/sync',
      authenticated: true,
      body: {'listingIds': guestFavorites.toList()},
      idempotent: true,
    );
    await _localStore.saveGuestFavorites(<String>{});
  }

  Future<AppProfile> fetchProfile() async {
    try {
      final response = await _apiClient.getJson(
        '/v1/me/profile',
        authenticated: true,
      );
      await _localStore.cacheJson('profile', response);
      return AppProfile.fromJson(response);
    } on ApiException {
      final cached = _localStore.readCachedJson('profile');
      if (cached != null) {
        return AppProfile.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<KarmaSnapshot> fetchKarma({String window = 'weekly'}) async {
    try {
      final response = await _apiClient.getJson(
        '/v1/me/karma',
        queryParameters: {'window': window},
        authenticated: true,
      );
      await _localStore.cacheJson('karma-$window', response);
      return KarmaSnapshot.fromJson(response);
    } on ApiException {
      final cached = _localStore.readCachedJson('karma-$window');
      if (cached != null) {
        return KarmaSnapshot.fromJson(cached);
      }
      return _fallbackKarma(window);
    }
  }

  Future<List<ContributionRecordModel>> fetchContributions() async {
    try {
      final response = await _apiClient.getJson(
        '/v1/me/contributions',
        authenticated: true,
      );
      final items = (response['items'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                ContributionRecordModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      return items;
    } on ApiException {
      return _fallbackContributions();
    }
  }

  Future<LeaderboardPayload> fetchLeaderboard({
    String window = 'weekly',
  }) async {
    try {
      final response = await _apiClient.getJson(
        '/v1/leaderboards',
        queryParameters: {'window': window},
        authenticated: true,
      );
      return LeaderboardPayload(
        window: response['window'] as String? ?? window,
        items: (response['items'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  LeaderboardEntryModel.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
    } on ApiException {
      return LeaderboardPayload(window: window, items: _fallbackLeaderboard());
    }
  }

  Future<NotificationsPayload> fetchNotifications() async {
    try {
      final response = await _apiClient.getJson(
        '/v1/notifications',
        authenticated: true,
      );
      await _localStore.cacheJson('notifications', response);
      return NotificationsPayload.fromJson(response);
    } on ApiException {
      final cached = _localStore.readCachedJson('notifications');
      if (cached != null) {
        return NotificationsPayload.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _apiClient.postJson(
      '/v1/notifications/$id/read',
      authenticated: true,
    );
    final cached = _localStore.readCachedJson('notifications');
    if (cached == null) {
      return;
    }
    final items = (cached['items'] as List<dynamic>? ?? const []).map((item) {
      final value = Map<String, dynamic>.from(item as Map);
      if (value['id'] == id && value['readAt'] == null) {
        value['readAt'] = DateTime.now().toUtc().toIso8601String();
      }
      return value;
    }).toList();
    await _localStore.cacheJson('notifications', {
      'items': items,
      'unreadCount': items.where((item) => item['readAt'] == null).length,
    });
  }

  Future<PreferencesModel> fetchPreferences() async {
    final response = await _apiClient.getJson(
      '/v1/me/preferences',
      authenticated: true,
    );
    return PreferencesModel.fromJson(response);
  }

  Future<PreferencesModel> updatePreferences(
    PreferencesModel preferences,
  ) async {
    final response = await _apiClient.putJson(
      '/v1/me/preferences',
      body: preferences.toJson(),
      authenticated: true,
    );
    return PreferencesModel.fromJson(response);
  }

  Future<SubmissionOutcome> submitNewContribution({
    required String venueName,
    required String neighborhood,
    required String title,
    required String description,
    required String conditions,
    required String scheduleSummary,
    double latitude = 33.780,
    double longitude = -84.387,
    List<String> tags = const [],
    Map<String, dynamic>? googlePlace,
  }) async {
    return _submitContribution(
      type: 'new_listing',
      onlineCall: () => _apiClient.postJson(
        '/v1/contributions/listings',
        authenticated: true,
        idempotent: true,
        body: {
          'venueName': venueName,
          'neighborhood': neighborhood,
          'latitude': latitude,
          'longitude': longitude,
          'title': title,
          'description': description,
          'conditions': conditions,
          'scheduleSummary': scheduleSummary,
          'tags': tags,
          ...googlePlace == null ? const {} : {'googlePlace': googlePlace},
          'proofAssetKeys': const [],
        },
      ),
      offlinePayload: {
        'venueName': venueName,
        'neighborhood': neighborhood,
        'latitude': latitude,
        'longitude': longitude,
        'title': title,
        'description': description,
        'conditions': conditions,
        'scheduleSummary': scheduleSummary,
        'tags': tags,
        ...googlePlace == null ? const {} : {'googlePlace': googlePlace},
      },
    );
  }

  Future<SubmissionOutcome> submitListingUpdate({
    required String listingId,
    String? title,
    String? description,
    String? conditions,
    String? scheduleSummary,
  }) async {
    final requestBody = <String, dynamic>{'proofAssetKeys': const []};
    if (title != null) {
      requestBody['title'] = title;
    }
    if (description != null) {
      requestBody['description'] = description;
    }
    if (conditions != null) {
      requestBody['conditions'] = conditions;
    }
    if (scheduleSummary != null) {
      requestBody['scheduleSummary'] = scheduleSummary;
    }
    return _submitContribution(
      type: 'listing_update',
      onlineCall: () => _apiClient.postJson(
        '/v1/contributions/listings/$listingId/update',
        authenticated: true,
        idempotent: true,
        body: requestBody,
      ),
      offlinePayload: {
        'listingId': listingId,
        'title': title,
        'description': description,
        'conditions': conditions,
        'scheduleSummary': scheduleSummary,
      },
    );
  }

  Future<SubmissionOutcome> confirmListing({required String listingId}) async {
    return _submitContribution(
      type: 'confirm_listing',
      onlineCall: () => _apiClient.postJson(
        '/v1/listings/$listingId/confirm',
        authenticated: true,
        idempotent: true,
        body: const {},
      ),
      offlinePayload: {'listingId': listingId},
    );
  }

  Future<SubmissionOutcome> reportExpired({
    required String listingId,
    required String reason,
    String? notes,
  }) async {
    return _submitContribution(
      type: 'report_expired',
      onlineCall: () => _apiClient.postJson(
        '/v1/listings/$listingId/report-expired',
        authenticated: true,
        idempotent: true,
        body: {
          'reason': reason,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      offlinePayload: {
        'listingId': listingId,
        'reason': reason,
        'notes': notes,
      },
    );
  }

  Future<String> requestProofUploadSlot() async {
    final response = await _apiClient.postJson(
      '/v1/contributions/proofs/presign',
      authenticated: true,
      body: {'contentType': 'image/jpeg'},
      idempotent: true,
    );
    return response['assetKey'] as String? ?? '';
  }

  Future<List<OfflineMutation>> flushOfflineQueue() async {
    final session = _localStore.loadSession();
    if (session == null) {
      return _localStore.loadOfflineQueue();
    }
    final pending = _localStore.loadOfflineQueue();
    final remaining = <OfflineMutation>[];
    for (final mutation in pending) {
      if (mutation.actorUserId != null &&
          mutation.actorUserId != session.userId) {
        remaining.add(mutation);
        continue;
      }
      try {
        await _replayMutation(mutation);
      } on ApiException {
        remaining.add(
          OfflineMutation(
            id: mutation.id,
            type: mutation.type,
            payload: mutation.payload,
            createdAt: mutation.createdAt,
            retryCount: mutation.retryCount + 1,
            actorUserId: mutation.actorUserId,
          ),
        );
      }
    }
    await _localStore.saveOfflineQueue(remaining);
    return remaining;
  }

  Future<void> registerDevice({
    required String deviceId,
    required String platform,
    String? pushToken,
    bool notificationsEnabled = true,
  }) async {
    if (!isAuthenticated) {
      return;
    }
    await _apiClient.postJson(
      '/v1/devices/register',
      authenticated: true,
      body: {
        'deviceId': deviceId,
        'platform': platform,
        'pushToken': pushToken,
        'locale': 'en-US',
        'notificationsEnabled': notificationsEnabled,
      },
      idempotent: true,
    );
  }

  Future<SubmissionOutcome> _submitContribution({
    required String type,
    required Future<Map<String, dynamic>> Function() onlineCall,
    required Map<String, dynamic> offlinePayload,
  }) async {
    try {
      final response = await onlineCall();
      await _analytics.track(
        'contribution_submitted',
        screen: 'post',
        properties: {'type': type},
      );
      return SubmissionOutcome(
        queuedOffline: false,
        referenceId:
            (response['contributionId'] as String?) ??
            (response['reportId'] as String?),
        duplicateCandidateIds:
            (response['duplicateCandidateIds'] as List<dynamic>? ?? const [])
                .cast<String>(),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        rethrow;
      }
      await _enqueueMutation(type: type, payload: offlinePayload);
      await _analytics.track(
        'contribution_queued_offline',
        screen: 'post',
        properties: {'type': type},
      );
      return const SubmissionOutcome(queuedOffline: true);
    }
  }

  Future<void> _enqueueMutation({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final queue = _localStore.loadOfflineQueue();
    final actorUserId = _localStore.loadSession()?.userId;
    queue.add(
      OfflineMutation(
        id: 'offline-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        payload: payload,
        createdAt: DateTime.now().toUtc(),
        retryCount: 0,
        actorUserId: actorUserId,
      ),
    );
    await _localStore.saveOfflineQueue(queue);
  }

  Future<void> _replayMutation(OfflineMutation mutation) async {
    switch (mutation.type) {
      case 'favorite_add':
        await _apiClient.postNoContent(
          '/v1/favorites/${mutation.payload['listingId']}',
          authenticated: true,
          idempotent: true,
        );
        return;
      case 'favorite_remove':
        await _apiClient.delete(
          '/v1/favorites/${mutation.payload['listingId']}',
          authenticated: true,
        );
        return;
      case 'confirm_listing':
        await _apiClient.postJson(
          '/v1/listings/${mutation.payload['listingId']}/confirm',
          authenticated: true,
          idempotent: true,
          body: const {},
        );
        return;
      case 'report_expired':
        await _apiClient.postJson(
          '/v1/listings/${mutation.payload['listingId']}/report-expired',
          authenticated: true,
          idempotent: true,
          body: {
            'reason': mutation.payload['reason'],
            if (mutation.payload['notes'] != null)
              'notes': mutation.payload['notes'],
          },
        );
        return;
      case 'listing_update':
        await _apiClient.postJson(
          '/v1/contributions/listings/${mutation.payload['listingId']}/update',
          authenticated: true,
          idempotent: true,
          body: {
            if (mutation.payload['title'] != null)
              'title': mutation.payload['title'],
            if (mutation.payload['description'] != null)
              'description': mutation.payload['description'],
            if (mutation.payload['conditions'] != null)
              'conditions': mutation.payload['conditions'],
            if (mutation.payload['scheduleSummary'] != null)
              'scheduleSummary': mutation.payload['scheduleSummary'],
            'proofAssetKeys': const [],
          },
        );
        return;
      case 'new_listing':
        await _apiClient.postJson(
          '/v1/contributions/listings',
          authenticated: true,
          idempotent: true,
          body: {...mutation.payload, 'proofAssetKeys': const []},
        );
        return;
    }
  }

  FeedPayload _decorateFeed(FeedPayload payload) {
    final favorites = _localStore.loadGuestFavorites();
    if (isAuthenticated) {
      return payload;
    }
    return FeedPayload(
      sections: payload.sections
          .map(
            (section) => FeedSectionModel(
              id: section.id,
              title: section.title,
              subtitle: section.subtitle,
              items: section.items
                  .map(
                    (deal) => favorites.contains(deal.id)
                        ? deal.copyWith(saved: true)
                        : deal,
                  )
                  .toList(),
            ),
          )
          .toList(),
      nextCursor: payload.nextCursor,
    );
  }

  SearchPayload _decorateSearch(SearchPayload payload) {
    final favorites = _localStore.loadGuestFavorites();
    if (isAuthenticated) {
      return payload;
    }
    return SearchPayload(
      listings: payload.listings
          .map(
            (deal) =>
                favorites.contains(deal.id) ? deal.copyWith(saved: true) : deal,
          )
          .toList(),
      venues: payload.venues,
      neighborhoods: payload.neighborhoods,
      suggestions: payload.suggestions,
      nextCursor: payload.nextCursor,
    );
  }

  Deal _decorateDeal(Deal deal) {
    if (isAuthenticated) {
      return deal;
    }
    return _localStore.loadGuestFavorites().contains(deal.id)
        ? deal.copyWith(saved: true)
        : deal;
  }

  FeedPayload _fallbackHomeFeed() {
    final deals = _fallbackDealCards
        .map((item) => _decorateDeal(Deal.fromCardJson(item)))
        .toList();
    final liveNow = deals
        .where((deal) => deal.scheduleLabel.toLowerCase().contains('live'))
        .toList();
    final tonight = deals
        .where((deal) => deal.scheduleLabel.toLowerCase().contains('tonight'))
        .toList();

    return FeedPayload(
      sections: [
        FeedSectionModel(
          id: 'live-now',
          title: 'Live now near you',
          subtitle: 'Launch-market deals available while the feed reconnects.',
          items: liveNow.isEmpty ? deals.take(3).toList() : liveNow,
        ),
        FeedSectionModel(
          id: 'tonight',
          title: 'Tonight',
          subtitle: 'Evening picks from the bundled DealDrop launch data.',
          items: tonight.isEmpty ? deals.skip(1).take(3).toList() : tonight,
        ),
        FeedSectionModel(
          id: 'fresh-this-week',
          title: 'Fresh this week',
          subtitle: 'Recently verified fallback listings.',
          items: deals,
        ),
      ],
      nextCursor: null,
    );
  }

  FiltersMetadataModel _fallbackFilters() {
    final neighborhoods =
        _fallbackDealCards.map((item) => item['neighborhood'] as String).toSet()
          ..removeWhere((item) => item.isEmpty);
    final cuisines =
        _fallbackDealCards.map((item) => item['cuisine'] as String).toSet()
          ..removeWhere((item) => item.isEmpty);
    final tags = _fallbackDealCards
        .expand((item) => (item['tags'] as List<String>))
        .toSet();

    return FiltersMetadataModel(
      neighborhoods: (neighborhoods.toList()..sort()),
      tags: (tags.toList()..sort()),
      cuisines: (cuisines.toList()..sort()),
      trustBands: TrustBand.values,
    );
  }

  Deal? _fallbackDealById(String listingId) {
    for (final json in _fallbackDealCards) {
      if (json['id'] == listingId) {
        return Deal.fromCardJson(json);
      }
    }
    return null;
  }

  KarmaSnapshot _fallbackKarma(String window) {
    final session = loadSession();
    final seed = session == null ? null : _devSeedUsers[session.email];
    return KarmaSnapshot(
      userId: session?.userId ?? 'usr_alex',
      points: session?.verifiedContributor == true ? 71 : 18,
      pendingPoints: 8,
      verifiedContributor: session?.verifiedContributor ?? true,
      currentStreakDays: 1,
      level: session?.verifiedContributor == true ? 'Deal Scout' : 'Newcomer',
      nextLevelPoints: 29,
      impactUsersHelped: seed?.verifiedContributor == false ? 18 : 79,
      approvedContributions: 1,
      pendingContributions: 1,
      badges: _fallbackBadges(),
      leaderboardWindow: window,
      leaderboard: _fallbackLeaderboard(),
    );
  }

  List<BadgeModel> _fallbackBadges() {
    const rows = [
      {
        'code': 'first-proof',
        'title': 'First Proof',
        'description': 'Accepted proof.',
        'unlocked': true,
      },
      {
        'code': 'week-streak',
        'title': 'Seven Day Run',
        'description': 'Keep a weekly streak.',
        'unlocked': true,
      },
      {
        'code': 'trust-anchor',
        'title': 'Trust Anchor',
        'description': 'High-accuracy confirms.',
        'unlocked': false,
      },
    ];
    return rows.map(BadgeModel.fromJson).toList();
  }

  List<LeaderboardEntryModel> _fallbackLeaderboard() {
    const rows = [
      {
        'rank': 1,
        'userId': 'usr_maya',
        'displayName': 'Maya Brooks',
        'verifiedContributor': true,
        'title': 'Deal Scout',
        'points': 39,
      },
      {
        'rank': 2,
        'userId': 'usr_jon',
        'displayName': 'Jon Patel',
        'verifiedContributor': true,
        'title': 'Newcomer',
        'points': 18,
      },
      {
        'rank': 3,
        'userId': 'usr_alex',
        'displayName': 'Alex Morgan',
        'verifiedContributor': true,
        'title': 'Newcomer',
        'points': 14,
      },
      {
        'rank': 4,
        'userId': 'usr_sam',
        'displayName': 'Sam Rivera',
        'verifiedContributor': false,
        'title': 'Newcomer',
        'points': 0,
      },
    ];
    return rows.map(LeaderboardEntryModel.fromJson).toList();
  }

  List<ContributionRecordModel> _fallbackContributions() {
    const rows = [
      {
        'id': 'fallback-contribution-proof',
        'listingId': 'lst_bogo_ramen',
        'listingTitle': 'BOGO ramen bowls',
        'venueName': 'Sakura Ramen House',
        'neighborhood': 'Midtown',
        'type': 'confirmation',
        'status': 'approved',
        'createdAt': '2026-05-04T13:00:00.000Z',
        'summary': 'Confirmed active deal.',
        'pointsDelta': 12,
        'pointsStatus': 'finalized',
      },
      {
        'id': 'fallback-contribution-update',
        'listingId': 'lst_happy_hour_pitcher',
        'listingTitle': 'Half-off pitcher happy hour',
        'venueName': 'Beltline Bar',
        'neighborhood': 'Beltline East',
        'type': 'update',
        'status': 'under_review',
        'createdAt': '2026-05-03T19:30:00.000Z',
        'summary': 'Submitted schedule update.',
        'pointsDelta': 8,
        'pointsStatus': 'pending',
      },
    ];
    return rows.map(ContributionRecordModel.fromJson).toList();
  }

  AuthPayload? _devSeedAuthPayload({
    required String email,
    required String password,
  }) {
    if (password != 'dealdrop123') {
      return null;
    }
    final normalizedEmail = email.trim().toLowerCase();
    final seed = _devSeedUsers[normalizedEmail];
    if (seed == null) {
      return null;
    }
    final session = AuthSessionModel(
      userId: seed.userId,
      email: normalizedEmail,
      displayName: seed.displayName,
      role: seed.role,
      verifiedContributor: seed.verifiedContributor,
    );
    final profile = AppProfile(
      id: seed.userId,
      email: normalizedEmail,
      displayName: seed.displayName,
      homeNeighborhood: seed.homeNeighborhood,
      role: seed.role,
      verifiedContributor: seed.verifiedContributor,
    );
    return AuthPayload(session: session, profile: profile);
  }
}

class _DevSeedUser {
  const _DevSeedUser({
    required this.userId,
    required this.displayName,
    required this.homeNeighborhood,
    required this.role,
    required this.verifiedContributor,
  });

  final String userId;
  final String displayName;
  final String homeNeighborhood;
  final String role;
  final bool verifiedContributor;
}

const _devSeedUsers = <String, _DevSeedUser>{
  'alex@dealdrop.app': _DevSeedUser(
    userId: 'usr_alex',
    displayName: 'Alex Morgan',
    homeNeighborhood: 'West Midtown',
    role: 'user',
    verifiedContributor: true,
  ),
  'maya@dealdrop.app': _DevSeedUser(
    userId: 'usr_maya',
    displayName: 'Maya Brooks',
    homeNeighborhood: 'Ponce',
    role: 'moderator',
    verifiedContributor: true,
  ),
  'jon@dealdrop.app': _DevSeedUser(
    userId: 'usr_jon',
    displayName: 'Jon Patel',
    homeNeighborhood: 'North Avenue',
    role: 'admin',
    verifiedContributor: true,
  ),
  'sam@dealdrop.app': _DevSeedUser(
    userId: 'usr_sam',
    displayName: 'Sam Rivera',
    homeNeighborhood: 'Colony Square',
    role: 'user',
    verifiedContributor: false,
  ),
};

const _fallbackDealCards = <Map<String, dynamic>>[
  {
    'id': 'fallback-taco-mesa-happy-hour',
    'venueId': 'fallback-taco-mesa',
    'venueName': 'Taco Mesa',
    'title': '2 tacos and agua fresca for \$9',
    'neighborhood': 'Midtown',
    'distanceMiles': 0.6,
    'rating': 4.7,
    'cuisine': 'Mexican',
    'categoryLabel': 'Lunch special',
    'scheduleLabel': 'Live now until 3 PM',
    'trustBand': 'founder_verified',
    'freshnessText': 'Verified today',
    'lastUpdatedAt': '2026-05-04T15:00:00.000Z',
    'affordabilityLabel': 'Under \$10',
    'valueNote': 'Best value before the afternoon rush.',
    'latitude': 33.7848,
    'longitude': -84.3844,
    'confidenceScore': 0.94,
    'tags': ['lunch', 'tacos', 'quick-bite'],
  },
  {
    'id': 'fallback-ruby-bowl-ramen',
    'venueId': 'fallback-ruby-bowl',
    'venueName': 'Ruby Bowl',
    'title': 'Half-price miso ramen',
    'neighborhood': 'Old Fourth Ward',
    'distanceMiles': 1.2,
    'rating': 4.5,
    'cuisine': 'Japanese',
    'categoryLabel': 'Dinner deal',
    'scheduleLabel': 'Tonight after 6 PM',
    'trustBand': 'merchant_confirmed',
    'freshnessText': 'Merchant confirmed',
    'lastUpdatedAt': '2026-05-04T13:30:00.000Z',
    'affordabilityLabel': 'Under \$15',
    'valueNote': 'Limited bowls available each night.',
    'latitude': 33.7646,
    'longitude': -84.3582,
    'confidenceScore': 0.88,
    'tags': ['dinner', 'ramen', 'comfort-food'],
  },
  {
    'id': 'fallback-piedmont-slice',
    'venueId': 'fallback-piedmont-slice',
    'venueName': 'Piedmont Slice',
    'title': 'Two slices and soda for \$7',
    'neighborhood': 'Virginia-Highland',
    'distanceMiles': 1.8,
    'rating': 4.4,
    'cuisine': 'Pizza',
    'categoryLabel': 'Student deal',
    'scheduleLabel': 'Live now',
    'trustBand': 'user_confirmed',
    'freshnessText': 'Confirmed by users',
    'lastUpdatedAt': '2026-05-04T14:10:00.000Z',
    'affordabilityLabel': 'Under \$10',
    'valueNote': 'Fast counter-service deal.',
    'latitude': 33.7824,
    'longitude': -84.3531,
    'confidenceScore': 0.83,
    'tags': ['pizza', 'cheap-eats', 'student'],
  },
  {
    'id': 'fallback-copper-lantern',
    'venueId': 'fallback-copper-lantern',
    'venueName': 'Copper Lantern',
    'title': '\$6 spritz and small plates',
    'neighborhood': 'Inman Park',
    'distanceMiles': 2.1,
    'rating': 4.6,
    'cuisine': 'Bar',
    'categoryLabel': 'Happy hour',
    'scheduleLabel': 'Tonight 5-7 PM',
    'trustBand': 'recently_updated',
    'freshnessText': 'Fresh this week',
    'lastUpdatedAt': '2026-05-03T22:00:00.000Z',
    'affordabilityLabel': 'Under \$15',
    'valueNote': 'Works best for early evening groups.',
    'latitude': 33.7615,
    'longitude': -84.3599,
    'confidenceScore': 0.79,
    'tags': ['drinks', 'happy-hour', 'small-plates'],
  },
];
