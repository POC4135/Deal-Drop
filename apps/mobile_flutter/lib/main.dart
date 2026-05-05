import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/dealdrop_app.dart';
import 'src/core/services/app_config.dart';
import 'src/core/services/app_providers.dart';
import 'src/core/services/google_maps_loader.dart';
import 'src/core/services/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final localStore = LocalStore(preferences);
  await localStore.initialize();
  final config = AppConfig.fromEnvironment();
  if (config.supabaseConfigured) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabasePublishableKey,
    );
  }
  await ensureGoogleMapsLoaded(config);
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        localStoreProvider.overrideWithValue(localStore),
        appConfigProvider.overrideWithValue(config),
      ],
      child: const DealDropApp(),
    ),
  );
}
