import 'dart:async';

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

class _DealDropAppState extends ConsumerState<DealDropApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _pushDeepLinkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pushDeepLinkSubscription = ref
        .read(pushNotificationServiceProvider)
        .deepLinks
        .listen(_openPushDeepLink);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pushDeepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(repositoryProvider).flushOfflineQueue();
      ref.read(authControllerProvider.notifier).refreshProfile();
      ref.read(pushNotificationServiceProvider).registerCurrentDevice();
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

  void _openPushDeepLink(String deepLink) {
    if (!mounted || !deepLink.startsWith('/')) {
      return;
    }
    ref.read(appRouterProvider).go(deepLink);
  }
}
