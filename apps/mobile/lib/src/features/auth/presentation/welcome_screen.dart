import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9F0),
              DealDropPalette.cream,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DealDropPalette.goldDeep, DealDropPalette.gold],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
                ),
                const SizedBox(height: 26),
                Text(
                  'Deal\nDrop',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 60,
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Discover unbeatable local restaurant deals, earn Karma points, and never overpay again.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 52),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/auth/sign-up'),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Sign Up'),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/auth/sign-in'),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/deals'),
                    child: const Text('Continue as guest'),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: const [
                    Expanded(
                      child: _ProofTile(
                        icon: Icons.restaurant_rounded,
                        title: '500+ spots',
                        subtitle: 'Verified local deals',
                        tint: DealDropPalette.mint,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _ProofTile(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Karma points',
                        subtitle: 'Stack rewards',
                        tint: DealDropPalette.lilac,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Live deals in Midtown and West Midtown',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'By continuing, you agree to our Terms and Privacy Policy.',
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
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        boxShadow: DealDropShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: DealDropPalette.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
