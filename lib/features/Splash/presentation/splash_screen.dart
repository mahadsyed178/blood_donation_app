import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../state/Providers/splash_provider.dart';
import '../state/Providers/splash_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _taglineSlideAnimation;

  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // Logo + text entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // Looping dots animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoController.forward();
  }

  /// Once the stored session has been checked (and the minimum splash time
  /// has elapsed — see SplashNotifier), route by the outcome.
  void _onSplashResolved(SplashState state) {
    if (!mounted) return;
    switch (state.status) {
      case SplashStatus.authenticated:
        context.go(AppRoutes.dashboard);
      case SplashStatus.unauthenticated:
        context.go(AppRoutes.onboarding);
      case SplashStatus.error:
      case SplashStatus.loading:
        break; // error renders inline with a retry
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SplashState>(splashProvider, (_, next) => _onSplashResolved(next));
    // Handle the case where the provider already resolved before this
    // widget subscribed (e.g. a hot restart).
    final current = ref.watch(splashProvider);
    if (current.status != SplashStatus.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onSplashResolved(current));
    }

    return Scaffold(
      body: Container(
        color: Colors.redAccent,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 39,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'BloodBridge',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      Padding(
                        padding: const EdgeInsets.only(left: 29),
                        child: SlideTransition(
                          position: _taglineSlideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              'Donate because you can',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (current.status == SplashStatus.error)
                _OfflineRetry(
                  message: current.errorMessage ?? 'Server unreachable',
                  onRetry: () => ref.read(splashProvider.notifier).retry(),
                  onContinue: () => context.go(AppRoutes.login),
                )
              else
                _LoadingDots(controller: _dotsController),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Stagger each dot's bounce by offsetting its phase
            final delay = index * 0.2;
            final t = (controller.value - delay) % 1.0;
            final bounce = t < 0
                ? 0.0
                : (t < 0.5
                ? Curves.easeOut.transform(t * 2)
                : Curves.easeIn.transform((1 - t) * 2));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.translate(
                offset: Offset(0, -8 * bounce),
                child: Opacity(
                  opacity: 0.5 + (0.5 * bounce),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _OfflineRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  const _OfflineRetry({required this.message, required this.onRetry, required this.onContinue});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onContinue,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Log in'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      );
}
