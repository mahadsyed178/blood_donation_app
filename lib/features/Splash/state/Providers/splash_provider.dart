
import 'package:blood_donation_app/features/Splash/state/Providers/splash_state.dart' show SplashState, SplashStatus;
import 'package:riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';


// TODO: Replace this with a real check once auth feature is built.
// e.g. return ref.read(authRepositoryProvider).getCurrentUser();
Future<bool> _checkIsLoggedIn(Ref ref) async {
  // Simulated check — always returns false (not logged in) for now.
  await Future.delayed(const Duration(milliseconds: 300));
  return false;
}

class SplashNotifier extends StateNotifier<SplashState> {
  final Ref ref;

  SplashNotifier(this.ref) : super(const SplashState()) {
    _initialize();
  }

  static const _minSplashDuration = Duration(milliseconds: 2800);

  Future<void> _initialize() async {
    final stopwatch = Stopwatch()..start();

    try {
      final isLoggedIn = await _checkIsLoggedIn(ref);

      final elapsed = stopwatch.elapsed;
      if (elapsed < _minSplashDuration) {
        await Future.delayed(_minSplashDuration - elapsed);
      }

      if (!mounted) return;

      state = state.copyWith(
        status: isLoggedIn
            ? SplashStatus.authenticated
            : SplashStatus.unauthenticated,
      );
    } catch (e) {
      final elapsed = stopwatch.elapsed;
      if (elapsed < _minSplashDuration) {
        await Future.delayed(_minSplashDuration - elapsed);
      }

      if (!mounted) return;

      state = state.copyWith(
        status: SplashStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void retry() {
    state = const SplashState();
    _initialize();
  }
}

final splashProvider =
StateNotifierProvider<SplashNotifier, SplashState>((ref) {
  return SplashNotifier(ref);
});