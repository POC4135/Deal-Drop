import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../discovery/application/discovery_providers.dart';
import '../../discovery/domain/deal.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _selectedDealId;
  late final MapController _mapController;

  static const _defaultCenter = LatLng(33.7848, -84.3879); // Midtown Atlanta
  static const _initialZoom = 14.5;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _centroid(List<Deal> deals) {
    final located = deals.where((d) => d.lat != null && d.lng != null).toList();
    if (located.isEmpty) return _defaultCenter;
    final avgLat =
        located.map((d) => d.lat!).reduce((a, b) => a + b) / located.length;
    final avgLng =
        located.map((d) => d.lng!).reduce((a, b) => a + b) / located.length;
    return LatLng(avgLat, avgLng);
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(filteredDealsProvider);
    final deals = dealsAsync.valueOrNull ?? [];

    if (dealsAsync.isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

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

    _selectedDealId ??= deals.first.id;
    final selectedDeal = deals.firstWhere(
      (d) => d.id == _selectedDealId,
      orElse: () => deals.first,
    );
    final center = _centroid(deals);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Nearby Deals',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                _FloatingSquareButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _mapController.move(center, _initialZoom),
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
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: _initialZoom,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.dealdropapp',
                          ),
                          MarkerLayer(
                            markers: [
                              for (final deal in deals)
                                if (deal.lat != null && deal.lng != null)
                                  Marker(
                                    point: LatLng(deal.lat!, deal.lng!),
                                    width: 120,
                                    height: 96,
                                    alignment: Alignment.bottomCenter,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedDealId = deal.id),
                                      child: _DealMapPin(
                                        deal: deal,
                                        selected: _selectedDealId == deal.id,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 18,
                    child: Column(
                      children: [
                        _MapControl(
                          icon: Icons.add_rounded,
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _MapControl(
                          icon: Icons.remove_rounded,
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 18,
                    child: GestureDetector(
                      onTap: () =>
                          context.push('/listing/${selectedDeal.id}'),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: selectedDeal.trustBand.tint,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      selectedDeal.trustBand.label
                                          .toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: selectedDeal
                                                .trustBand.foreground,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    selectedDeal.valueHook,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${selectedDeal.neighborhood} • ${selectedDeal.distanceMiles.toStringAsFixed(1)} mi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    DealDropPalette.goldDeep,
                                    DealDropPalette.gold,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: Colors.white, size: 32),
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
  const _DealMapPin({required this.deal, required this.selected});

  final Deal deal;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? deal.tone.accent : Colors.transparent,
              width: 2,
            ),
            boxShadow: DealDropShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(deal.icon, color: deal.tone.accent, size: 20),
              const SizedBox(height: 4),
              Text(
                deal.venueName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DealDropPalette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          width: 3,
          height: 12,
          color: deal.tone.accent,
        ),
      ],
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: DealDropShadows.card,
        ),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            icon,
            color: onTap != null ? DealDropPalette.ink : DealDropPalette.muted,
          ),
        ),
      ),
    );
  }
}

class _FloatingSquareButton extends StatelessWidget {
  const _FloatingSquareButton({required this.icon, required this.onTap});

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
