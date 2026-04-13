import 'dart:math' as math;

import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../discovery/application/discovery_providers.dart';
import '../../discovery/domain/deal.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? selectedDealId;

  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(filteredDealsProvider);

    if (deals.isEmpty) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No map results yet for this filter. Try broadening your search from the Deals tab.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    selectedDealId ??= deals.first.id;
    final selectedDeal = deals.firstWhere(
      (deal) => deal.id == selectedDealId,
      orElse: () => deals.first,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Nearby Deals', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                _FloatingSquareButton(
                  icon: Icons.my_location_rounded,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: CustomPaint(
                        painter: _CityMapPainter(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            for (final deal in deals)
                              Positioned(
                                left: constraints.maxWidth * deal.mapDx,
                                top: constraints.maxHeight * deal.mapDy,
                                child: GestureDetector(
                                  onTap: () => setState(() => selectedDealId = deal.id),
                                  child: _DealMapPin(
                                    deal: deal,
                                    selected: selectedDealId == deal.id,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 110,
                    child: Column(
                      children: const [
                        _MapControl(icon: Icons.add_rounded),
                        SizedBox(height: 12),
                        _MapControl(icon: Icons.remove_rounded),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 18,
                    child: GestureDetector(
                      onTap: () => context.push('/listing/${selectedDeal.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: DealDropShadows.soft,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 94,
                              height: 94,
                              decoration: BoxDecoration(
                                color: selectedDeal.tone.surfaceTint,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                selectedDeal.icon,
                                size: 48,
                                color: selectedDeal.tone.accent,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: selectedDeal.trustBand.tint,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      selectedDeal.trustBand.label.toUpperCase(),
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            color: selectedDeal.trustBand.foreground,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    selectedDeal.valueHook,
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${selectedDeal.neighborhood} • ${selectedDeal.distanceMiles.toStringAsFixed(1)} mi',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [DealDropPalette.goldDeep, DealDropPalette.gold],
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                            ),
                          ],
                        ),
                      ),
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

class _DealMapPin extends StatelessWidget {
  const _DealMapPin({
    required this.deal,
    required this.selected,
  });

  final Deal deal;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? deal.tone.accent : Colors.transparent,
              width: 2,
            ),
            boxShadow: DealDropShadows.card,
          ),
          child: Column(
            children: [
              Icon(deal.icon, color: deal.tone.accent, size: 22),
              const SizedBox(height: 6),
              Text(
                deal.venueName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DealDropPalette.ink,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        Container(
          width: 3,
          height: 16,
          color: deal.tone.accent,
        ),
      ],
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: DealDropShadows.card,
      ),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Icon(icon, color: DealDropPalette.ink),
      ),
    );
  }
}

class _FloatingSquareButton extends StatelessWidget {
  const _FloatingSquareButton({
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
          boxShadow: DealDropShadows.card,
        ),
        child: Icon(icon, color: DealDropPalette.goldDeep),
      ),
    );
  }
}

class _CityMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFD0D1C6);
    canvas.drawRect(Offset.zero & size, background);

    final localRoad = Paint()
      ..color = const Color(0xFFEAE0D1)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final majorRoad = Paint()
      ..color = const Color(0xFFE7C77C)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 9; i++) {
      final dx = size.width * (0.08 + i * 0.1);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), localRoad);
    }

    for (var i = 0; i < 10; i++) {
      final dy = size.height * (0.06 + i * 0.1);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), localRoad);
    }

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.18, 0)
        ..quadraticBezierTo(
          size.width * 0.28,
          size.height * 0.38,
          size.width * 0.62,
          size.height,
        ),
      majorRoad,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.34)
        ..quadraticBezierTo(
          size.width * 0.4,
          size.height * 0.26,
          size.width,
          size.height * 0.18,
        ),
      majorRoad,
    );

    final parkPaint = Paint()..color = const Color(0xFFDDE8C6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.45, 72, 94),
        const Radius.circular(18),
      ),
      parkPaint,
    );

    final dots = Paint()..color = Colors.white.withOpacity(0.08);
    for (var i = 0; i < 90; i++) {
      final dx = (math.Random(i).nextDouble()) * size.width;
      final dy = (math.Random(i + 19).nextDouble()) * size.height;
      canvas.drawCircle(Offset(dx, dy), 1.5, dots);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
