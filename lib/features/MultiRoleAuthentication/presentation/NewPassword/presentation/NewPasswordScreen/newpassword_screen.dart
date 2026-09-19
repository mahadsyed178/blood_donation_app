import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/models/enums.dart';
import '../../../../../../core/providers/core_providers.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/feedback.dart';

/// `POST /{donors|requestors}/reset-password` with the token from the reset
/// e-mail. The token is a JWT; the role it was issued for must match.
class CreateNewPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  const CreateNewPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends ConsumerState<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _role = UserRole.donor;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  bool get _isValid =>
      _tokenController.text.trim().isNotEmpty &&
      validatePassword(_newPasswordController.text) == null &&
      _confirmPasswordController.text == _newPasswordController.text;

  @override
  void initState() {
    super.initState();
    for (final c in [_tokenController, _newPasswordController, _confirmPasswordController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onResetPasswordPressed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            _role,
            _tokenController.text.trim(),
            _newPasswordController.text,
          );
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Password Updated!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your password has been reset successfully. Please log in with your new credentials.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go(AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 280),
                          padding: const EdgeInsets.all(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'lib/core/constants/assets/images/images (3).png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.password_rounded,
                                size: 72,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create New Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.initialEmail != null
                            ? 'We sent a reset link to ${widget.initialEmail}. Paste the token from it below.'
                            : 'Paste the token from your reset e-mail and choose a new password.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.textGrey, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      _label('Account type'),
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment(value: UserRole.donor, label: Text('Donor')),
                          ButtonSegment(value: UserRole.requestor, label: Text('Requester')),
                        ],
                        selected: {_role},
                        onSelectionChanged: (s) => setState(() => _role = s.first),
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: AppColors.primaryRed,
                          selectedForegroundColor: Colors.white,
                          foregroundColor: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Reset token'),
                      TextFormField(
                        controller: _tokenController,
                        maxLines: 3,
                        minLines: 1,
                        autocorrect: false,
                        style: const TextStyle(fontSize: 12.5, fontFamily: 'monospace'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Paste the token from your e-mail' : null,
                        decoration: appInputDecoration(
                          hint: 'eyJhbGciOi…',
                          icon: Icons.vpn_key_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('New Password'),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        validator: validatePassword,
                        style: const TextStyle(fontSize: 14),
                        decoration: appInputDecoration(
                          hint: 'Min 8 chars, a letter and a digit',
                          suffix: IconButton(
                            tooltip: _obscureNew ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.hintGrey,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Confirm Password'),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        validator: (v) =>
                            v != _newPasswordController.text ? 'Passwords do not match' : null,
                        style: const TextStyle(fontSize: 14),
                        decoration: appInputDecoration(
                          hint: 'Re-enter new password',
                          suffix: IconButton(
                            tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.hintGrey,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            BottomActionBar(
              child: AppButton(
                label: 'Reset password',
                icon: Icons.lock_reset_rounded,
                height: 54,
                enabled: _isValid,
                busy: _isLoading,
                onPressed: _isValid ? _onResetPasswordPressed : null,
              ),
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
      );
}
