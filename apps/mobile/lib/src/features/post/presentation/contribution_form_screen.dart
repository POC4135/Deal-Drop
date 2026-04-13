import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContributionFormScreen extends StatelessWidget {
  const ContributionFormScreen({super.key, required this.actionSlug});

  final String actionSlug;

  @override
  Widget build(BuildContext context) {
    final config = _ContributionConfig.fromSlug(actionSlug);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                    child: Text(config.title, style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(config.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Restaurant or venue',
                  hintText: 'Add the place name',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                decoration: InputDecoration(
                  labelText: config.primaryFieldLabel,
                  hintText: config.primaryFieldHint,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Area or address',
                  hintText: 'Midtown, West Midtown, Ponce, Beltline...',
                ),
              ),
              const SizedBox(height: 14),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Optional evidence note',
                  hintText: 'Receipt, menu board, screenshot, or in-person observation',
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: DealDropPalette.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: config.tint,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.upload_rounded, color: DealDropPalette.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Proof uploads will be supported here once signed-upload infrastructure is connected.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: config.tint.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  config.reviewCopy,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DealDropPalette.ink,
                      ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${config.title} queued for moderation review.')),
                    );
                  },
                  child: Text(config.submitLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
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
          border: Border.all(color: DealDropPalette.divider),
        ),
        child: Icon(icon, color: DealDropPalette.ink),
      ),
    );
  }
}

class _ContributionConfig {
  const _ContributionConfig({
    required this.title,
    required this.description,
    required this.primaryFieldLabel,
    required this.primaryFieldHint,
    required this.reviewCopy,
    required this.submitLabel,
    required this.tint,
  });

  final String title;
  final String description;
  final String primaryFieldLabel;
  final String primaryFieldHint;
  final String reviewCopy;
  final String submitLabel;
  final Color tint;

  factory _ContributionConfig.fromSlug(String slug) {
    return switch (slug) {
      'suggest-deal' => const _ContributionConfig(
          title: 'Suggest a new deal',
          description: 'Add a new listing for review. Clear timing and pricing details increase acceptance speed.',
          primaryFieldLabel: 'Deal details',
          primaryFieldHint: 'Describe the offer, timing, and any restrictions',
          reviewCopy: 'New listings stay pending until moderation confirms source quality, duplicates, and launch-market relevance.',
          submitLabel: 'Submit for review',
          tint: DealDropPalette.goldSoft,
        ),
      'suggest-update' => const _ContributionConfig(
          title: 'Suggest an update',
          description: 'Correct pricing, time windows, terms, or neighborhood information without overwriting trust history.',
          primaryFieldLabel: 'What changed?',
          primaryFieldHint: 'Explain the corrected timing, price, or conditions',
          reviewCopy: 'Updates help the trust system decay stale info more slowly when supported by strong evidence.',
          submitLabel: 'Send update',
          tint: DealDropPalette.sky,
        ),
      'confirm-active' => const _ContributionConfig(
          title: 'Confirm still active',
          description: 'Use this when you have strong in-market confidence that the deal is currently valid.',
          primaryFieldLabel: 'Confirmation note',
          primaryFieldHint: 'Where did you verify it? Menu board, receipt, in-person check...',
          reviewCopy: 'Confirmations increase confidence gradually and are weighted by contributor reliability.',
          submitLabel: 'Confirm listing',
          tint: Color(0xFFDDF7EE),
        ),
      'report-expired' => const _ContributionConfig(
          title: 'Report expired',
          description: 'Use this when the offer is stale, unavailable, or conflicts with current venue information.',
          primaryFieldLabel: 'What was wrong?',
          primaryFieldHint: 'Explain what you saw and why the listing looks expired',
          reviewCopy: 'Conflicting reports can reduce trust quickly on high-traffic listings, then trigger recheck queues.',
          submitLabel: 'Report issue',
          tint: Color(0xFFFFE5CC),
        ),
      _ => const _ContributionConfig(
          title: 'Contribution',
          description: 'Submit a moderated contribution.',
          primaryFieldLabel: 'Details',
          primaryFieldHint: 'Add context for the moderation team',
          reviewCopy: 'All high-impact actions are reviewed before they affect public trust labels.',
          submitLabel: 'Submit',
          tint: DealDropPalette.goldSoft,
        ),
    };
  }
}
