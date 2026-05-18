import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/app_models.dart';
import '../../../core/services/app_providers.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../discovery/presentation/widgets/deal_card.dart';
import '../application/listing_image_providers.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(dealProvider(listingId));
    return Scaffold(
      body: SafeArea(
        child: dealAsync.when(
          data: (deal) => _DetailBody(deal: deal),
          error: (error, _) => Center(child: Text('$error')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.deal});

  final Deal deal;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final nearby = ref.watch(nearbyAlternativesProvider(deal));
    final imagesAsync = ref.watch(listingImagesProvider(deal.id));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              // ------------------------------------------------------------------
              // Top row: back + save
              // ------------------------------------------------------------------
              Row(
                children: [
                  _TopIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  _TopIconButton(
                    icon: deal.saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    onTap: () async {
                      try {
                        await ref
                            .read(repositoryProvider)
                            .toggleFavorite(deal.id, save: !deal.saved);
                      } finally {
                        ref.invalidate(dealProvider(deal.id));
                        ref.invalidate(savedIdsProvider);
                        ref.invalidate(savedDealsProvider);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ------------------------------------------------------------------
              // Main info card
              // ------------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DealDropPalette.divider),
                  boxShadow: DealDropShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: deal.tone.surfaceTint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(deal.icon, color: deal.tone.accent, size: 25),
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
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                deal.valueHook,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: DealDropPalette.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _Pill(
                          label: deal.trustBand.label,
                          background: deal.trustBand.tint,
                          foreground: deal.trustBand.foreground,
                          icon: deal.trustBand.icon,
                        ),
                        _Pill(
                          label: deal.scheduleLabel,
                          background: DealDropPalette.warmSurface,
                          foreground: DealDropPalette.body,
                          icon: Icons.schedule_rounded,
                        ),
                        _Pill(
                          label: '${deal.distanceMiles.toStringAsFixed(1)} mi',
                          background: Colors.white,
                          foreground: DealDropPalette.body,
                          icon: Icons.place_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroMetric(
                            label: 'Confidence',
                            value: '${(deal.confidenceScore * 100).round()}%',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HeroMetric(label: 'Updated', value: deal.lastUpdatedText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push(
                              '/contribute/confirm-active?listingId=${deal.id}',
                            ),
                            icon: const Icon(Icons.verified_rounded),
                            label: const Text('Confirm'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openDirections(context, deal),
                            icon: const Icon(Icons.directions_rounded),
                            label: const Text('Directions'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ------------------------------------------------------------------
              // Image gallery
              // ------------------------------------------------------------------
              _DetailSection(
                title: 'Photos',
                trailing: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
                        onPressed: () => _pickAndUploadImage(deal.id),
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                        label: const Text('Add photo'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                child: imagesAsync.when(
                  data: (urls) => _ImageGallery(urls: urls),
                  error: (_, _) => Text(
                    'Photos unavailable right now.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ------------------------------------------------------------------
              // Value note
              // ------------------------------------------------------------------
              Text(
                deal.valueNote,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DealDropPalette.ink,
                ),
              ),
              const SizedBox(height: 14),

              // ------------------------------------------------------------------
              // Trust & freshness
              // ------------------------------------------------------------------
              _DetailSection(
                title: 'Trust and freshness',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(deal.trustBand.icon, color: deal.trustBand.foreground),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            deal.trustSummary.explanation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Trust label', value: deal.trustBand.label),
                    _InfoRow(label: 'Freshness', value: deal.freshnessText),
                    _InfoRow(label: 'Last updated', value: deal.lastUpdatedText),
                    _InfoRow(label: 'Proof count', value: '${deal.trustSummary.proofCount} evidence items'),
                    _InfoRow(label: 'Recent confirmations', value: '${deal.trustSummary.recentConfirmations}'),
                    _InfoRow(label: 'Disputes', value: '${deal.trustSummary.disputeCount}'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ------------------------------------------------------------------
              // Offer details
              // ------------------------------------------------------------------
              _DetailSection(
                title: 'Offer details',
                child: Column(
                  children: [
                    for (var i = 0; i < deal.offers.length; i++) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              deal.offers[i].title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '\$${deal.offers[i].originalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '\$${deal.offers[i].dealPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DealDropPalette.success,
                            ),
                          ),
                        ],
                      ),
                      if (i < deal.offers.length - 1) const Divider(height: 22),
                    ],
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Restrictions', value: deal.conditions),
                    _InfoRow(label: 'Address', value: deal.venueAddress),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ------------------------------------------------------------------
              // Action buttons
              // ------------------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/contribute/report-expired?listingId=${deal.id}',
                      ),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Report issue'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/contribute/suggest-update?listingId=${deal.id}',
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Suggest update'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ------------------------------------------------------------------
              // Source note
              // ------------------------------------------------------------------
              _DetailSection(
                title: 'Source note',
                child: Text(deal.sourceNote, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 18),

              // ------------------------------------------------------------------
              // Nearby alternatives
              // ------------------------------------------------------------------
              _DetailSection(
                title: 'Nearby alternatives',
                child: nearby.when(
                  data: (items) {
                    final filtered = items.where((i) => i.id != deal.id).take(2).toList();
                    if (filtered.isEmpty) {
                      return Text(
                        'No nearby alternatives yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }
                    return Column(
                      children: filtered
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: DealCard(
                                deal: item,
                                onTap: () => context.push('/listing/${item.id}'),
                                onSavePressed: () async {
                                  await ref
                                      .read(repositoryProvider)
                                      .toggleFavorite(item.id, save: !item.saved);
                                  ref.invalidate(savedIdsProvider);
                                  ref.invalidate(savedDealsProvider);
                                },
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  error: (_, _) => Text(
                    'Nearby alternatives are unavailable right now.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadImage(String listingId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await ref.read(repositoryProvider).uploadListingImage(
        listingId: listingId,
        filePath: picked.path,
        contentType: 'image/jpeg',
      );
      ref.invalidate(listingImagesProvider(listingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openDirections(BuildContext context, Deal deal) async {
    final destination = deal.venueAddress.isNotEmpty
        ? '${deal.venueName}, ${deal.venueAddress}'
        : '${deal.latitude},${deal.longitude}';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open directions right now.')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Image gallery widget
// ---------------------------------------------------------------------------

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DealDropPalette.warmSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, color: DealDropPalette.muted, size: 28),
            const SizedBox(height: 6),
            Text(
              'No photos yet. Be the first to add one!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DealDropPalette.muted,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullImage(context, urls, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                urls[index],
                width: 140,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 140,
                  height: 140,
                  color: DealDropPalette.warmSurface,
                  child: const Icon(Icons.broken_image_outlined, color: DealDropPalette.muted),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, List<String> urls, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ImageViewerDialog(urls: urls, initialIndex: initialIndex),
    );
  }
}

class _ImageViewerDialog extends StatefulWidget {
  const _ImageViewerDialog({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.urls.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: Center(
                      child: Image.network(
                        widget.urls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 60,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DetailSection with optional trailing widget
// ---------------------------------------------------------------------------

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DealDropPalette.divider),
        boxShadow: DealDropShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable detail widgets
// ---------------------------------------------------------------------------

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DealDropPalette.warmSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: DealDropPalette.muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DealDropPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
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

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DealDropPalette.divider),
        ),
        child: Icon(icon, color: DealDropPalette.ink),
      ),
    );
  }
}
