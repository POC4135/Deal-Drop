import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/app_providers.dart';

class AuthFormScreen extends ConsumerStatefulWidget {
  const AuthFormScreen({super.key, required this.mode, this.redirectTo});

  final String mode;
  final String? redirectTo;

  @override
  ConsumerState<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends ConsumerState<AuthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _neighborhoodController = TextEditingController(text: 'Midtown');

  bool _submitting = false;
  String? _error;

  bool get _signIn => widget.mode == 'sign-in';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .track('screen_view', screen: _signIn ? 'sign_in' : 'sign_up');
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _signIn ? 'Sign in' : 'Create account';
    final subtitle = _signIn ? 'Sync saves.' : 'Save deals. Earn Karma.';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DealDropPalette.divider),
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'DealDrop',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: DealDropPalette.goldDeep),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(title, style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                _AuthSubtitleChip(text: subtitle),
                const SizedBox(height: 22),
                if (!_signIn) ...[
                  _FieldLabel('Display name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _displayNameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (_signIn) {
                        return null;
                      }
                      if ((value ?? '').trim().length < 2) {
                        return 'Use at least 2 characters.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      hintText: 'How people will see you',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Home neighborhood'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _neighborhoodController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (_signIn) {
                        return null;
                      }
                      if ((value ?? '').trim().isEmpty) {
                        return 'Add your primary area.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.place_outlined),
                      hintText: 'Midtown, West Midtown, Ponce...',
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _FieldLabel('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (!email.contains('@')) {
                      return 'Enter a valid email.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                    hintText: 'you@email.com',
                  ),
                ),
                const SizedBox(height: 14),
                _FieldLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if ((value ?? '').length < 8) {
                      return 'Use at least 8 characters.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                    hintText: 'Enter your password',
                  ),
                  onFieldSubmitted: (_) => _submit(context),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE0E5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(context),
                    child: Text(
                      _submitting
                          ? 'Working...'
                          : (_signIn ? 'Enter DealDrop' : 'Create account'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _signIn
                        ? 'Guest saves merge after sign in.'
                        : 'Neighborhood keeps the feed local.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () {
                      final nextMode = _signIn ? 'sign-up' : 'sign-in';
                      final redirect = widget.redirectTo;
                      final path = redirect == null
                          ? '/auth/$nextMode'
                          : '/auth/$nextMode?from=${Uri.encodeComponent(redirect)}';
                      context.go(path);
                    },
                    child: Text(
                      _signIn
                          ? 'Need an account? Sign up'
                          : 'Already have an account? Sign in',
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

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (_signIn) {
        await ref
            .read(authControllerProvider.notifier)
            .signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _displayNameController.text.trim(),
              homeNeighborhood: _neighborhoodController.text.trim(),
            );
      }
      if (!mounted) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      context.go(widget.redirectTo ?? '/deals');
    } catch (error) {
      setState(() {
        _error = error is ApiException ? error.message : '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
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

class _AuthSubtitleChip extends StatelessWidget {
  const _AuthSubtitleChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: DealDropPalette.warmSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
