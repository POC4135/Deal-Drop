import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';

class DealDropBottomNav extends StatelessWidget {
  const DealDropBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(label: 'Deals', icon: Icons.local_offer_outlined),
      _NavItem(label: 'Map', icon: Icons.map_outlined),
      _NavItem(label: 'Post', icon: Icons.add_circle_outline),
      _NavItem(label: 'Karma', icon: Icons.stars_outlined),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DealDropPalette.divider),
          boxShadow: DealDropShadows.soft,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onTap(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: index == currentIndex
                                  ? DealDropPalette.goldSoft
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              items[index].icon,
                              color: index == currentIndex
                                  ? DealDropPalette.goldDeep
                                  : DealDropPalette.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[index].label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: index == currentIndex
                                      ? DealDropPalette.goldDeep
                                      : DealDropPalette.muted,
                                  fontWeight: index == currentIndex
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
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

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
