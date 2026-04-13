import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';

import '../../domain/deal.dart';

class DealCard extends StatelessWidget {
  const DealCard({
    super.key,
    required this.deal,
    required this.isSaved,
    required this.onTap,
    required this.onSavePressed,
  });

  final Deal deal;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSavePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleOffers = deal.offers.length > 2 ? deal.offers.take(2).toList() : deal.offers;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: DealDropShadows.card,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: deal.tone.surfaceTint,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
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
                          '${deal.cuisine} • ${deal.distanceMiles.toStringAsFixed(1)} mi • ★ ${deal.rating.toStringAsFixed(1)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetaPill(
                              label: deal.trustBand.label,
                              background: deal.trustBand.tint,
                              foreground: deal.trustBand.foreground,
                            ),
                            _MetaPill(
                              label: deal.freshnessText,
                              background: Colors.white.withOpacity(0.78),
                              foreground: DealDropPalette.body,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      _ActionIconButton(
                        icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                        onPressed: onSavePressed,
                      ),
                      const SizedBox(height: 10),
                      const _ActionIconButton(
                        icon: Icons.more_horiz,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                children: [
                  for (var index = 0; index < visibleOffers.length; index++) ...[
                    _OfferRow(offer: visibleOffers[index]),
                    if (index < visibleOffers.length - 1)
                      const Divider(height: 22),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    deal.offers.length > 2
                        ? '+${deal.offers.length - 2} more deals'
                        : deal.scheduleLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: DealDropPalette.goldDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});

  final DealOffer offer;

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
        const SizedBox(width: 12),
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
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: DealDropPalette.ink),
      ),
    );
  }
}
