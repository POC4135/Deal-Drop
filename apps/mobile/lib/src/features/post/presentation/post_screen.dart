import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PostScreen extends StatelessWidget {
  const PostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const actions = [
      _ContributionAction(
        title: 'Suggest a new deal',
        description: 'Submit a new local listing for moderator review.',
        icon: Icons.add_circle_outline_rounded,
        slug: 'suggest-deal',
        tint: DealDropPalette.goldSoft,
      ),
      _ContributionAction(
        title: 'Suggest an update',
        description: 'Fix timing, pricing, restrictions, or location issues.',
        icon: Icons.edit_outlined,
        slug: 'suggest-update',
        tint: DealDropPalette.sky,
      ),
      _ContributionAction(
        title: 'Confirm still active',
        description: 'Boost confidence for a listing you just saw in-market.',
        icon: Icons.verified_rounded,
        slug: 'confirm-active',
        tint: Color(0xFFDDF7EE),
      ),
      _ContributionAction(
        title: 'Report expired',
        description: 'Flag stale or conflicting offers before more users waste time.',
        icon: Icons.report_gmailerrorred_rounded,
        slug: 'report-expired',
        tint: Color(0xFFFFE5CC),
      ),
    ];

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DealDropPalette.goldDeep, DealDropPalette.gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: DealDropShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'QUALITY CONTRIBUTIONS ONLY',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Keep Atlanta fresh',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Every action on this tab improves trust, freshness, or confidence. Nothing publishes straight to the feed without review.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.88),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                for (final action in actions) ...[
                  _ActionCard(
                    action: action,
                    onTap: () => context.push('/contribute/${action.slug}'),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: DealDropShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How quality is protected', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      const _BulletLine('Points start as pending and finalize after moderation or consensus.'),
                      const _BulletLine('Duplicate or low-signal submissions earn nothing.'),
                      const _BulletLine('Higher-trust contributors carry more weight over time.'),
                      const _BulletLine('Evidence uploads are optional but boost moderation speed.'),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.onTap,
  });

  final _ContributionAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: DealDropShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: action.tint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(action.icon, color: DealDropPalette.ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(action.description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: DealDropPalette.muted),
          ],
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8, color: DealDropPalette.goldDeep),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ContributionAction {
  const _ContributionAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.slug,
    required this.tint,
  });

  final String title;
  final String description;
  final IconData icon;
  final String slug;
  final Color tint;
}
