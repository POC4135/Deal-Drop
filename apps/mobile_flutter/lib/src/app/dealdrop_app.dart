import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/app_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class DealDropApp extends ConsumerStatefulWidget {
  const DealDropApp({super.key});

  @override
  ConsumerState<DealDropApp> createState() => _DealDropAppState();
}

class _DealDropAppState extends ConsumerState<DealDropApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(repositoryProvider).flushOfflineQueue();
      ref.read(authControllerProvider.notifier).refreshProfile();
      ref.read(analyticsServiceProvider).flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'DealDrop',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: buildDealDropTheme(),
    );
  }
}
