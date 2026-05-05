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
    final offers = deal.offers.isEmpty
        ? const <ListingOffer>[]
        : deal.offers.take(1).toList();

    return Semantics(
      button: true,
      label: '${deal.venueName}, ${deal.title}, ${deal.trustBand.label}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: DealDropShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: deal.tone.surfaceTint,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(deal.icon, color: deal.tone.accent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deal.venueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${deal.neighborhood} · ${deal.distanceMiles.toStringAsFixed(1)} mi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            deal.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onSavePressed,
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          deal.saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: deal.saved
                              ? DealDropPalette.goldDeep
                              : DealDropPalette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _MetaPill(
                            icon: deal.trustBand.icon,
                            label: deal.trustBand.shortLabel,
                            background: deal.trustBand.tint,
                            foreground: deal.trustBand.foreground,
                          ),
                          const SizedBox(width: 7),
                          _MetaPill(
                            icon: Icons.schedule_rounded,
                            label: _compactSchedule(deal.scheduleLabel),
                            background: DealDropPalette.warmSurface,
                            foreground: DealDropPalette.body,
                          ),
                          const SizedBox(width: 7),
                          _MetaPill(
                            icon: Icons.bolt_rounded,
                            label: '${(deal.confidenceScore * 100).round()}%',
                            background: Colors.white,
                            foreground: DealDropPalette.goldDeep,
                            outlined: true,
                          ),
                        ],
                      ),
                    ),
                    if (deal.valueNote.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: DealDropPalette.cream,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          deal.valueNote,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: DealDropPalette.ink,
                          ),
                        ),
                      ),
                    ],
                    if (offers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      for (var index = 0; index < offers.length; index++) ...[
                        _OfferRow(offer: offers[index]),
                        if (index < offers.length - 1)
                          const Divider(height: 20),
                      ],
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deal.freshnessText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: DealDropPalette.body,
                            ),
                          ),
                        ),
                        Text(
                          deal.affordabilityLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: DealDropPalette.goldDeep,
                          ),
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

String _compactSchedule(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('live')) {
    return 'Live now';
  }
  if (lower.contains('tonight')) {
    return 'Tonight';
  }
  if (value.length > 18) {
    return '${value.substring(0, 17)}...';
  }
  return value;
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
            style: theme.textTheme.titleMedium?.copyWith(
              color: DealDropPalette.success,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: DealDropPalette.divider) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
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
