import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart' show appRouterProvider, rootNavigatorKey;
import '../../../core/services/app_providers.dart';

enum _ReportType { bug, suggestion }

class BugReportButton extends ConsumerStatefulWidget {
  const BugReportButton({super.key});

  @override
  ConsumerState<BugReportButton> createState() => _BugReportButtonState();
}

class _BugReportButtonState extends ConsumerState<BugReportButton> {
  bool _sheetOpen = false;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !_sheetOpen,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          boxShadow: DealDropShadows.card,
        ),
        child: IconButton(
          onPressed: _showSheet,
          icon: const Icon(Icons.feedback_rounded, color: Color(0xFFE53935)),
        ),
      ),
    );
  }

  Future<void> _showSheet() async {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    final size = MediaQuery.of(navContext).size;
    final route = ref
        .read(appRouterProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();
    final session = ref.read(authControllerProvider).valueOrNull?.session;
    final metadata = {
      if (route.isNotEmpty) 'route': route,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
      'screen': '${size.width.toInt()} × ${size.height.toInt()}',
      if (session != null) ...{
        'user': session.displayName,
        'email': session.email,
      },
    };

    setState(() => _sheetOpen = true);
    await showModalBottomSheet<void>(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbackSheet(metadata: metadata),
    );
    if (mounted) setState(() => _sheetOpen = false);
  }
}

class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet({required this.metadata});

  final Map<String, String> metadata;

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  final _descriptionController = TextEditingController();
  _ReportType _type = _ReportType.bug;
  bool _submitting = false;
  bool _submitted = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      final filled = _descriptionController.text.trim().isNotEmpty;
      if (filled != _hasText) setState(() => _hasText = filled);
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: DealDropShadows.soft,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20 + bottom),
        child: _submitted
            ? _SuccessView(
                type: _type,
                onDone: () => Navigator.pop(context),
              )
            : _FormView(
                type: _type,
                onTypeChanged: (t) => setState(() => _type = t),
                descriptionController: _descriptionController,
                submitting: _submitting,
                canSubmit: _hasText,
                onSubmit: _submit,
                onCancel: () => Navigator.pop(context),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(repositoryProvider).submitFeedback(
            title: _type == _ReportType.bug ? 'Bug Report' : 'Suggestion',
            description: description,
            metadata: {
              ...widget.metadata,
              'type': _type == _ReportType.bug ? 'bug' : 'suggestion',
            },
          );
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send — try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.type,
    required this.onTypeChanged,
    required this.descriptionController,
    required this.submitting,
    required this.canSubmit,
    required this.onSubmit,
    required this.onCancel,
  });

  final _ReportType type;
  final ValueChanged<_ReportType> onTypeChanged;
  final TextEditingController descriptionController;
  final bool submitting;
  final bool canSubmit;
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
            Text(
              'What would you like to report?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              color: DealDropPalette.muted,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<_ReportType>(
          segments: const [
            ButtonSegment(
              value: _ReportType.bug,
              label: Text('Report a Bug'),
              icon: Icon(Icons.bug_report_outlined),
            ),
            ButtonSegment(
              value: _ReportType.suggestion,
              label: Text('Make a Suggestion'),
              icon: Icon(Icons.lightbulb_outline),
            ),
          ],
          selected: {type},
          onSelectionChanged: (selection) => onTypeChanged(selection.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Details',
            alignLabelWithHint: true,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: submitting || !canSubmit ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.type, required this.onDone});

  final _ReportType type;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isSuggestion = type == _ReportType.suggestion;
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
        Text(
          isSuggestion ? 'Suggestion sent!' : 'Report sent!',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          isSuggestion
              ? 'Thanks — we love hearing ideas.'
              : 'Thanks — the team will look into it.',
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
