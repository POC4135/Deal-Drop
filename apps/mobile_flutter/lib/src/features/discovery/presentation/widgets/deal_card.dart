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
    final primaryOffer = deal.offers.isEmpty ? null : deal.offers.first;

    return Semantics(
      button: true,
      label: '${deal.venueName}, ${deal.title}, ${deal.trustBand.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DealDropPalette.divider),
            boxShadow: DealDropShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: deal.tone.surfaceTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(deal.icon, color: deal.tone.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deal.venueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deal.affordabilityLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: DealDropPalette.goldDeep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      deal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DealDropPalette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaPill(
                          icon: deal.trustBand.icon,
                          label: deal.trustBand.shortLabel,
                          background: deal.trustBand.tint,
                          foreground: deal.trustBand.foreground,
                        ),
                        _MetaPill(
                          icon: Icons.schedule_rounded,
                          label: _compactSchedule(deal.scheduleLabel),
                          background: DealDropPalette.warmSurface,
                          foreground: DealDropPalette.body,
                        ),
                        _MetaPill(
                          icon: Icons.place_outlined,
                          label: '${deal.distanceMiles.toStringAsFixed(1)} mi',
                          background: Colors.white,
                          foreground: DealDropPalette.body,
                          outlined: true,
                        ),
                      ],
                    ),
                    if (primaryOffer != null) ...[
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              primaryOffer.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: DealDropPalette.body,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PriceInline(offer: primaryOffer),
                        ],
                      ),
                    ] else if (deal.valueNote.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        deal.valueNote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      deal.freshnessText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onSavePressed,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: deal.saved
                        ? DealDropPalette.goldSoft
                        : DealDropPalette.cream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DealDropPalette.divider),
                  ),
                  child: Icon(
                    deal.saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 21,
                    color: deal.saved
                        ? DealDropPalette.goldDeep
                        : DealDropPalette.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceInline extends StatelessWidget {
  const _PriceInline({required this.offer});

  final ListingOffer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '\$${offer.originalPrice.toStringAsFixed(0)}',
          style: theme.textTheme.bodySmall?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: DealDropPalette.muted,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F7EF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '\$${offer.dealPrice.toStringAsFixed(0)}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: DealDropPalette.success,
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: DealDropPalette.divider) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
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

String _compactSchedule(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('live')) {
    return 'Live';
  }
  if (lower.contains('tonight')) {
    return 'Tonight';
  }
  if (value.length > 15) {
    return '${value.substring(0, 14)}...';
  }
  return value;
}
