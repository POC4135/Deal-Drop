import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).track('screen_view', screen: 'welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8EA),
              DealDropPalette.cream,
              Color(0xFFF7EFE3),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DealDropPalette.goldDeep, DealDropPalette.gold],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: DealDropShadows.soft,
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 30),
                Text(
                  'Deal\nDrop',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 58),
                ),
                const SizedBox(height: 18),
                Text(
                  'Fast local restaurant value, with trust that is legible enough to act on in seconds.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Atlanta-first, freshness-weighted, and built to tell you what is actually worth the walk.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 34),
                const _HeroProofRail(),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/auth/sign-up'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Create account'),
                    iconAlignment: IconAlignment.end,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/auth/sign-in'),
                    child: const Text('Sign in'),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).continueAsGuest();
                      if (context.mounted) {
                        context.go('/deals');
                      }
                    },
                    child: const Text('Continue as guest'),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: DealDropShadows.card,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: DealDropPalette.mint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.place_outlined, color: DealDropPalette.mintDeep),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Browse now, keep local saves as a guest, and sync them once you sign in.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'By continuing, you agree to the community standards that keep trust and freshness useful.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroProofRail extends StatelessWidget {
  const _HeroProofRail();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _ProofTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Trust-first',
            subtitle: 'Founder, merchant, and community-backed states',
            tint: DealDropPalette.goldSoft,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _ProofTile(
            icon: Icons.bolt_rounded,
            title: 'Live relevance',
            subtitle: 'Fresh this week, tonight, and live-now modules',
            tint: DealDropPalette.sky,
          ),
        ),
      ],
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        boxShadow: DealDropShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: DealDropPalette.ink),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
