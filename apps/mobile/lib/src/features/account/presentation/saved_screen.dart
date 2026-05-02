import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../discovery/application/discovery_providers.dart';
import '../../discovery/presentation/widgets/deal_card.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedDealsAsync = ref.watch(savedDealsProvider);
    final savedDeals = savedDealsAsync.valueOrNull ?? [];
    final savedIds = ref.watch(favoritesControllerProvider).valueOrNull ?? {};

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
                    child: Text('Saved deals', style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (savedDealsAsync.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (savedDeals.isEmpty)
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: DealDropShadows.card,
                      ),
                      child: Text(
                        'Save deals from the feed or map to revisit them here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: savedDeals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      final deal = savedDeals[index];
                      return DealCard(
                        deal: deal,
                        isSaved: savedIds.contains(deal.id),
                        onTap: () => context.push('/listing/${deal.id}'),
                        onSavePressed: () =>
                            ref.read(favoritesControllerProvider.notifier).toggle(deal.id),
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
