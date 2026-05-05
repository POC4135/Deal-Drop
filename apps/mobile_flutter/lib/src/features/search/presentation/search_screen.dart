import 'dart:async';

import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/app_models.dart';
import '../../../core/services/app_providers.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../discovery/presentation/widgets/deal_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  SearchPayload? _result;
  bool _loading = false;
  String? _error;
  String? _neighborhood;
  TrustBand? _trustBand;

  @override
  void initState() {
    super.initState();
    Future.microtask(_performSearch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(filtersMetadataProvider).valueOrNull;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DealDropPalette.divider),
                      ),
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (_) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 250),
                          _performSearch,
                        );
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Search by venue, offer, or area',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _showFilters(context, filters),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DealDropPalette.divider),
                      ),
                      child: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_neighborhood != null)
                    InputChip(
                      label: Text(_neighborhood!),
                      onDeleted: () {
                        setState(() => _neighborhood = null);
                        _performSearch();
                      },
                    ),
                  if (_trustBand != null)
                    InputChip(
                      label: Text(_trustBand!.label),
                      onDeleted: () {
                        setState(() => _trustBand = null);
                        _performSearch();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              else if ((_result?.listings.isEmpty ?? true) &&
                  _controller.text.trim().isNotEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No DealDrop match.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search this place on Google Maps.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _openGoogleMapsSearch,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open in Google'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      if ((_result?.suggestions.isNotEmpty ?? false) &&
                          _controller.text.trim().isNotEmpty) ...[
                        Text(
                          'Suggestions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _result!.suggestions
                              .map(
                                (suggestion) => ActionChip(
                                  label: Text(suggestion),
                                  onPressed: () {
                                    _controller.text = suggestion;
                                    _performSearch();
                                  },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 22),
                      ],
                      ...(_result?.listings ?? const <Deal>[]).map(
                        (deal) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: DealCard(
                            deal: deal,
                            onTap: () => context.push('/listing/${deal.id}'),
                            onSavePressed: () async {
                              final currentlySaved = deal.saved;
                              try {
                                await ref
                                    .read(repositoryProvider)
                                    .toggleFavorite(
                                      deal.id,
                                      save: !currentlySaved,
                                    );
                              } finally {
                                _performSearch();
                              }
                            },
                          ),
                        ),
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

  Future<void> _performSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(repositoryProvider)
          .search(
            query: _controller.text.trim(),
            neighborhood: _neighborhood,
            trustBand: _trustBand,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
      });
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
          _loading = false;
        });
      }
    }
  }

  Future<void> _openGoogleMapsSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showFilters(
    BuildContext context,
    FiltersMetadataModel? filters,
  ) async {
    final metadata = filters;
    if (metadata == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? pendingNeighborhood = _neighborhood;
        TrustBand? pendingTrustBand = _trustBand;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Neighborhood',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: metadata.neighborhoods
                        .map(
                          (value) => ChoiceChip(
                            selected: pendingNeighborhood == value,
                            label: Text(value),
                            onSelected: (_) => setModalState(() {
                              pendingNeighborhood = pendingNeighborhood == value
                                  ? null
                                  : value;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Trust', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: metadata.trustBands
                        .map(
                          (value) => ChoiceChip(
                            selected: pendingTrustBand == value,
                            label: Text(value.label),
                            onSelected: (_) => setModalState(() {
                              pendingTrustBand = pendingTrustBand == value
                                  ? null
                                  : value;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _neighborhood = null;
                              _trustBand = null;
                            });
                            Navigator.of(context).pop();
                            _performSearch();
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _neighborhood = pendingNeighborhood;
                              _trustBand = pendingTrustBand;
                            });
                            Navigator.of(context).pop();
                            _performSearch();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
