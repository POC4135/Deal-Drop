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
  String? _confirmationEmail;
  bool _emailExists = false;

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
    if (_confirmationEmail != null) {
      return _ConfirmEmailScreen(
        email: _confirmationEmail!,
        onGoToSignIn: () => context.go('/auth/sign-in'),
      );
    }

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
                      'Hapora',
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
                  onChanged: (_) {
                    if (_emailExists) setState(() => _emailExists = false);
                  },
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
                if (_emailExists) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: DealDropPalette.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'An account with this email already exists. ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(
                          widget.redirectTo == null
                              ? '/auth/sign-in'
                              : '/auth/sign-in?from=${Uri.encodeComponent(widget.redirectTo!)}',
                        ),
                        child: Text(
                          'Sign in instead',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: DealDropPalette.goldDeep,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                          : (_signIn ? 'Enter Hapora' : 'Create account'),
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
    } on EmailAlreadyExistsException {
      setState(() {
        _emailExists = true;
      });
    } on EmailConfirmationRequiredException catch (error) {
      setState(() {
        _confirmationEmail = error.email;
      });
    } catch (error) {
      setState(() {
        _error = _friendlyAuthError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String _friendlyAuthError(Object error) {
    if (error is ApiException) return error.message;
    final raw = '$error'.toLowerCase();
    if (raw.contains('invalid_credentials') || raw.contains('invalid login')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('email_not_confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (raw.contains('too_many_requests') || raw.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (raw.contains('user_not_found')) {
      return 'No account found with that email.';
    }
    return 'Something went wrong. Please try again.';
  }
}

class _ConfirmEmailScreen extends StatelessWidget {
  const _ConfirmEmailScreen({required this.email, required this.onGoToSignIn});

  final String email;
  final VoidCallback onGoToSignIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6ED),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 30,
                  color: Color(0xFF2D7A3A),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Check your inbox',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'We sent a confirmation link to',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Click the link in the email, then come back here to sign in.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7A7670),
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGoToSignIn,
                  child: const Text('Go to sign in'),
                ),
              ),
            ],
          ),
        ),
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
