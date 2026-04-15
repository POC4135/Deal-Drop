import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/app_providers.dart';
import '../application/account_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DealDropPalette.divider),
                      ),
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Activity for trust changes, moderation outcomes, and finalized points.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: notifications.when(
                  data: (payload) {
                    if (payload.items.isEmpty) {
                      return Center(
                        child: Text(
                          'No notifications yet.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: payload.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = payload.items[index];
                        return InkWell(
                          onTap: () async {
                            try {
                              await ref
                                  .read(repositoryProvider)
                                  .markNotificationRead(item.id);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Unable to update read state right now.',
                                    ),
                                  ),
                                );
                              }
                            }
                            ref.invalidate(notificationsProvider);
                            if (item.deepLink != null && context.mounted) {
                              context.push(item.deepLink!);
                            }
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: item.isUnread
                                  ? DealDropPalette.warmSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: DealDropShadows.card,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: _iconTint(item.kind),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    _iconFor(item.kind),
                                    color: DealDropPalette.ink,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.body,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormat.MMMd().add_jm().format(
                                          item.createdAt.toLocal(),
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.isUnread)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: DealDropPalette.goldDeep,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  error: (error, _) => Center(child: Text('$error')),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String kind) {
    return switch (kind) {
      'points_finalized' => Icons.stars_rounded,
      'trust_status_changed' => Icons.verified_rounded,
      'listing_reported_stale' => Icons.flag_outlined,
      'moderation_update' => Icons.gavel_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _iconTint(String kind) {
    return switch (kind) {
      'points_finalized' => DealDropPalette.lilac,
      'trust_status_changed' => DealDropPalette.mint,
      'listing_reported_stale' => const Color(0xFFFFE5CC),
      'moderation_update' => DealDropPalette.sky,
      _ => DealDropPalette.goldSoft,
    };
  }
}
