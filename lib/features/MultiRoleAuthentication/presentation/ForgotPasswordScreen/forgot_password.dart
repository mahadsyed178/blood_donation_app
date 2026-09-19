import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/feedback.dart';

/// `POST /{donors|requestors}/forgot-password`. The backend emails a reset
/// link containing a token; the next screen takes that token.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  UserRole _role = UserRole.donor;
  bool _isLoading = false;

  bool get _isValid => validateEmail(_emailController.text) == null;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendPressed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);
    try {
      final message = await ref.read(authRepositoryProvider).forgotPassword(_role, email);
      if (!mounted) return;
      showSnack(context, message);
      context.push(AppRoutes.newPassword, extra: email);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                          height: 180,
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 280),
                          padding: const EdgeInsets.all(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'lib/core/constants/assets/images/images (2).png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.lock_reset_rounded,
                                size: 72,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Forgot Password?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Enter your registered e-mail and we’ll send you a reset link. Paste the token from that link on the next screen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: AppColors.textGrey, height: 1.5),
                      ),
                      const SizedBox(height: 28),

                      const Text('Account type',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment(
                            value: UserRole.donor,
                            label: Text('Donor'),
                            icon: Icon(Icons.volunteer_activism_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: UserRole.requestor,
                            label: Text('Requester'),
                            icon: Icon(Icons.bloodtype_rounded, size: 16),
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (s) => setState(() => _role = s.first),
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: AppColors.primaryRed,
                          selectedForegroundColor: Colors.white,
                          foregroundColor: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hospital and organization accounts reset their password through the platform administrator.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 18),

                      const Text('E-mail',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _isLoading ? null : _onSendPressed(),
                        validator: validateEmail,
                        style: const TextStyle(fontSize: 14),
                        decoration: appInputDecoration(
                          hint: 'Enter your registered e-mail',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            BottomActionBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: 'Send reset link',
                    icon: Icons.send_rounded,
                    height: 54,
                    enabled: _isValid,
                    busy: _isLoading,
                    onPressed: _isValid ? _onSendPressed : null,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.newPassword),
                    child: const Text('Already have a reset token?'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
