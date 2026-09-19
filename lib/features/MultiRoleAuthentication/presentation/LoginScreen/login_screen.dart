import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback.dart';

/// Email + password login. The backend has one login endpoint per account
/// type, so the user picks which kind of account they hold.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _role = UserRole.donor;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).login(
            _role,
            _emailController.text.trim(),
            _passwordController.text,
          );
      // The router's redirect moves an authenticated user to /dashboard.
      if (mounted) context.go(AppRoutes.dashboard);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.message);
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 320),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'lib/core/constants/assets/animations/blood_donation_02.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.bloodtype,
                              size: 96,
                              color: AppColors.primaryRed,
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
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _AuthTabs(isLogin: true, onSignupTap: () => context.go(AppRoutes.signup)),
                      const SizedBox(height: 20),

                      _label('I am a'),
                      _RolePicker(value: _role, onChanged: (r) => setState(() => _role = r)),
                      const SizedBox(height: 16),

                      _label('E-mail'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 14),
                        validator: validateEmail,
                        decoration: appInputDecoration(
                          hint: 'Enter your e-mail',
                          suffix: const Icon(Icons.email_outlined,
                              color: AppColors.hintGrey, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Password'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _isLoading ? null : _onLoginPressed(),
                        style: const TextStyle(fontSize: 14),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Password is required' : null,
                        decoration: appInputDecoration(
                          hint: 'Password',
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.hintGrey,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push(AppRoutes.forgotPassword),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.primaryRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      if (_formError != null) ...[
                        const SizedBox(height: 12),
                        _ErrorBanner(message: _formError!),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            _BottomButton(
              isLoading: _isLoading,
              label: 'Login',
              onPressed: _onLoginPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      );
}

/// Login / Sign Up switcher shared by both auth screens.
class _AuthTabs extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onSignupTap;
  const _AuthTabs({required this.isLogin, required this.onSignupTap});

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool active, VoidCallback? onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: double.infinity,
              decoration: BoxDecoration(
                color: active ? AppColors.primaryRed : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primaryRed.withValues(alpha: 0.3),
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
                  color: active ? Colors.white : AppColors.textGrey,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pinkBorder),
      ),
      child: Row(
        children: [
          tab('Login', isLogin, null),
          tab('Sign Up', !isLogin, onSignupTap),
        ],
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  final UserRole value;
  final ValueChanged<UserRole> onChanged;
  const _RolePicker({required this.value, required this.onChanged});

  static const _icons = {
    UserRole.donor: Icons.volunteer_activism_rounded,
    UserRole.requestor: Icons.bloodtype_rounded,
    UserRole.hospital: Icons.local_hospital_rounded,
    UserRole.organization: Icons.inventory_2_rounded,
    UserRole.admin: Icons.admin_panel_settings_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: UserRole.values.map((role) {
        final active = role == value;
        return ChoiceChip(
          selected: active,
          onSelected: (_) => onChanged(role),
          avatar: Icon(_icons[role], size: 16,
              color: active ? Colors.white : AppColors.primaryRed),
          label: Text(role.label),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textDark,
          ),
          selectedColor: AppColors.primaryRed,
          backgroundColor: AppColors.bgGrey,
          showCheckmark: false,
          side: BorderSide(color: active ? AppColors.primaryRed : AppColors.borderGrey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      }).toList(),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightPink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.primaryRed, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 12.5)),
            ),
          ],
        ),
      );
}

/// Sticky bottom CTA used across the auth flow.
class _BottomButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onPressed;
  const _BottomButton({required this.isLoading, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
                elevation: 4,
                shadowColor: AppColors.primaryRed.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      );
}
