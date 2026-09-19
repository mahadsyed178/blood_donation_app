import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/BloodRequestsLifeCycle/presentation/create_request_screen.dart';
import '../../features/BloodRequestsLifeCycle/presentation/request_detail_screen.dart';
import '../../features/Co-ordinationChat/presenatation/chat_thread_screen.dart';
import '../../features/DashBoardScreen/presentation/dashboard_screen.dart';
import '../../features/DonorMatching/presentation/donor_matching_screen.dart';
import '../../features/MultiRoleAuthentication/presentation/ForgotPasswordScreen/forgot_password.dart';
import '../../features/MultiRoleAuthentication/presentation/LoginScreen/login_screen.dart';
import '../../features/MultiRoleAuthentication/presentation/NewPassword/presentation/NewPasswordScreen/newpassword_screen.dart';
import '../../features/MultiRoleAuthentication/presentation/RoleSelection/BloodDonorScreen/blood_donor.dart';
import '../../features/MultiRoleAuthentication/presentation/SignupScreen/signup_screen.dart';
import '../../features/MultiRoleAuthentication/state/signup_draft.dart';
import '../../features/Onboarding/presentation/onboarding_screen.dart';
import '../../features/Profile/presentation/profile_screen.dart';
import '../../features/Splash/presentation/splash_screen.dart';
import '../models/blood_request.dart';
import '../models/chat.dart';
import '../providers/auth_provider.dart';
import 'app_routes.dart';

/// Bridges Riverpod → GoRouter: any auth change re-runs `redirect`.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.uri.path;
      final isPublic = AppRoutes.public.contains(path);

      // Splash owns the "unknown" phase; nothing else renders until the
      // stored session has been checked.
      if (auth.status == AuthStatus.unknown) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (!auth.isAuthenticated && !isPublic) return AppRoutes.login;
      if (auth.isAuthenticated && isPublic && path != AppRoutes.splash) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, name: 'splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.login, name: 'login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, name: 'signup', builder: (_, __) => const SignUpScreen()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot_password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.newPassword,
        name: 'new_password',
        builder: (_, state) =>
            CreateNewPasswordScreen(initialEmail: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.roleRegistration,
        name: 'role_registration',
        builder: (_, state) =>
            RoleBasedRegistrationScreen(draft: state.extra as SignupDraft?),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (_, __) => const MainDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.createRequest,
        name: 'create_request',
        builder: (_, __) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.requestDetail,
        name: 'request_detail',
        builder: (_, state) => RequestDetailScreen(
          requestId: state.pathParameters['id']!,
          initial: state.extra as BloodRequest?,
        ),
      ),
      GoRoute(
        path: AppRoutes.locationPicker,
        name: 'location_picker',
        builder: (_, state) => DonorMatchingScreen(
          mode: state.extra as LocationPickerMode? ?? LocationPickerMode.pick,
        ),
      ),
      GoRoute(
        path: AppRoutes.chatThread,
        name: 'chat_thread',
        builder: (_, state) => ChatThreadScreen(
          matchId: state.pathParameters['matchId']!,
          summary: state.extra as ChatThreadSummary?,
        ),
      ),
      GoRoute(path: AppRoutes.profile, name: 'profile', builder: (_, __) => const ProfileScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
