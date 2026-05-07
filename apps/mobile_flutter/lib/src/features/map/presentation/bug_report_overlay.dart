import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_providers.dart';

class BugReportButton extends StatelessWidget {
  const BugReportButton({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: DealDropShadows.card,
      ),
      child: IconButton(
        onPressed: () => _showSheet(context),
        icon: const Icon(Icons.bug_report_outlined),
        color: DealDropPalette.ink,
        tooltip: 'Report a bug',
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final metadata = {
      'route': currentRoute,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
      'screen': '${size.width.toInt()} × ${size.height.toInt()}',
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BugReportSheet(metadata: metadata),
    );
  }
}

class _BugReportSheet extends ConsumerStatefulWidget {
  const _BugReportSheet({required this.metadata});

  final Map<String, String> metadata;

  @override
  ConsumerState<_BugReportSheet> createState() => _BugReportSheetState();
}

class _BugReportSheetState extends ConsumerState<_BugReportSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: DealDropShadows.soft,
      ),
      child: _submitted
          ? _SuccessView(onDone: () => Navigator.pop(context))
          : _FormView(
              titleController: _titleController,
              descriptionController: _descriptionController,
              submitting: _submitting,
              onSubmit: _submit,
              onCancel: () => Navigator.pop(context),
            ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(repositoryProvider).submitFeedback(
            title: title,
            description: _descriptionController.text.trim(),
            metadata: widget.metadata,
          );
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send report — try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.titleController,
    required this.descriptionController,
    required this.submitting,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: DealDropPalette.goldSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bug_report_outlined,
                size: 20,
                color: DealDropPalette.goldDeep,
              ),
            ),
            const SizedBox(width: 12),
            Text('Report a Bug',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              color: DealDropPalette.muted,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: titleController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'What went wrong?',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Details (optional)',
            alignLabelWithHint: true,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Report'),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: DealDropPalette.mint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.check_rounded,
              size: 28, color: DealDropPalette.mintDeep),
        ),
        const SizedBox(height: 14),
        Text('Report sent!', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Thanks — the team will look into it.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onDone, child: const Text('Done')),
        ),
      ],
    );
  }
}
