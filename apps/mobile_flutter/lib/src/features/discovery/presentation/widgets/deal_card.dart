import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/app_models.dart';

class DealCard extends StatelessWidget {
  const DealCard({
    super.key,
    required this.deal,
    required this.onTap,
    required this.onSavePressed,
  });

  final Deal deal;
  final VoidCallback onTap;
  final VoidCallback onSavePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offers = deal.offers.isEmpty ? const <ListingOffer>[] : deal.offers.take(2).toList();

    return Semantics(
      button: true,
      label: '${deal.venueName}, ${deal.title}, ${deal.trustBand.label}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: DealDropShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: deal.tone.surfaceTint,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(deal.icon, color: deal.tone.accent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(deal.venueName, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            '${deal.neighborhood} • ${deal.affordabilityLabel} • ${deal.distanceMiles.toStringAsFixed(1)} mi',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            deal.title,
                            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onSavePressed,
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          deal.saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                          color: deal.saved ? DealDropPalette.goldDeep : DealDropPalette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          icon: deal.trustBand.icon,
                          label: deal.trustBand.label,
                          background: deal.trustBand.tint,
                          foreground: deal.trustBand.foreground,
                        ),
                        _MetaPill(
                          icon: Icons.schedule_rounded,
                          label: deal.scheduleLabel,
                          background: DealDropPalette.warmSurface,
                          foreground: DealDropPalette.body,
                        ),
                        _MetaPill(
                          icon: Icons.bolt_rounded,
                          label: '${(deal.confidenceScore * 100).round()}% confidence',
                          background: Colors.white,
                          foreground: DealDropPalette.goldDeep,
                          outlined: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      deal.valueNote,
                      style: theme.textTheme.bodyMedium?.copyWith(color: DealDropPalette.ink),
                    ),
                    if (offers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      for (var index = 0; index < offers.length; index++) ...[
                        _OfferRow(offer: offers[index]),
                        if (index < offers.length - 1) const Divider(height: 20),
                      ],
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deal.freshnessText,
                            style: theme.textTheme.bodySmall?.copyWith(color: DealDropPalette.body),
                          ),
                        ),
                        Text(
                          deal.lastUpdatedText,
                          style: theme.textTheme.labelLarge?.copyWith(color: DealDropPalette.goldDeep),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});

  final ListingOffer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            offer.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '\$${offer.originalPrice.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: DealDropPalette.muted,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F7EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '\$${offer.dealPrice.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(color: DealDropPalette.success),
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    this.outlined = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: DealDropPalette.divider) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
