import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/app_models.dart';
import '../../../core/services/app_providers.dart';
import '../../account/application/account_providers.dart';
import '../../karma/application/karma_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final karma = ref.watch(karmaSnapshotProvider);
    final preferences = ref.watch(preferencesProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeaderIcon(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  _HeaderIcon(
                    icon: Icons.bookmark_outline_rounded,
                    onTap: () => context.push('/account/saved'),
                  ),
                  const SizedBox(width: 10),
                  _HeaderIcon(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => context.push('/account/notifications'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              profile.when(
                data: (value) => _ProfileHero(value: value),
                error: (error, _) => Text('$error'),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 14),
              karma.when(
                data: (value) => Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: NumberFormat.decimalPattern().format(
                          value.points,
                        ),
                        label: 'Finalized points',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        value: '${value.currentStreakDays}',
                        label: 'Current streak',
                      ),
                    ),
                  ],
                ),
                error: (error, _) => Text('$error'),
                loading: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 18),
              Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              preferences.when(
                data: (value) => Column(
                  children: [
                    _PreferenceRow(
                      label: 'Contribution updates',
                      subtitle:
                          'Resolve, request-proof, and moderation notifications.',
                      value: value.contributionResolved,
                      onChanged: (next) => _updatePreferences(
                        context,
                        ref,
                        value.copyWith(contributionResolved: next),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PreferenceRow(
                      label: 'Points finalized',
                      subtitle: 'Know when pending Karma clears review.',
                      value: value.pointsFinalized,
                      onChanged: (next) => _updatePreferences(
                        context,
                        ref,
                        value.copyWith(pointsFinalized: next),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PreferenceRow(
                      label: 'Trust changes',
                      subtitle:
                          'Get nudged when a saved listing changes state.',
                      value: value.trustStatusChanged,
                      onChanged: (next) => _updatePreferences(
                        context,
                        ref,
                        value.copyWith(trustStatusChanged: next),
                      ),
                    ),
                  ],
                ),
                error: (error, _) => Text('$error'),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 18),
              Text('Account', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _ActionRow(
                icon: Icons.bookmark_outline_rounded,
                label: 'Saved deals',
                onTap: () => context.push('/account/saved'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => context.push('/account/notifications'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.emoji_events_outlined,
                label: 'Open Karma',
                onTap: () => context.go('/karma'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.logout_rounded,
                label: 'Sign out',
                destructive: true,
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/welcome');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updatePreferences(
    BuildContext context,
    WidgetRef ref,
    PreferencesModel next,
  ) async {
    try {
      await ref.read(repositoryProvider).updatePreferences(next);
      ref.invalidate(preferencesProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save preferences right now.'),
          ),
        );
      }
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.value});

  final AppProfile value;

  @override
  Widget build(BuildContext context) {
    final initials = value.displayName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part.characters.first)
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DealDropPalette.divider),
        boxShadow: DealDropShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DealDropPalette.goldSoft,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: DealDropPalette.goldDeep,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(value.email, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(label: value.homeNeighborhood),
                    _MetaChip(
                      label: value.verifiedContributor
                          ? 'Verified contributor'
                          : 'Building trust',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: DealDropPalette.warmSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: DealDropPalette.goldDeep,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DealDropPalette.divider),
        boxShadow: DealDropShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
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
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: destructive ? const Color(0xFFFBE0E5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DealDropPalette.divider),
          boxShadow: destructive ? null : DealDropShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: destructive
                    ? const Color(0xFFAF3150)
                    : DealDropPalette.goldDeep,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DealDropPalette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DealDropPalette.goldSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: DealDropPalette.goldDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DealDropPalette.divider),
        ),
        child: Icon(icon, color: DealDropPalette.ink),
      ),
    );
  }
}

extension on PreferencesModel {
  PreferencesModel copyWith({
    bool? contributionResolved,
    bool? pointsFinalized,
    bool? trustStatusChanged,
    bool? marketingAnnouncements,
  }) {
    return PreferencesModel(
      contributionResolved: contributionResolved ?? this.contributionResolved,
      pointsFinalized: pointsFinalized ?? this.pointsFinalized,
      trustStatusChanged: trustStatusChanged ?? this.trustStatusChanged,
      marketingAnnouncements:
          marketingAnnouncements ?? this.marketingAnnouncements,
    );
  }
}
