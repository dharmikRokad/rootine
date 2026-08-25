import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rootine/core/app_images.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_strings.dart';
import '../../habits/presentation/home_page.dart';
import '../application/auth_controller.dart';

class AuthGatePage extends ConsumerWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text(AppStrings.authenticationErrorMessage(error))),
      ),
      data: (user) {
        if (user != null && !user.isAnonymous) {
          return const HabitsHomePage();
        }

        return _SignInPage(
          onSignIn: () => ref.read(authActionsProvider).signInWithGoogle(),
        );
      },
    );
  }
}

class _SignInPage extends ConsumerWidget {
  const _SignInPage({required this.onSignIn});

  final Future<void> Function() onSignIn;

  void _handleSignIn(WidgetRef ref) async {
    ref.read(signInLoadingProvider.notifier).state = true;
    ref.read(signInErrorProvider.notifier).state = null;

    try {
      await onSignIn();
    } catch (e) {
      ref.read(signInErrorProvider.notifier).state =
          'Sign-in failed: ${e.toString()}';
      ref.read(signInLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(signInLoadingProvider);
    final errorMessage = ref.watch(signInErrorProvider);

    return Stack(
      children: [
        Image.asset(
          AppImages.authBg,
          fit: BoxFit.fill,
          width: double.infinity,
          height: double.infinity,
        ),
        Scaffold(
          backgroundColor: AppColors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(
                    image: AssetImage(AppImages.rootineLogo),
                    width: 100,
                    height: 100,
                    fit: BoxFit.fill,
                    color: Theme.of(context).brightness == Brightness.light
                        ? null
                        : AppColors.authGradientEnd,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.welcomeTo,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.nijDarshan,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontWeight: .bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.welcomeSubtitle,
                    textAlign: TextAlign.center,
                  ),
                  Spacer(),
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: isLoading ? null : () => _handleSignIn(ref),
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      isLoading
                          ? AppStrings.signingIn
                          : AppStrings.signInWithGoogle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
