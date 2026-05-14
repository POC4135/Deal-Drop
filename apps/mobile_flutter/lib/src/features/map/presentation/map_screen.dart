import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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

// ---------------------------------------------------------------------------
// Minimal, Uber-style Google Maps JSON style.
// Hides all POIs, transit, and business labels — shows only streets + water.
// ---------------------------------------------------------------------------
const _kMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f0f0f0"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f5f5"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.neighborhood","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e8e8e8"}]},
  {"featureType":"road","elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"road.arterial","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#e8e8e8"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#d6d6d6"}]},
  {"featureType":"road.highway","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road.local","stylers":[{"visibility":"simplified"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9e8f5"}]},
  {"featureType":"water","elementType":"labels.text","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f0f0f0"}]},
  {"featureType":"landscape.man_made","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#e8f5e9"}]}
]
''';

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

  // Cache of rendered BitmapDescriptors per trust band
  final _markerIconCache = <TrustBand, BitmapDescriptor>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _refreshBounds(_atlanta);
      _tryInitialLocation();
      _preloadMarkerIcons();
    });
  }

  @override
  void dispose() {
    _boundsDebounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _tryInitialLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      ref.read(userPositionProvider.notifier).state = UserPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final target = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14.5,
      );
      await _controller?.animateCamera(CameraUpdate.newCameraPosition(target));
      if (mounted) setState(() => _currentCamera = target);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final mapListings = ref.watch(mapListingsProvider);
    final categoryFilter = ref.watch(mapCategoryFilterProvider);
    final distanceFilter = ref.watch(mapDistanceFilterProvider);
    final selectedDealAsync = _selectedListingId == null
        ? null
        : ref.watch(dealProvider(_selectedListingId!));
    final canRenderInteractiveMap =
        (!kIsWeb || googleMapsRuntimeAvailable) &&
        config.googleMapsKeyConfigured;

    return SafeArea(
      child: Stack(
        children: [
          // ----------------------------------------------------------------
          // Map layer
          // ----------------------------------------------------------------
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
              child: canRenderInteractiveMap
                  ? GoogleMap(
                      initialCameraPosition: _atlanta,
                      cloudMapId: config.googleMapsMapId.isNotEmpty
                          ? config.googleMapsMapId
                          : null,
                      myLocationEnabled: !_locationDenied,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      buildingsEnabled: false,
                      indoorViewEnabled: false,
                      trafficEnabled: false,
                      onMapCreated: (controller) async {
                        _controller = controller;
                        if (!kIsWeb) await controller.setMapStyle(_kMapStyle);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 250),
                        );
                        if (mounted) _refreshBounds(_currentCamera);
                      },
                      onCameraMove: (pos) => _currentCamera = pos,
                      onCameraIdle: () => _refreshBounds(_currentCamera),
                      onTap: (_) => setState(() => _selectedListingId = null),
                      markers: mapListings.when(
                        data: (items) => _buildMarkers(items),
                        error: (_, _) => const <Marker>{},
                        loading: () => const <Marker>{},
                      ),
                    )
                  : const _MapUnavailableSurface(),
            ),
          ),

          // ----------------------------------------------------------------
          // Header bar + filter chips
          // ----------------------------------------------------------------
          Positioned(
            left: 16,
            right: 16,
            top: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 8),
                  const _InlineBanner(
                    icon: Icons.key_outlined,
                    title: 'Google Maps key required',
                    body: 'Add GOOGLE_MAPS_API_KEY for full map rendering.',
                  ),
                ],
                if (_locationDenied) ...[
                  const SizedBox(height: 8),
                  _InlineBanner(
                    icon: Icons.location_off_rounded,
                    title: 'Location permission is off',
                    body: 'Browse the citywide map or tap recenter to retry.',
                    actionLabel: 'Retry',
                    onTap: _centerOnUser,
                  ),
                ],
                const SizedBox(height: 8),
                // Category filter chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final f in MapCategoryFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: f.label,
                            icon: switch (f) {
                              MapCategoryFilter.all => Icons.apps_rounded,
                              MapCategoryFilter.food => Icons.restaurant_rounded,
                              MapCategoryFilter.drink => Icons.local_bar_rounded,
                            },
                            selected: categoryFilter == f,
                            onTap: () => ref
                                .read(mapCategoryFilterProvider.notifier)
                                .state = f,
                          ),
                        ),
                      const SizedBox(width: 4),
                      // Distance filter chips
                      for (final d in MapDistanceFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: d.label,
                            icon: d == MapDistanceFilter.any
                                ? Icons.location_searching_rounded
                                : Icons.social_distance_rounded,
                            selected: distanceFilter == d,
                            onTap: () {
                              ref
                                  .read(mapDistanceFilterProvider.notifier)
                                  .state = d;
                              if (d != MapDistanceFilter.any &&
                                  ref.read(userPositionProvider) == null) {
                                _centerOnUser();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------------------------------------------
          // Map controls (zoom + locate)
          // ----------------------------------------------------------------
          Positioned(
            right: 16,
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

          // ----------------------------------------------------------------
          // Loading indicator
          // ----------------------------------------------------------------
          if (mapListings.isLoading)
            const Positioned(
              left: 20,
              right: 20,
              bottom: 130,
              child: Center(child: CircularProgressIndicator()),
            ),

          // ----------------------------------------------------------------
          // Selected deal preview card
          // ----------------------------------------------------------------
          if (selectedDealAsync != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
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

  // -------------------------------------------------------------------------
  // Location helpers
  // -------------------------------------------------------------------------

  Future<void> _centerOnUser() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      final resolved = permission == LocationPermission.denied
          ? await Geolocator.requestPermission()
          : permission;
      if (resolved == LocationPermission.denied ||
          resolved == LocationPermission.deniedForever) {
        setState(() => _locationDenied = true);
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      ref.read(userPositionProvider.notifier).state = UserPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final target = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14.5,
      );
      await _controller?.animateCamera(CameraUpdate.newCameraPosition(target));
      if (mounted) {
        setState(() {
          _locationDenied = false;
          _currentCamera = target;
        });
      }
      _refreshBounds(target);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _refreshBounds(CameraPosition cameraPosition) async {
    _boundsDebounce?.cancel();
    _boundsDebounce = Timer(const Duration(milliseconds: 220), () async {
      final controller = _controller;
      if (controller == null) return;
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

  // -------------------------------------------------------------------------
  // Custom marker rendering
  // -------------------------------------------------------------------------

  Set<Marker> _buildMarkers(List<MapDeal> deals) {
    final clusters = _clusterDeals(deals, _currentCamera.zoom);
    return clusters.map((cluster) {
      return Marker(
        markerId: MarkerId(cluster.id),
        position: LatLng(cluster.latitude, cluster.longitude),
        icon: _markerIconCache[cluster.primary.trustBand] ??
            BitmapDescriptor.defaultMarkerWithHue(
              _trustBandHue(cluster.primary.trustBand),
            ),
        anchor: const Offset(0.5, 1.0),
        onTap: () {
          setState(() => _selectedListingId = cluster.primary.listingId);
          if (cluster.count > 1) {
            _controller?.animateCamera(
              CameraUpdate.zoomTo(
                math.min(_currentCamera.zoom + 1.2, 16),
              ),
            );
          }
        },
      );
    }).toSet();
  }

  double _trustBandHue(TrustBand band) => switch (band) {
    TrustBand.founderVerified => BitmapDescriptor.hueYellow,
    TrustBand.merchantConfirmed => BitmapDescriptor.hueGreen,
    TrustBand.userConfirmed => BitmapDescriptor.hueAzure,
    TrustBand.recentlyUpdated => BitmapDescriptor.hueBlue,
    TrustBand.needsRecheck => BitmapDescriptor.hueOrange,
    TrustBand.disputed => BitmapDescriptor.hueRose,
  };

  Future<void> _preloadMarkerIcons() async {
    for (final band in TrustBand.values) {
      if (_markerIconCache.containsKey(band)) continue;
      try {
        final icon = kIsWeb
            ? await _buildWebMarker(band)
            : await _buildCustomMarker(band);
        _markerIconCache[band] = icon;
      } catch (_) {
        // fallback handled in _buildMarkers via ?? operator
      }
    }
    if (mounted) setState(() {});
  }

  // Web-compatible marker using SVG encoded as PNG bytes via dart:ui
  Future<BitmapDescriptor> _buildWebMarker(TrustBand band) async {
    final color = _bandColor(band);
    final hex = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    final isStar = band == TrustBand.founderVerified;
    final starPath = isStar
        ? '<polygon points="20,6 23.5,15 33,15 25.5,21 28,30 20,24.5 12,30 14.5,21 7,15 16.5,15" fill="white"/>'
        : '<circle cx="20" cy="18" r="5" fill="white"/>';
    final svg = '''<svg xmlns="http://www.w3.org/2000/svg" width="40" height="52">
  <filter id="s"><feDropShadow dx="0" dy="2" stdDeviation="2" flood-opacity="0.3"/></filter>
  <g filter="url(#s)">
    <rect x="2" y="2" width="36" height="34" rx="12" ry="12" fill="#$hex"/>
    <polygon points="20,46 12,36 28,36" fill="#$hex"/>
    <rect x="2" y="2" width="36" height="34" rx="12" ry="12" fill="none" stroke="white" stroke-width="2"/>
  </g>
  $starPath
</svg>''';

    final bytes = svg.codeUnits;
    // Encode SVG as PNG via canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 40, 52));
    void unused(dynamic _) {}
    unused(bytes);
    // Draw the pin shape directly since SVG decode isn't available in dart:ui
    final bodyPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawRRect(RRect.fromLTRBR(2, 4, 38, 38, const Radius.circular(12)), shadowPaint);
    canvas.drawRRect(RRect.fromLTRBR(2, 2, 38, 36, const Radius.circular(12)), bodyPaint);
    canvas.drawRRect(RRect.fromLTRBR(2, 2, 38, 36, const Radius.circular(12)), borderPaint);

    final tipPath = Path()
      ..moveTo(12, 36)
      ..lineTo(28, 36)
      ..lineTo(20, 48)
      ..close();
    canvas.drawPath(tipPath, bodyPaint);
    final tipBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(tipPath, tipBorder);

    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    _drawPinIcon(canvas, const Offset(20, 19), 16, iconPaint, band);

    final picture = recorder.endRecording();
    final image = await picture.toImage(40, 52);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw Exception('toByteData returned null');
    return BitmapDescriptor.bytes(data.buffer.asUint8List(), imagePixelRatio: 1.0);
  }

  Future<BitmapDescriptor> _buildCustomMarker(TrustBand band) async {
    const size = 80.0;
    const pinW = 40.0;
    const pinH = 52.0;
    const radius = 14.0;
    const tipH = 12.0;
    const iconSize = 20.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(size / 2, pinH + 4),
        width: pinW * 0.7,
        height: 8,
      ),
      shadowPaint,
    );

    final color = _bandColor(band);
    final bodyPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final left = (size - pinW) / 2;
    final top = (size - pinH) / 2 - 4;
    final bodyRect = RRect.fromLTRBR(left, top, left + pinW, top + pinH - tipH, const Radius.circular(radius));

    final shadowPinPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(bodyRect, shadowPinPaint);
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, borderPaint);

    final tipPath = Path()
      ..moveTo(left + pinW / 2 - 8, top + pinH - tipH)
      ..lineTo(left + pinW / 2 + 8, top + pinH - tipH)
      ..lineTo(left + pinW / 2, top + pinH)
      ..close();
    canvas.drawPath(tipPath, bodyPaint);
    final tipBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(tipPath, tipBorderPaint);

    final iconCenter = Offset(size / 2, top + (pinH - tipH) / 2);
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    _drawPinIcon(canvas, iconCenter, iconSize, iconPaint, band);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw Exception('toByteData returned null');
    return BitmapDescriptor.bytes(data.buffer.asUint8List(), imagePixelRatio: 2.0);
  }

  void _drawPinIcon(Canvas canvas, Offset center, double size, Paint paint, TrustBand band) {
    // Simple geometric icons
    if (band == TrustBand.founderVerified) {
      // Star shape
      _drawStar(canvas, center, size / 2, paint);
    } else {
      // Location dot
      canvas.drawCircle(center, size / 4, paint);
      canvas.drawCircle(
        center,
        size / 4,
        Paint()
          ..color = _bandColor(band)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final outerR = radius;
    final innerR = radius * 0.4;
    for (var i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = outerAngle + 36 * math.pi / 180;
      final outerPoint = Offset(
        center.dx + outerR * math.cos(outerAngle),
        center.dy + outerR * math.sin(outerAngle),
      );
      final innerPoint = Offset(
        center.dx + innerR * math.cos(innerAngle),
        center.dy + innerR * math.sin(innerAngle),
      );
      if (i == 0) path.moveTo(outerPoint.dx, outerPoint.dy);
      else path.lineTo(outerPoint.dx, outerPoint.dy);
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  Color _bandColor(TrustBand band) => switch (band) {
    TrustBand.founderVerified => const Color(0xFFD4A017),
    TrustBand.merchantConfirmed => const Color(0xFF00C07F),
    TrustBand.userConfirmed => const Color(0xFF2D7EEA),
    TrustBand.recentlyUpdated => const Color(0xFF6B7FD7),
    TrustBand.needsRecheck => const Color(0xFFE88B2F),
    TrustBand.disputed => const Color(0xFFD0354B),
  };

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
      final latitude = items.map((i) => i.latitude).reduce((a, b) => a + b) / items.length;
      final longitude = items.map((i) => i.longitude).reduce((a, b) => a + b) / items.length;
      final sorted = [...items]
        ..sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
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

// ---------------------------------------------------------------------------
// Supporting widget: filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? DealDropPalette.mintDeep : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: DealDropShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : DealDropPalette.ink,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : DealDropPalette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets (mostly unchanged from original)
// ---------------------------------------------------------------------------

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: DealDropShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DealDropPalette.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.map_outlined, color: DealDropPalette.mintDeep),
              ),
              const SizedBox(height: 12),
              Text('Map key needed', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Text('Deals still work.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
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
        borderRadius: BorderRadius.circular(14),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DealDropShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: deal.tone.surfaceTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(deal.icon, size: 30, color: deal.tone.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                const SizedBox(height: 5),
                Text(
                  deal.venueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  deal.valueHook,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${deal.neighborhood} · ${deal.affordabilityLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: DealDropPalette.muted),
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
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
