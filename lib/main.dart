// import 'package:blood_donation_app/features/MultiRoleAuthentication/NewPassword/presentation/NewPasswordScreen/newpassword_screen.dart';
// import 'package:blood_donation_app/features/MultiRoleAuthentication/OTPVerification/presentation/OTPScreen/otp_screen.dart';
// import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/ForgotPasswordScreen/forgot_password.dart';
// import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/LoginScreen/login_screen.dart';
// import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/RoleSelection/BloodDonorScreen/blood_donor.dart';
// import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/SignupScreen/signup_screen.dart';
// import 'package:blood_donation_app/features/Onboarding/presentation/onboarding_screen.dart';
// import 'package:blood_donation_app/features/Splash/presentation/splash_screen.dart';
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: CreateNewPasswordScreen(
//
//       ),
//     );
//   }
// }







import 'package:blood_donation_app/core/routes/app_router.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BLOOD-BRIDGE- Blood Donation App',
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          primary: const Color(0xFFE53935),
        ),
      ),
    );
  }
}
