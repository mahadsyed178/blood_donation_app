import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/RoleSelection/BloodDonorScreen/blood_donor.dart';
import 'package:flutter/material.dart';
import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/LoginScreen/login_screen.dart';
import 'package:go_router/go_router.dart';
// Adjust path if needed

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final bool _isLoginTab = false; // False indicates Sign Up tab is active
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasAcceptedConsent = false;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailMobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const Color primaryRed = Color(0xFFE53935);
  static const Color lightPink = Color(0xFFFFF5F5);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);

  @override
  void dispose() {
    _nameController.dispose();
    _emailMobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // void _onTabTapped(bool isLogin) {
  //   if (isLogin) {
  //     // Switch back to LoginScreen
  //     Navigator.pushReplacement(
  //       context,
  //       PageRouteBuilder(
  //         pageBuilder: (context, anim1, anim2) => const LoginScreen(),
  //         transitionDuration: Duration.zero,
  //       ),
  //     );
  //   }
  //
  void _onTabTapped(bool isLoginTabValue) {
    // isLoginTabValue = the tab that was tapped (true = Login, false = Sign Up)
    if (isLoginTabValue) {
      context.go('/login');
    } else {
      context.go('/signup');
    }
  }
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onSignUpPressed() async {
    // 1. Validation checks
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter your full name');
      return;
    }

    if (_emailMobileController.text.trim().isEmpty) {
      _showSnack('Please enter your email or mobile number');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnack('Please create a password');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match');
      return;
    }

    if (!_hasAcceptedConsent) {
      _showSnack('Please accept the Terms of Service & Privacy Policy');
      return;
    }

    setState(() => _isLoading = true);

    // 2. Simulated authentication / setup delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 3. Navigate to RoleBasedRegistrationScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleBasedRegistrationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Scrollable Form Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    // --- Logo Header ---
                    Center(
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'lib/core/constants/assets/animations/blood_donation_02.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                            Icons.bloodtype,
                            size: 80,
                            color: primaryRed,
                          ),
                        ),
                      ),
                    ),

                    const Center(
                      child: Text(
                        'BLOOD-BRIDGE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: textDark,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Toggle Bar ---
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

                    const SizedBox(height: 20),

                    // --- Full Name ---
                    _buildLabel('Full Name'),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration(
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- Email / Mobile ---
                    _buildLabel('E-mail ID / Mobile number'),
                    TextField(
                      controller: _emailMobileController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration(
                        hint: 'Enter E-mail ID / Mobile number',
                        icon: Icons.phone_android_outlined,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- Password ---
                    _buildLabel('Password'),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration(
                        hint: 'Create password',
                        suffix: IconButton(
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
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- Confirm Password ---
                    _buildLabel('Confirm Password'),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(fontSize: 14),
                      decoration: _buildInputDecoration(
                        hint: 'Re-enter password',
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFFA0AEC0),
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                          _obscureConfirmPassword =
                          !_obscureConfirmPassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- Privacy Consent Checkbox (FR-02) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _hasAcceptedConsent,
                            activeColor: primaryRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) => setState(
                                    () => _hasAcceptedConsent = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'I agree to the Terms of Service & Privacy Policy for blood response coordination.',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- Bottom Continue Button ---
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
                    onPressed: _isLoading ? null : _onSignUpPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
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
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue to Role Selection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA0AEC0),
        fontSize: 13,
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFFA0AEC0), size: 20)
          : null,
      suffixIcon: suffix,
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