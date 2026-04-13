import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'Taqueria del Sol was reconfirmed',
        'Confidence increased after 3 recent confirmations in West Midtown.',
        Icons.verified_rounded,
        DealDropPalette.mint,
      ),
      (
        'Bella Napoli needs recheck',
        'Conflicting reports lowered confidence on the late-night slice deal.',
        Icons.flag_outlined,
        Color(0xFFFFE5CC),
      ),
      (
        '180 pending Karma points',
        'Your recent updates are waiting on moderation review.',
        Icons.stars_outlined,
        DealDropPalette.lilac,
      ),
    ];

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
                    child: Text('Notifications', style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: DealDropShadows.card,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: item.$4,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(item.$3, color: DealDropPalette.ink),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.$1, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 6),
                                Text(item.$2, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
