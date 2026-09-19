import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/accounts.dart';
import '../../../../../core/models/enums.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../state/signup_draft.dart';

/// Step 2 of signup: pick Donor or Requester and fill the fields that role
/// needs, then `POST /donors/signup` or `POST /requestors/signup` and log in.
///
/// Hospital and organization accounts are provisioned outside the app.
class RoleBasedRegistrationScreen extends ConsumerStatefulWidget {
  final SignupDraft? draft;
  const RoleBasedRegistrationScreen({super.key, this.draft});

  @override
  ConsumerState<RoleBasedRegistrationScreen> createState() =>
      _RoleBasedRegistrationScreenState();
}

enum _SignupRole { donor, requester }

class _RoleBasedRegistrationScreenState
    extends ConsumerState<RoleBasedRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  _SignupRole _selectedRole = _SignupRole.donor;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  Map<String, String> _fieldErrors = const {};

  final _mobileController = TextEditingController();
  final _nidController = TextEditingController();
  final _weightController = TextEditingController();

  Gender? _gender;
  DateTime? _dateOfBirth;
  BloodType? _bloodType;
  DateTime? _lastDonationDate;
  AvailableTime? _availableTime;

  @override
  void initState() {
    super.initState();
    if (widget.draft == null) {
      // Deep link / restart without step 1: send them back for credentials.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.signup);
      });
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _nidController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? (lastDate != null && lastDate.isBefore(now) ? lastDate : now),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryRed),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  bool _validateExtraFields() {
    if (_selectedRole == _SignupRole.donor) {
      if (_gender == null) return _fail('Please select your gender');
      if (_dateOfBirth == null) return _fail('Please select your date of birth');
      if (_bloodType == null) return _fail('Please select your blood group');
    }
    if (!_agreedToTerms) return _fail('Please agree to the consent checkbox to continue');
    return true;
  }

  bool _fail(String message) {
    showSnack(context, message, isError: true);
    return false;
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    setState(() => _fieldErrors = const {});
    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid || !_validateExtraFields()) return;

    final draft = widget.draft!;
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authProvider.notifier);
      if (_selectedRole == _SignupRole.donor) {
        final weightText = _weightController.text.trim();
        await auth.signupDonor(DonorSignupRequest(
          fullName: draft.fullName,
          email: draft.email,
          password: draft.password,
          phone: _mobileController.text.trim(),
          bloodType: _bloodType!,
          gender: _gender!,
          dateOfBirth: _dateOfBirth!,
          nationalId: _nidController.text.trim().isEmpty ? null : _nidController.text.trim(),
          weightKg: weightText.isEmpty ? null : double.tryParse(weightText),
          lastDonationDate: _lastDonationDate,
          availableTime: _availableTime,
        ));
      } else {
        await auth.signupRequestor(RequestorSignupRequest(
          fullName: draft.fullName,
          email: draft.email,
          password: draft.password,
          phone: _mobileController.text.trim(),
        ));
      }
      if (!mounted) return;
      showSnack(context, 'Welcome to BloodBridge, ${draft.fullName}!');
      context.go(AppRoutes.dashboard);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _fieldErrors = e.fieldErrors);
      // Email/password errors belong to step 1 — say so explicitly.
      final stepOne = e.fieldErrors.keys.any((k) => k == 'email' || k == 'password' || k == 'full_name');
      showSnack(
        context,
        stepOne ? '${e.message}\nGo back to fix your account details.' : e.message,
        isError: true,
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDonor = _selectedRole == _SignupRole.donor;
    final draft = widget.draft;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: const Text('Choose your role',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      if (draft != null) _AccountSummary(draft: draft),
                      const SizedBox(height: 20),
                      _buildRoleToggle(),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 14),
                        validator: validatePhone,
                        decoration: _decoration('Mobile Number', error: _fieldErrors['phone'])
                            .copyWith(prefixIcon: const Icon(Icons.phone_android_outlined,
                                color: AppColors.hintGrey, size: 20)),
                      ),
                      const SizedBox(height: 20),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: isDonor
                            ? _buildDonorFields()
                            : const _RequesterNote(key: ValueKey('req')),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _agreedToTerms,
                              activeColor: AppColors.primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (value) =>
                                  setState(() => _agreedToTerms = value ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                isDonor
                                    ? 'I voluntarily consent to donate blood and agree to any necessary medical checks before donation.'
                                    : 'I confirm my requests will be genuine and understand that final donor eligibility is decided by qualified medical staff.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(isDonor),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorFields() {
    return Column(
      key: const ValueKey('donor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<Gender>(
                initialValue: _gender,
                isExpanded: true,
                decoration: _decoration('Gender', error: _fieldErrors['gender']),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
                items: Gender.values
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.label, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: 'Date of Birth',
                value: _dateOfBirth,
                error: _fieldErrors['date_of_birth'],
                onTap: () => _pickDate(
                  initialDate: _dateOfBirth,
                  // Backend: 18–65 years old.
                  firstDate: DateTime(DateTime.now().year - 65),
                  lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                  onPicked: (d) => setState(() => _dateOfBirth = d),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<BloodType>(
                initialValue: _bloodType,
                isExpanded: true,
                decoration: _decoration('Blood Group', error: _fieldErrors['blood_type']),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
                items: BloodType.values
                    .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.label, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _nidController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 14),
                maxLength: 30,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                decoration: _decoration('NID (optional)', error: _fieldErrors['national_id']),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Last Donation (optional)',
                value: _lastDonationDate,
                error: _fieldErrors['last_donation_date'],
                onTap: () => _pickDate(
                  initialDate: _lastDonationDate,
                  onPicked: (d) => setState(() => _lastDonationDate = d),
                ),
                onClear: _lastDonationDate == null
                    ? null
                    : () => setState(() => _lastDonationDate = null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<AvailableTime>(
                initialValue: _availableTime,
                isExpanded: true,
                decoration: _decoration('Available Time', error: _fieldErrors['available_time']),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
                items: AvailableTime.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _availableTime = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 14),
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return null;
            final w = double.tryParse(t);
            if (w == null) return 'Enter a number';
            if (w < 30 || w > 300) return 'Between 30 and 300 kg';
            return null;
          },
          decoration: _decoration('Weight in kg (optional)', error: _fieldErrors['weight_kg'])
              .copyWith(suffixText: 'kg'),
        ),
      ],
    );
  }

  Widget _buildRoleToggle() {
    Widget tab(String label, _SignupRole role) {
      final bool isActive = _selectedRole == role;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedRole = role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryRed : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textGrey,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pinkBorder),
      ),
      child: Row(
        children: [
          tab('I WANT TO\nDONATE BLOOD', _SignupRole.donor),
          const SizedBox(width: 6),
          tab('I NEED\nBLOOD', _SignupRole.requester),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDonor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
                  elevation: 4,
                  shadowColor: AppColors.primaryRed.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isDonor ? 'Become a Donor' : 'Create Requester Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, {String? error}) =>
      appInputDecoration(hint: hint, errorText: error);
}

class _AccountSummary extends StatelessWidget {
  final SignupDraft draft;
  const _AccountSummary({required this.draft});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightPink,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.pinkBorder),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.25), width: 1.5),
              ),
              child: const Icon(Icons.person_outline, color: AppColors.primaryRed, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(draft.email,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Edit', style: TextStyle(color: AppColors.primaryRed)),
            ),
          ],
        ),
      );
}

class _RequesterNote extends StatelessWidget {
  const _RequesterNote({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryRed),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Once your account is ready you can post blood requests with the patient, blood group, units and urgency — and track every donor who responds.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.4),
              ),
            ),
          ],
        ),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String? error;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: InputDecorator(
          decoration: appInputDecoration(hint: label, errorText: error).copyWith(
            suffixIcon: onClear != null
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textGrey),
                    onPressed: onClear,
                  )
                : const Icon(Icons.calendar_today_outlined, color: AppColors.textGrey, size: 18),
          ),
          isEmpty: value == null,
          child: Text(
            value == null ? '' : formatDate(value!),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
}
