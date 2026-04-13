import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthFormScreen extends StatelessWidget {
  const AuthFormScreen({super.key, required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final signIn = mode == 'sign-in';
    final title = signIn ? 'Sign In' : 'Create Account';
    final subtitle = signIn
        ? 'Welcome back to Atlanta’s curated value network.'
        : 'Join the curated Atlanta network for fresh nearby drops.';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                  Text(
                    'DealDrop',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: DealDropPalette.goldDeep,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(title, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 12),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 28),
              if (!signIn) ...[
                const _FieldLabel('Location'),
                const SizedBox(height: 10),
                const TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.place_outlined),
                    hintText: 'City or zip code',
                  ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Username'),
                const SizedBox(height: 10),
                const TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    hintText: 'Pick a unique name',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const _FieldLabel('Email'),
              const SizedBox(height: 10),
              const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                  hintText: 'you@email.com',
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Password'),
              const SizedBox(height: 10),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  hintText: 'Enter your password',
                ),
              ),
              if (!signIn) ...[
                const SizedBox(height: 16),
                const _FieldLabel('Age'),
                const SizedBox(height: 10),
                const TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.cake_outlined),
                    hintText: 'Your age',
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/deals'),
                  child: Text(signIn ? 'Enter DealDrop' : 'Get Started'),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  signIn
                      ? 'By signing in, you agree to our terms and community standards.'
                      : 'By tapping Get Started, you acknowledge our editorial standards and community guidelines.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/auth/${signIn ? 'sign-up' : 'sign-in'}'),
                  child: Text(
                    signIn ? 'Need an account? Sign up' : 'Already have an account? Sign in',
                  ),
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
