// import 'package:flutter/material.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   bool _isLoginTab = true;
//   bool _obscurePassword = true;
//   bool _isLoading = false;
//
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//
//   static const Color primaryRed = Color(0xFFE53935);
//   static const Color lightPink = Color(0xFFFFF5F5);
//   static const Color textDark = Color(0xFF1E293B);
//   static const Color textGrey = Color(0xFF64748B);
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onLoginPressed() async {
//     setState(() => _isLoading = true);
//
//     // TODO: wire to auth usecase / Riverpod provider
//     await Future.delayed(const Duration(milliseconds: 800));
//
//     if (!mounted) return;
//     setState(() => _isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // --- Scrollable form content ---
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 28),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const SizedBox(height: 12),
//
//                     // --- Logo / Illustration — enlarged, matches onboarding style ---
//                     Center(
//                       child: Container(
//                         height: 240,
//                         width: double.infinity,
//                         constraints: const BoxConstraints(maxWidth: 320),
//                         padding: const EdgeInsets.all(8),
//                         child: Image.asset(
//                           'lib/core/constants/assets/animations/blood_donation_02.jpg',
//                           fit: BoxFit.contain,
//                           errorBuilder: (context, error, stackTrace) =>
//                           const Icon(
//                             Icons.bloodtype,
//                             size: 96,
//                             color: primaryRed,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 8),
//
//                     const Center(
//                       child: Text(
//                         'HEMALINK',
//                         style: TextStyle(
//                           fontSize: 30,
//                           fontWeight: FontWeight.w900,
//                           letterSpacing: 1.2,
//                           color: textDark,
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 28),
//
//                     // --- Login / Sign Up Toggle ---
//                     Container(
//                       height: 52,
//                       padding: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         color: lightPink,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(color: const Color(0xFFFFE0E0)),
//                       ),
//                       child: Row(
//                         children: [
//                           _buildTab('Login', true),
//                           _buildTab('Sign Up', false),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     // --- Email / Mobile field ---
//                     const Text(
//                       'E-mail ID / Mobile number',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: textDark,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: _emailController,
//                       keyboardType: TextInputType.emailAddress,
//                       style: const TextStyle(fontSize: 14),
//                       decoration: InputDecoration(
//                         hintText: 'Enter your E-mail ID / Mobile number',
//                         hintStyle: const TextStyle(
//                           color: Color(0xFFA0AEC0),
//                           fontSize: 13,
//                         ),
//                         suffixIcon: const Icon(
//                           Icons.visibility_outlined,
//                           color: Color(0xFFA0AEC0),
//                           size: 20,
//                         ),
//                         filled: true,
//                         fillColor: const Color(0xFFF8FAFC),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 14,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide:
//                           const BorderSide(color: Color(0xFFE2E8F0)),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide:
//                           const BorderSide(color: Color(0xFFE2E8F0)),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide:
//                           const BorderSide(color: primaryRed, width: 1.5),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 18),
//
//                     // --- Password field ---
//                     const Text(
//                       'Password',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: textDark,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: _passwordController,
//                       obscureText: _obscurePassword,
//                       style: const TextStyle(fontSize: 14),
//                       decoration: InputDecoration(
//                         hintText: 'Password',
//                         hintStyle: const TextStyle(
//                           color: Color(0xFFA0AEC0),
//                           fontSize: 13,
//                         ),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _obscurePassword
//                                 ? Icons.visibility_outlined
//                                 : Icons.visibility_off_outlined,
//                             color: const Color(0xFFA0AEC0),
//                             size: 20,
//                           ),
//                           onPressed: () => setState(
//                                   () => _obscurePassword = !_obscurePassword),
//                         ),
//                         filled: true,
//                         fillColor: const Color(0xFFF8FAFC),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 14,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide:
//                           const BorderSide(color: Color(0xFFE2E8F0)),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide:
//                           const BorderSide(color: Color(0xFFE2E8F0)),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide:
//                           const BorderSide(color: primaryRed, width: 1.5),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 8),
//
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: TextButton(
//                         onPressed: () {
//                           // TODO: navigate to forgot password flow
//                         },
//                         style: TextButton.styleFrom(
//                           padding: EdgeInsets.zero,
//                           minimumSize: Size.zero,
//                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         ),
//                         child: const Text(
//                           'Forgot Password?',
//                           style: TextStyle(
//                             color: primaryRed,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 12),
//
//                     // --- Biometric login ---
//                     Center(
//                       child: Column(
//                         children: [
//                           InkWell(
//                             borderRadius: BorderRadius.circular(40),
//                             onTap: () {
//                               // TODO: trigger biometric auth
//                             },
//                             child: Container(
//                               height: 60,
//                               width: 60,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: lightPink,
//                                 border: Border.all(
//                                   color: primaryRed.withOpacity(0.3),
//                                   width: 1.5,
//                                 ),
//                               ),
//                               child: const Icon(
//                                 Icons.fingerprint,
//                                 color: primaryRed,
//                                 size: 30,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text(
//                             'Please scan your face or fingerprint',
//                             style: TextStyle(color: textGrey, fontSize: 12),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//                   ],
//                 ),
//               ),
//             ),
//
//             // --- Fixed bottom Login button — always docked at screen bottom ---
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.06),
//                     blurRadius: 12,
//                     offset: const Offset(0, -4),
//                   ),
//                 ],
//               ),
//               child: SafeArea(
//                 top: false,
//                 child: SizedBox(
//                   height: 54,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _onLoginPressed,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryRed,
//                       disabledBackgroundColor: primaryRed.withOpacity(0.6),
//                       elevation: 4,
//                       shadowColor: primaryRed.withOpacity(0.4),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                       height: 22,
//                       width: 22,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2.5,
//                       ),
//                     )
//                         : const Text(
//                       'Login',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTab(String label, bool isLoginTabValue) {
//     final bool isActive = _isLoginTab == isLoginTabValue;
//
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => _isLoginTab = isLoginTabValue),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeInOut,
//           height: double.infinity,
//           decoration: BoxDecoration(
//             color: isActive ? primaryRed : Colors.transparent,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: isActive
//                 ? [
//               BoxShadow(
//                 color: primaryRed.withOpacity(0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3),
//               ),
//             ]
//                 : null,
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             label,
//             style: TextStyle(
//               color: isActive ? Colors.white : textGrey,
//               fontWeight: FontWeight.w700,
//               fontSize: 14,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }










import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/SignupScreen/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final bool _isLoginTab = true; // True for Login screen
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const Color primaryRed = Color(0xFFE53935);
  static const Color lightPink = Color(0xFFFFF5F5);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    setState(() => _isLoading = true);

    // TODO: Wire to Auth Riverpod Controller / UseCase
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // void _onTabTapped(bool isLogin) {
  //   if (!isLogin) {
  //     // Navigate to SignUpScreen without stacking multiple routes
  //     Navigator.pushReplacement(
  //       context,
  //       PageRouteBuilder(
  //         pageBuilder: (context, anim1, anim2) => const SignUpScreen(),
  //         transitionDuration: Duration.zero, // Instant or smooth fade switch
  //       ),
  //     );
  //   }
  // }














  void _onTabTapped(bool isLogin) {
    if (!isLogin) {
      context.push('/signup');
      // Use context.push (not go) so back navigation returns to Login,
      // matching the "tab switch" feel rather than replacing history.
    }
  }













  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Scrollable form content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    // --- Logo / Illustration ---
                    Center(
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'lib/core/constants/assets/animations/blood_donation_02.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                            Icons.bloodtype,
                            size: 96,
                            color: primaryRed,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Center(
                      child: Text(
                        'BLOOD-BRIDGE',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: textDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Login / Sign Up Toggle ---
                    Container(
                      height: 52,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: lightPink,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE0E0)),
                      ),
                      child: Row(
                        children: [
                          _buildTab('Login', true),
                          _buildTab('Sign Up', false),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Email / Mobile field ---
                    const Text(
                      'E-mail ID / Mobile number',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter your E-mail ID / Mobile number',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA0AEC0),
                          fontSize: 13,
                        ),
                        suffixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFFA0AEC0),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryRed, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // --- Password field ---
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA0AEC0),
                          fontSize: 13,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFFA0AEC0),
                            size: 20,
                          ),
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryRed, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: navigate to forgot password flow
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: primaryRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- Biometric login ---
                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(40),
                            onTap: () {
                              // TODO: trigger biometric auth
                            },
                            child: Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: lightPink,
                                border: Border.all(
                                  color: primaryRed.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.fingerprint,
                                color: primaryRed,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please scan your face or fingerprint',
                            style: TextStyle(color: textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // --- Bottom Login button ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onLoginPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      disabledBackgroundColor: primaryRed.withOpacity(0.6),
                      elevation: 4,
                      shadowColor: primaryRed.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isLoginTabValue) {
    final bool isActive = _isLoginTab == isLoginTabValue;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(isLoginTabValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: primaryRed.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : textGrey,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}