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
    final response = _config.supabaseConfigured
        ? await _signInWithSupabase(email: email, password: password)
        : await _apiClient.postJson(
            '/v1/auth/sign-in',
            body: {'email': email, 'password': password},
          );
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
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  Future<List<ContributionRecordModel>> fetchContributions() async {
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
  }

  Future<LeaderboardPayload> fetchLeaderboard({
    String window = 'weekly',
  }) async {
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
}
