import 'dart:async';
import 'dart:math' as math;

import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/app_models.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/services/google_maps_loader.dart';
import '../../discovery/application/discovery_providers.dart';
import '../application/map_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _atlanta = CameraPosition(
    target: LatLng(33.7806, -84.3870),
    zoom: 12.9,
  );

  GoogleMapController? _controller;
  CameraPosition _currentCamera = _atlanta;
  String? _selectedListingId;
  bool _locationDenied = false;
  bool _locating = false;
  Timer? _boundsDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshBounds(_atlanta));
  }

  @override
  void dispose() {
    _boundsDebounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final mapListings = ref.watch(mapListingsProvider);
    final selectedDealAsync = _selectedListingId == null
        ? null
        : ref.watch(dealProvider(_selectedListingId!));
    final canRenderInteractiveMap =
        (!kIsWeb || googleMapsRuntimeAvailable) &&
        config.googleMapsKeyConfigured;

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(34),
              ),
              child: canRenderInteractiveMap
                  ? GoogleMap(
                      initialCameraPosition: _atlanta,
                      myLocationEnabled: !_locationDenied,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) {
                        _controller = controller;
                        Future<void>.delayed(
                          const Duration(milliseconds: 250),
                          () {
                            if (mounted) {
                              _refreshBounds(_currentCamera);
                            }
                          },
                        );
                      },
                      onCameraMove: (cameraPosition) {
                        _currentCamera = cameraPosition;
                      },
                      onCameraIdle: () {
                        _refreshBounds(_currentCamera);
                      },
                      markers: mapListings.when(
                        data: (items) => _buildMarkers(items),
                        error: (_, _) => const <Marker>{},
                        loading: () => const <Marker>{},
                      ),
                    )
                  : const _MapUnavailableSurface(),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: DealDropShadows.card,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Map',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            _MapStatusChip(
                              label: _locationDenied
                                  ? 'Atlanta default'
                                  : 'Move to refresh',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/search'),
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ],
                  ),
                ),
                if (!config.googleMapsKeyConfigured) ...[
                  const SizedBox(height: 12),
                  const _InlineBanner(
                    icon: Icons.key_outlined,
                    title: 'Google Maps key required',
                    body:
                        'Add GOOGLE_MAPS_API_KEY for full map rendering in this build.',
                  ),
                ],
                if (_locationDenied) ...[
                  const SizedBox(height: 12),
                  _InlineBanner(
                    icon: Icons.location_off_rounded,
                    title: 'Location permission is off',
                    body:
                        'You can still browse the citywide map or tap recenter to try again.',
                    actionLabel: 'Retry',
                    onTap: _centerOnUser,
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: selectedDealAsync == null ? 32 : 220,
            child: Column(
              children: [
                _MapControl(
                  icon: Icons.my_location_rounded,
                  onTap: canRenderInteractiveMap && !_locating
                      ? _centerOnUser
                      : null,
                ),
                if (canRenderInteractiveMap) ...[
                  const SizedBox(height: 12),
                  _MapControl(
                    icon: Icons.add_rounded,
                    onTap: () =>
                        _controller?.animateCamera(CameraUpdate.zoomIn()),
                  ),
                  const SizedBox(height: 12),
                  _MapControl(
                    icon: Icons.remove_rounded,
                    onTap: () =>
                        _controller?.animateCamera(CameraUpdate.zoomOut()),
                  ),
                ],
              ],
            ),
          ),
          if (mapListings.isLoading)
            const Positioned(
              left: 20,
              right: 20,
              bottom: 130,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (selectedDealAsync != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 20,
              child: selectedDealAsync.when(
                data: (deal) => GestureDetector(
                  onTap: () => context.push('/listing/${deal.id}'),
                  child: _MapPreviewCard(deal: deal),
                ),
                error: (_, _) => const SizedBox.shrink(),
                loading: () => const _MapPreviewLoading(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _centerOnUser() async {
    setState(() {
      _locating = true;
    });
    try {
      final permission = await Geolocator.checkPermission();
      final resolved = permission == LocationPermission.denied
          ? await Geolocator.requestPermission()
          : permission;
      if (resolved == LocationPermission.denied ||
          resolved == LocationPermission.deniedForever) {
        setState(() {
          _locationDenied = true;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final target = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14.5,
      );
      await _controller?.animateCamera(CameraUpdate.newCameraPosition(target));
      setState(() {
        _locationDenied = false;
        _currentCamera = target;
      });
      await _refreshBounds(target);
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  Future<void> _refreshBounds(CameraPosition cameraPosition) async {
    _boundsDebounce?.cancel();
    _boundsDebounce = Timer(const Duration(milliseconds: 220), () async {
      final controller = _controller;
      if (controller == null) {
        return;
      }
      final region = await controller.getVisibleRegion();
      ref.read(mapBoundsProvider.notifier).state = (
        north: region.northeast.latitude,
        south: region.southwest.latitude,
        east: region.northeast.longitude,
        west: region.southwest.longitude,
        zoom: cameraPosition.zoom,
        trustBand: null,
      );
    });
  }

  Set<Marker> _buildMarkers(List<MapDeal> deals) {
    final clusters = _clusterDeals(deals, _currentCamera.zoom);
    return clusters.map((cluster) {
      final markerHue = switch (cluster.primary.trustBand) {
        TrustBand.founderVerified => BitmapDescriptor.hueYellow,
        TrustBand.merchantConfirmed => BitmapDescriptor.hueGreen,
        TrustBand.userConfirmed => BitmapDescriptor.hueAzure,
        TrustBand.recentlyUpdated => BitmapDescriptor.hueBlue,
        TrustBand.needsRecheck => BitmapDescriptor.hueOrange,
        TrustBand.disputed => BitmapDescriptor.hueRose,
      };

      return Marker(
        markerId: MarkerId(cluster.id),
        position: LatLng(cluster.latitude, cluster.longitude),
        infoWindow: InfoWindow(
          title: cluster.count > 1
              ? '${cluster.count} listings here'
              : cluster.primary.venueName,
          snippet: cluster.count > 1
              ? 'Zoom in for individual deals'
              : cluster.primary.title,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
        onTap: () {
          setState(() {
            _selectedListingId = cluster.primary.listingId;
          });
          if (cluster.count > 1) {
            _controller?.animateCamera(
              CameraUpdate.zoomTo(math.min(_currentCamera.zoom + 1.2, 16)),
            );
          }
        },
      );
    }).toSet();
  }

  List<_ClusterPin> _clusterDeals(List<MapDeal> deals, double zoom) {
    final bucketSize = zoom >= 15
        ? 0.002
        : zoom >= 14
        ? 0.004
        : zoom >= 13
        ? 0.007
        : 0.012;

    final clusters = <String, List<MapDeal>>{};
    for (final deal in deals) {
      final latKey = (deal.latitude / bucketSize).round();
      final lngKey = (deal.longitude / bucketSize).round();
      final key = '$latKey:$lngKey';
      clusters.putIfAbsent(key, () => <MapDeal>[]).add(deal);
    }

    return clusters.entries.map((entry) {
      final items = entry.value;
      final latitude =
          items
              .map((item) => item.latitude)
              .reduce((left, right) => left + right) /
          items.length;
      final longitude =
          items
              .map((item) => item.longitude)
              .reduce((left, right) => left + right) /
          items.length;
      final sorted = [...items]
        ..sort(
          (left, right) =>
              right.confidenceScore.compareTo(left.confidenceScore),
        );
      return _ClusterPin(
        id: entry.key,
        latitude: latitude,
        longitude: longitude,
        count: items.length,
        primary: sorted.first,
      );
    }).toList();
  }
}

class _MapUnavailableSurface extends StatelessWidget {
  const _MapUnavailableSurface();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF6F1), Color(0xFFFFF3E4), Color(0xFFEDEBFF)],
        ),
      ),
      child: Center(
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            boxShadow: DealDropShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: DealDropPalette.mint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: DealDropPalette.mintDeep,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Map key needed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Deals still work.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapStatusChip extends StatelessWidget {
  const _MapStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: DealDropPalette.warmSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ClusterPin {
  const _ClusterPin({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.primary,
  });

  final String id;
  final double latitude;
  final double longitude;
  final int count;
  final MapDeal primary;
}

class _MapControl extends StatelessWidget {
  const _MapControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: DealDropShadows.card,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: DealDropPalette.ink),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: DealDropShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: deal.tone.surfaceTint,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(deal.icon, size: 44, color: deal.tone.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: deal.trustBand.tint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    deal.trustBand.shortLabel.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: deal.trustBand.foreground,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  deal.venueName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  deal.valueHook,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${deal.neighborhood} • ${deal.affordabilityLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreviewLoading extends StatelessWidget {
  const _MapPreviewLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: DealDropShadows.card,
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: DealDropShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DealDropPalette.goldSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: DealDropPalette.goldDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onTap, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
