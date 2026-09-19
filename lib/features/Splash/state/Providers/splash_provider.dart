import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_provider.dart';
import 'splash_state.dart';

/// Holds the splash on screen until both are true: the minimum branding
/// time has elapsed, and [AuthNotifier.restoreSession] has decided whether a
/// stored token is still good.
class SplashNotifier extends Notifier<SplashState> {
  static const _minSplashDuration = Duration(milliseconds: 2800);

  @override
  SplashState build() {
    final stopwatch = Stopwatch()..start();
    var resolved = false;

    Future<void> resolve(AuthState auth) async {
      if (resolved || auth.status == AuthStatus.unknown) return;
      resolved = true;
      final remaining = _minSplashDuration - stopwatch.elapsed;
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      if (!ref.mounted) return;
      state = SplashState(
        status: auth.isAuthenticated
            ? SplashStatus.authenticated
            : auth.serverUnreachable
                ? SplashStatus.error
                : SplashStatus.unauthenticated,
        errorMessage: auth.serverUnreachable
            ? 'We couldn’t reach the server to restore your session. Check your connection and try again.'
            : null,
      );
    }

    ref.listen<AuthState>(authProvider, (_, next) => resolve(next));
    // Auth may already be known (hot restart, or a very fast storage read).
    unawaited(resolve(ref.read(authProvider)));

    return const SplashState();
  }

  void retry() {
    ref.invalidateSelf();
    ref.read(authProvider.notifier).restoreSession();
  }
}

final splashProvider = NotifierProvider<SplashNotifier, SplashState>(SplashNotifier.new);
