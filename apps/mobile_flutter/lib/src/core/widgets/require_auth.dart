import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/app_providers.dart';

class RequireAuth extends ConsumerWidget {
  const RequireAuth({
    super.key,
    required this.child,
    required this.redirectTo,
    this.message = 'Sign in to continue.',
  });

  final Widget child;
  final String redirectTo;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      data: (state) {
        if (state.isAuthenticated) {
          return child;
        }
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You can still browse the deals feed and map as a guest.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push(
                          '/auth/sign-in?from=${Uri.encodeComponent(redirectTo)}',
                        ),
                        child: const Text('Sign in'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
