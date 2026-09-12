import 'package:blood_donation_app/features/AdminSafetyConsole/presentation/admin_safety_console_screen.dart';
import 'package:blood_donation_app/features/BloodRequestsLifeCycle/presentation/blood_request_lifecycle_screen.dart';
import 'package:blood_donation_app/features/Co-ordinationChat/presenatation/co-ordination_chat_screen.dart';
import 'package:blood_donation_app/features/DashBoardScreen/presentation/dashboard_screen.dart';
import 'package:blood_donation_app/features/DonorMatching/presentation/donor_matching_screen.dart';
import 'package:blood_donation_app/features/HospitalVerification/presentation/hospital_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- Auth & Onboarding Screens Imports ---
import 'package:blood_donation_app/features/Splash/presentation/splash_screen.dart';
import 'package:blood_donation_app/features/Onboarding/presentation/onboarding_screen.dart';
import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/LoginScreen/login_screen.dart';
import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/SignupScreen/signup_screen.dart';
import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/ForgotPasswordScreen/forgot_password.dart';
import 'package:blood_donation_app/features/MultiRoleAuthentication/OTPVerification/presentation/OTPScreen/otp_screen.dart';
import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/NewPassword/presentation/NewPasswordScreen/newpassword_screen.dart';
import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/RoleSelection/BloodDonorScreen/blood_donor.dart';
import 'app_routes.dart';
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  routes: [
    // ==========================================
    // 1. Splash & Onboarding
    // ==========================================
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // ==========================================
    // 2. Authentication Flow
    // ==========================================
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgot_password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.otpVerification,
      name: 'otp_verification',
      builder: (context, state) {
        final destination = state.extra as String? ?? '+92 300 1234567';
        return OtpVerificationScreen(destination: destination);
      },
    ),
    GoRoute(
      path: AppRoutes.newPassword,
      name: 'new_password',
      builder: (context, state) => const CreateNewPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.roleRegistration,
      name: 'role_registration',
      builder: (context, state) => const RoleBasedRegistrationScreen(),
    ),

    // ==========================================
    // 3. Main Dashboard (BottomNav & Drawer Shell)
    // ==========================================
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      builder: (context, state) => const MainDashboardScreen(),
    ),

    // ==========================================
    // 4. Standalone Direct Feature Routes
    // ==========================================
    GoRoute(
      path: AppRoutes.bloodRequests,
      name: 'blood_requests',
      builder: (context, state) => const BloodRequestsLifecycleScreen(),
    ),
    GoRoute(
      path: AppRoutes.liveMap,
      name: 'live_map',
      builder: (context, state) => const DonorMatchingScreen(),
    ),
    GoRoute(
      path: AppRoutes.hospitalVerification,
      name: 'hospital_verification',
      builder: (context, state) => const HospitalVerificationScreen(),
    ),
    GoRoute(
      path: AppRoutes.coordinationChat,
      name: 'coordination_chat',
      builder: (context, state) => const CoordinationChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminConsole,
      name: 'admin_console',
      builder: (context, state) => const AdminSafetyConsoleScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);