import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/notifications_screen.dart';
import '../../features/account/presentation/profile_screen.dart';
import '../../features/account/presentation/saved_screen.dart';
import '../../features/auth/presentation/auth_form_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/discovery/presentation/screens/deals_screen.dart';
import '../../features/karma/presentation/karma_screen.dart';
import '../../features/listing/presentation/listing_detail_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/post/presentation/contribution_form_screen.dart';
import '../../features/post/presentation/post_screen.dart';
import '../widgets/dealdrop_bottom_nav.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/:mode',
        builder: (context, state) {
          final mode = state.pathParameters['mode'] ?? 'sign-up';
          return AuthFormScreen(mode: mode);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DealDropShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/deals',
                builder: (context, state) => const DealsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/post',
                builder: (context, state) => const PostScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/karma',
                builder: (context, state) => const KarmaScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/listing/:listingId',
        builder: (context, state) {
          final listingId = state.pathParameters['listingId']!;
          return ListingDetailScreen(listingId: listingId);
        },
      ),
      GoRoute(
        path: '/account/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/account/saved',
        builder: (context, state) => const SavedScreen(),
      ),
      GoRoute(
        path: '/account/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/contribute/:action',
        builder: (context, state) {
          final action = state.pathParameters['action']!;
          return ContributionFormScreen(actionSlug: action);
        },
      ),
    ],
  );
});

class DealDropShell extends StatelessWidget {
  const DealDropShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DealDropBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
      ),
    );
  }
}
