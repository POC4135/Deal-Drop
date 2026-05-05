import 'dart:async';

import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/app_models.dart';
import '../../../core/models/google_place_models.dart';
import '../../../core/services/app_providers.dart';
import '../../../core/services/dealdrop_repository.dart';
import '../../../core/services/google_places_service.dart';
import '../../karma/application/karma_providers.dart';
import '../application/post_providers.dart';

class ContributionFormScreen extends ConsumerStatefulWidget {
  const ContributionFormScreen({
    super.key,
    required this.actionSlug,
    this.listingId,
  });

  final String actionSlug;
  final String? listingId;

  @override
  ConsumerState<ContributionFormScreen> createState() =>
      _ContributionFormScreenState();
}

class _ContributionFormScreenState
    extends ConsumerState<ContributionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _venueController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _neighborhoodController = TextEditingController(text: 'Midtown');
  final _reasonController = TextEditingController(text: 'expired');
  final _proofNoteController = TextEditingController();
  final _searchController = TextEditingController();

  Timer? _debounce;
  bool _submitting = false;
  bool _searching = false;
  bool _venueSearching = false;
  String? _error;
  String? _proofAssetKey;
  Deal? _selectedListing;
  GooglePlaceDetails? _selectedGooglePlace;
  List<GooglePlacePrediction> _venuePredictions = const [];
  List<Deal> _searchResults = const [];
  late final GooglePlacesService _googlePlacesService;

  @override
  void initState() {
    super.initState();
    _googlePlacesService = GooglePlacesService(
      config: ref.read(appConfigProvider),
    );
    final action = _config;
    if (widget.listingId != null) {
      Future.microtask(() async {
        try {
          final listing = await ref
              .read(repositoryProvider)
              .fetchListingDetail(widget.listingId!);
          if (!mounted) {
            return;
          }
          setState(() {
            _selectedListing = listing;
            _searchController.text = listing.venueName;
          });
        } catch (_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _error = 'Unable to load the selected listing right now.';
          });
        }
      });
    }
    if (action.slug == 'suggest-deal') {
      _titleController.text = '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _venueController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _conditionsController.dispose();
    _scheduleController.dispose();
    _neighborhoodController.dispose();
    _reasonController.dispose();
    _proofNoteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  _ContributionConfig get _config =>
      _ContributionConfig.fromSlug(widget.actionSlug);

  bool get _requiresListingSelection => _config.slug != 'suggest-deal';

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        config.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  config.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                if (_requiresListingSelection) ...[
                  Text(
                    'Select listing',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _searchController,
                    onChanged: _searchListings,
                    validator: (_) {
                      if (_selectedListing == null) {
                        return 'Pick a listing first.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search for the listing you want to update',
                    ),
                  ),
                  if (_searching)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (_selectedListing != null) ...[
                    const SizedBox(height: 12),
                    _SelectedListingTile(listing: _selectedListing!),
                  ],
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._searchResults
                        .take(4)
                        .map(
                          (deal) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              onTap: () => setState(() {
                                _selectedListing = deal;
                                _searchController.text = deal.venueName;
                                _searchResults = const [];
                              }),
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              title: Text(deal.venueName),
                              subtitle: Text(
                                '${deal.title} • ${deal.neighborhood}',
                              ),
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 12),
                ],
                if (!_requiresListingSelection) ...[
                  const _FieldLabel('Venue'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _venueController,
                    onChanged: _searchGoogleVenues,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Add the venue name.'
                        : _selectedGooglePlace == null
                        ? 'Pick a Google Maps venue.'
                        : null,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.place_outlined),
                      hintText: 'Search Google Maps venues',
                    ),
                  ),
                  if (_venueSearching)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (_selectedGooglePlace != null) ...[
                    const SizedBox(height: 12),
                    _SelectedGooglePlaceTile(place: _selectedGooglePlace!),
                  ],
                  if (_venuePredictions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._venuePredictions
                        .take(5)
                        .map(
                          (place) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              onTap: () => _selectGooglePlace(place),
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              leading: const Icon(Icons.place_outlined),
                              title: Text(place.mainText),
                              subtitle: Text(place.secondaryText),
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 12),
                  const _FieldLabel('Neighborhood'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _neighborhoodController,
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Add the area.' : null,
                    decoration: const InputDecoration(
                      hintText: 'Midtown, West Midtown, Ponce...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('Title'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Summarize the offer.'
                        : null,
                    decoration: const InputDecoration(
                      hintText: 'Short value-forward title',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const _FieldLabel('Details'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (value) => (value ?? '').trim().length < 6
                      ? 'Add a little more detail.'
                      : null,
                  decoration: InputDecoration(
                    hintText: config.primaryFieldHint,
                  ),
                ),
                if (config.slug != 'confirm-active') ...[
                  const SizedBox(height: 12),
                  const _FieldLabel('Conditions or restrictions'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _conditionsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'Age gates, exclusions, time windows, or quantity limits',
                    ),
                  ),
                ],
                if (config.slug == 'suggest-deal' ||
                    config.slug == 'suggest-update') ...[
                  const SizedBox(height: 12),
                  const _FieldLabel('Schedule'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _scheduleController,
                    decoration: const InputDecoration(
                      hintText: 'Tue 4PM-10PM, Daily after 9PM...',
                    ),
                  ),
                ],
                if (config.slug == 'report-expired') ...[
                  const SizedBox(height: 12),
                  const _FieldLabel('Reason'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _reasonController.text,
                    items: const [
                      DropdownMenuItem(
                        value: 'expired',
                        child: Text('Expired'),
                      ),
                      DropdownMenuItem(
                        value: 'details_incorrect',
                        child: Text('Details incorrect'),
                      ),
                      DropdownMenuItem(
                        value: 'venue_closed',
                        child: Text('Venue closed'),
                      ),
                    ],
                    onChanged: (value) =>
                        _reasonController.text = value ?? 'expired',
                    decoration: const InputDecoration(),
                  ),
                ],
                const SizedBox(height: 12),
                const _FieldLabel('Evidence note'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _proofNoteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                        'What did you see in person? Receipt, menu board, pricing sign, or timestamped photo.',
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _submitting
                      ? null
                      : () async {
                          try {
                            final assetKey = await ref
                                .read(repositoryProvider)
                                .requestProofUploadSlot();
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _proofAssetKey = assetKey;
                              _error = null;
                            });
                          } catch (_) {
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _error =
                                  'Unable to request a proof upload slot right now.';
                            });
                          }
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: DealDropPalette.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: config.tint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.upload_rounded,
                            color: DealDropPalette.ink,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _proofAssetKey == null
                                ? 'Add proof when available. A signed upload slot will be created for this submission.'
                                : 'Upload slot created: $_proofAssetKey',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE0E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: config.tint.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    config.reviewCopy,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DealDropPalette.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(
                      _submitting ? 'Submitting...' : config.submitLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _searchListings(String query) async {
    final normalized = query.trim();
    if (_selectedListing != null && _selectedListing!.venueName != normalized) {
      setState(() {
        _selectedListing = null;
      });
    }
    if (normalized.length < 2) {
      setState(() {
        _searchResults = const [];
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() {
        _searching = true;
      });
      try {
        final result = await ref.read(repositoryProvider).search(query: query);
        if (!mounted) {
          return;
        }
        setState(() {
          _searchResults = result.listings;
          _error = null;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _error = 'Unable to search listings right now.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _searching = false;
          });
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repository = ref.read(repositoryProvider);
      late final SubmissionOutcome outcome;
      switch (_config.slug) {
        case 'suggest-deal':
          final place = _selectedGooglePlace!;
          outcome = await repository.submitNewContribution(
            venueName: place.name,
            neighborhood: _neighborhoodController.text.trim(),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            conditions: _conditionsController.text.trim(),
            scheduleSummary: _scheduleController.text.trim(),
            latitude: place.latitude,
            longitude: place.longitude,
            googlePlace: place.toJson(),
          );
        case 'suggest-update':
          outcome = await repository.submitListingUpdate(
            listingId: _selectedListing!.id,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            conditions: _conditionsController.text.trim().isEmpty
                ? null
                : _conditionsController.text.trim(),
            scheduleSummary: _scheduleController.text.trim().isEmpty
                ? null
                : _scheduleController.text.trim(),
          );
        case 'confirm-active':
          outcome = await repository.confirmListing(
            listingId: _selectedListing!.id,
          );
        case 'report-expired':
          outcome = await repository.reportExpired(
            listingId: _selectedListing!.id,
            reason: _reasonController.text,
            notes: _descriptionController.text.trim(),
          );
        default:
          outcome = const SubmissionOutcome(queuedOffline: false);
      }
      if (!mounted) {
        return;
      }
      ref.invalidate(contributionHistoryProvider);
      ref.invalidate(karmaSnapshotProvider);
      ref.invalidate(offlineQueueProvider);
      final feedback = outcome.queuedOffline
          ? 'Saved offline and will retry automatically.'
          : 'Contribution sent for review.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(feedback)));
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _searchGoogleVenues(String query) async {
    setState(() {
      _selectedGooglePlace = null;
    });
    final normalized = query.trim();
    if (normalized.length < 2) {
      setState(() {
        _venuePredictions = const [];
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() {
        _venueSearching = true;
        _error = null;
      });
      try {
        final predictions = await _googlePlacesService.searchPlaces(normalized);
        if (!mounted) {
          return;
        }
        setState(() {
          _venuePredictions = predictions;
          _error = predictions.isEmpty
              ? 'No Google Maps venues found. Check the name or API key.'
              : null;
        });
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _venuePredictions = const [];
          _error = _googlePlacesService.available
              ? 'Unable to search Google Maps venues right now.'
              : 'Google Maps venue search needs GOOGLE_MAPS_API_KEY in this build.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _venueSearching = false;
          });
        }
      }
    });
  }

  Future<void> _selectGooglePlace(GooglePlacePrediction prediction) async {
    setState(() {
      _venueSearching = true;
      _error = null;
    });
    try {
      final details = await _googlePlacesService.fetchPlaceDetails(
        prediction.placeId,
      );
      if (!mounted) {
        return;
      }
      if (details == null) {
        setState(() {
          _venueSearching = false;
          _error = 'Unable to load Google Maps details for this venue.';
        });
        return;
      }
      setState(() {
        _selectedGooglePlace = details;
        _venueController.text = details.name;
        _venuePredictions = const [];
        _venueSearching = false;
        if (details.formattedAddress.isNotEmpty) {
          _neighborhoodController.text = _inferArea(details.formattedAddress);
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _venueSearching = false;
        _error = 'Unable to load Google Maps details for this venue.';
      });
    }
  }

  String _inferArea(String address) {
    final parts = address.split(',').map((item) => item.trim()).toList();
    if (parts.length >= 2) {
      return parts[parts.length - 2].replaceAll(RegExp(r'\s+\d{5}.*$'), '');
    }
    return _neighborhoodController.text;
  }
}

class _SelectedGooglePlaceTile extends StatelessWidget {
  const _SelectedGooglePlaceTile({required this.place});

  final GooglePlaceDetails place;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: DealDropShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DealDropPalette.sky,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.map_outlined, color: DealDropPalette.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  place.formattedAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

class _SelectedListingTile extends StatelessWidget {
  const _SelectedListingTile({required this.listing});

  final Deal listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: DealDropShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: listing.trustBand.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              listing.trustBand.icon,
              color: listing.trustBand.foreground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.venueName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${listing.title} • ${listing.neighborhood}',
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

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
          border: Border.all(color: DealDropPalette.divider),
        ),
        child: Icon(icon, color: DealDropPalette.ink),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

class _ContributionConfig {
  const _ContributionConfig({
    required this.slug,
    required this.title,
    required this.description,
    required this.primaryFieldHint,
    required this.reviewCopy,
    required this.submitLabel,
    required this.tint,
  });

  final String slug;
  final String title;
  final String description;
  final String primaryFieldHint;
  final String reviewCopy;
  final String submitLabel;
  final Color tint;

  factory _ContributionConfig.fromSlug(String slug) {
    return switch (slug) {
      'suggest-deal' => const _ContributionConfig(
        slug: 'suggest-deal',
        title: 'Suggest a new deal',
        description:
            'Add a new listing for review. Clear timing, price, and neighborhood details move faster.',
        primaryFieldHint: 'Describe the offer, timing, and why it matters.',
        reviewCopy:
            'New listings stay pending until moderation confirms source quality, duplicates, and launch-market relevance.',
        submitLabel: 'Submit for review',
        tint: DealDropPalette.goldSoft,
      ),
      'suggest-update' => const _ContributionConfig(
        slug: 'suggest-update',
        title: 'Suggest an update',
        description:
            'Correct pricing, time windows, restrictions, or neighborhood information.',
        primaryFieldHint: 'Explain exactly what changed and what you saw.',
        reviewCopy:
            'Updates slow down trust decay only when the signal is clear and recent.',
        submitLabel: 'Send update',
        tint: DealDropPalette.sky,
      ),
      'confirm-active' => const _ContributionConfig(
        slug: 'confirm-active',
        title: 'Confirm still active',
        description:
            'Use this when you have strong in-market confidence the deal is valid right now.',
        primaryFieldHint:
            'Where did you confirm it? Menu board, receipt, in-person check...',
        reviewCopy:
            'High-quality confirmations can finalize points immediately on strong-trust listings.',
        submitLabel: 'Confirm listing',
        tint: Color(0xFFDDF7EE),
      ),
      'report-expired' => const _ContributionConfig(
        slug: 'report-expired',
        title: 'Report expired',
        description:
            'Use this when the offer is stale, unavailable, or conflicts with what is actually in market.',
        primaryFieldHint: 'Explain what failed and how confident you are.',
        reviewCopy:
            'Conflicting reports can push a listing into disputed state very quickly on high-traffic items.',
        submitLabel: 'Report issue',
        tint: Color(0xFFFFE5CC),
      ),
      _ => const _ContributionConfig(
        slug: 'unknown',
        title: 'Contribution',
        description: 'Submit a moderated contribution.',
        primaryFieldHint: 'Add context for the moderation team.',
        reviewCopy:
            'All high-impact actions are reviewed before they affect public trust labels.',
        submitLabel: 'Submit',
        tint: DealDropPalette.goldSoft,
      ),
    };
  }
}
