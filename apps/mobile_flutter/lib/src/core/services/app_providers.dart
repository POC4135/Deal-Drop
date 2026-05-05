import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_models.dart';
import 'analytics_service.dart';
import 'api_client.dart';
import 'app_config.dart';
import 'dealdrop_repository.dart';
import 'local_store.dart';
import 'push_notification_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden at startup.',
  );
});

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final localStoreProvider = Provider<LocalStore>((ref) {
  return LocalStore(ref.watch(sharedPreferencesProvider));
});

final apiClientProvider = Provider<DealDropApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final store = ref.watch(localStoreProvider);
  return DealDropApiClient(
    config: config,
    sessionReader: () async => store.loadSession(),
    accessTokenReader: () async => config.supabaseConfigured
        ? Supabase.instance.client.auth.currentSession?.accessToken
        : null,
  );
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(apiClientProvider));
});

final repositoryProvider = Provider<DealDropRepository>((ref) {
  return DealDropRepository(
    apiClient: ref.watch(apiClientProvider),
    localStore: ref.watch(localStoreProvider),
    analytics: ref.watch(analyticsServiceProvider),
    config: ref.watch(appConfigProvider),
  );
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(
    repository: ref.watch(repositoryProvider),
    localStore: ref.watch(localStoreProvider),
  );
});

class AuthState {
  const AuthState({
    required this.initialized,
    required this.isGuest,
    this.session,
    this.profile,
    this.error,
  });

  final bool initialized;
  final bool isGuest;
  final AuthSessionModel? session;
  final AppProfile? profile;
  final String? error;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    bool? initialized,
    bool? isGuest,
    AuthSessionModel? session,
    AppProfile? profile,
    String? error,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      isGuest: isGuest ?? this.isGuest,
      session: session ?? this.session,
      profile: profile ?? this.profile,
      error: error,
    );
  }

  static const loading = AuthState(initialized: false, isGuest: true);
}

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repository = ref.read(repositoryProvider);
    final session = repository.loadSession();
    if (session == null) {
      return const AuthState(initialized: true, isGuest: true);
    }
    await ref.read(pushNotificationServiceProvider).registerCurrentDevice();
    try {
      final profile = await repository.fetchProfile();
      return AuthState(
        initialized: true,
        isGuest: false,
        session: session,
        profile: profile,
      );
    } catch (_) {
      return AuthState(initialized: true, isGuest: false, session: session);
    }
  }

  Future<void> continueAsGuest() async {
    state = AsyncData(const AuthState(initialized: true, isGuest: true));
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final payload = await ref
          .read(repositoryProvider)
          .signIn(email: email, password: password);
      await ref.read(pushNotificationServiceProvider).registerCurrentDevice();
      return AuthState(
        initialized: true,
        isGuest: false,
        session: payload.session,
        profile: payload.profile,
      );
    });
    state = result;
    if (result.hasError) {
      throw result.error!;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String homeNeighborhood,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final payload = await ref
          .read(repositoryProvider)
          .signUp(
            email: email,
            password: password,
            displayName: displayName,
            homeNeighborhood: homeNeighborhood,
          );
      await ref.read(pushNotificationServiceProvider).registerCurrentDevice();
      return AuthState(
        initialized: true,
        isGuest: false,
        session: payload.session,
        profile: payload.profile,
      );
    });
    state = result;
    if (result.hasError) {
      throw result.error!;
    }
  }

  Future<void> signOut() async {
    await ref.read(pushNotificationServiceProvider).unregisterCurrentDevice();
    await ref.read(repositoryProvider).signOut();
    state = const AsyncData(AuthState(initialized: true, isGuest: true));
  }

  Future<void> refreshProfile() async {
    final current = state.valueOrNull;
    if (current?.session == null) {
      return;
    }
    try {
      final profile = await ref.read(repositoryProvider).fetchProfile();
      state = AsyncData(current!.copyWith(profile: profile, error: null));
    } catch (error) {
      state = AsyncData(current!.copyWith(error: '$error'));
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
