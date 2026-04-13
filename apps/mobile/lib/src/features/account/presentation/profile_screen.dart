import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final points = NumberFormat.decimalPattern().format(8340);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeaderIcon(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                  const Spacer(),
                  _HeaderIcon(icon: Icons.settings_outlined, onTap: () {}),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DealDropPalette.warmSurface,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: DealDropShadows.card,
                          ),
                          child: Center(
                            child: Text(
                              'JC',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: DealDropPalette.goldDeep,
                                  ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -6,
                          bottom: 4,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: DealDropPalette.mintDeep,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.verified, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Joon Choi', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 8),
                    Text('Atlanta, GA', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(value: points, label: 'Karma points'),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: _StatCard(value: '4', label: 'Elite badges'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text('Friends', style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE4F8F2),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: const Icon(Icons.person_add_alt_rounded, color: DealDropPalette.mintDeep),
                    label: const Text('Add friends'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final friend in const [
                ('Sarah M.', 'Deal hunter', '12.4k'),
                ('Jake T.', 'Moderator', '9.1k'),
                ('Priya K.', 'Campus legend', '15.8k'),
                ('Marcus D.', 'Deal hunter', '7.2k'),
                ('Ling W.', 'Newcomer', '4.5k'),
              ]) ...[
                _FriendRow(name: friend.$1, subtitle: friend.$2, points: friend.$3),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 22),
              Text('Support & growth', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              _ActionRow(
                icon: Icons.bookmark_outline_rounded,
                label: 'Saved deals',
                onTap: () => context.push('/account/saved'),
              ),
              const SizedBox(height: 14),
              _ActionRow(
                icon: Icons.mail_outline_rounded,
                label: 'Contact us',
                onTap: () {},
              ),
              const SizedBox(height: 14),
              _ActionRow(
                icon: Icons.ios_share_outlined,
                label: 'Share app',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EA),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: DealDropPalette.goldDeep,
                  fontSize: 32,
                ),
          ),
          const SizedBox(height: 6),
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.name,
    required this.subtitle,
    required this.points,
  });

  final String name;
  final String subtitle;
  final String points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: DealDropShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: DealDropPalette.warmSurfaceStrong,
            child: Text(name.substring(0, 1), style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
          Text(
            '$points\npoints',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DealDropPalette.goldDeep,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: DealDropPalette.warmSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: DealDropPalette.goldDeep),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleLarge)),
            const Icon(Icons.chevron_right_rounded, color: DealDropPalette.muted),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DealDropPalette.divider),
        ),
        child: Icon(icon, color: DealDropPalette.ink),
      ),
    );
  }
}
