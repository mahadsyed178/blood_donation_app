import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/accounts.dart';
import '../../../core/models/enums.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/feedback.dart';

/// `PATCH /donors/me` / `PATCH /requestors/me`, plus account deletion.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _nid;
  late final TextEditingController _weight;
  BloodType? _bloodType;
  Gender? _gender;
  DateTime? _dob;
  DateTime? _lastDonation;
  AvailableTime? _availableTime;
  bool _busy = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final donor = user?.donor;
    _name = TextEditingController(text: user?.displayName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _nid = TextEditingController(text: donor?.nationalId ?? '');
    _weight = TextEditingController(text: donor?.weightKg?.toStringAsFixed(0) ?? '');
    _bloodType = donor?.bloodType;
    _gender = donor?.gender;
    _dob = donor?.dateOfBirth;
    _lastDonation = donor?.lastDonationDate;
    _availableTime = donor?.availableTime;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _nid.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final auth = ref.read(authProvider.notifier);
      if (user.role == UserRole.donor) {
        final w = _weight.text.trim();
        final updated = await ref.read(donorRepositoryProvider).updateProfile(DonorProfileUpdate(
              fullName: _name.text.trim(),
              phone: _phone.text.trim(),
              bloodType: _bloodType,
              gender: _gender,
              dateOfBirth: _dob,
              nationalId: _nid.text.trim().isEmpty ? null : _nid.text.trim(),
              weightKg: w.isEmpty ? null : double.tryParse(w),
              lastDonationDate: _lastDonation,
              availableTime: _availableTime,
            ));
        auth.updateDonor(updated);
      } else {
        final updated = await ref.read(requestorRepositoryProvider).updateProfile(
              RequestorProfileUpdate(fullName: _name.text.trim(), phone: _phone.text.trim()),
            );
        auth.updateRequestor(updated);
      }
      if (!mounted) return;
      showSnack(context, 'Profile updated');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _fieldErrors = e.fieldErrors);
      showSnack(context, e.message, isError: true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final ok = await confirmDialog(context,
        title: 'Delete your account?',
        message: 'This permanently removes your account and cannot be undone.',
        confirmLabel: 'Delete',
        destructive: true);
    if (!ok) return;
    setState(() => _busy = true);
    try {
      if (user.role == UserRole.donor) {
        await ref.read(donorRepositoryProvider).deleteAccount();
      } else {
        await ref.read(requestorRepositoryProvider).deleteAccount();
      }
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate(DateTime? initial, ValueChanged<DateTime> onPicked,
      {DateTime? first, DateTime? last}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? last ?? DateTime.now(),
      firstDate: first ?? DateTime(1900),
      lastDate: last ?? DateTime.now(),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final isDonor = user.role == UserRole.donor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.lightPink,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.pinkBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, color: AppColors.primaryRed),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(user.email,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            Chip2(
                              label: user.role.label,
                              color: AppColors.primaryRed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _label('Full name'),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Name is required' : null,
                        decoration: appInputDecoration(
                            hint: 'Full name', icon: Icons.person_outline, errorText: _fieldErrors['full_name']),
                      ),
                      const SizedBox(height: 14),
                      _label('Mobile number'),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        validator: validatePhone,
                        decoration: appInputDecoration(
                            hint: 'Mobile', icon: Icons.phone_android_outlined, errorText: _fieldErrors['phone']),
                      ),
                      if (isDonor) ...[
                        const SizedBox(height: 14),
                        _label('Blood group'),
                        DropdownButtonFormField<BloodType>(
                          initialValue: _bloodType,
                          decoration: appInputDecoration(hint: 'Blood group', errorText: _fieldErrors['blood_type']),
                          items: BloodType.values
                              .map((b) => DropdownMenuItem(value: b, child: Text(b.label)))
                              .toList(),
                          onChanged: (v) => setState(() => _bloodType = v),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Gender'),
                                  DropdownButtonFormField<Gender>(
                                    initialValue: _gender,
                                    decoration: appInputDecoration(hint: 'Gender', errorText: _fieldErrors['gender']),
                                    items: Gender.values
                                        .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _gender = v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Date of birth'),
                                  InkWell(
                                    onTap: () => _pickDate(_dob, (d) => setState(() => _dob = d),
                                        first: DateTime(DateTime.now().year - 65),
                                        last: DateTime.now().subtract(const Duration(days: 365 * 18))),
                                    child: InputDecorator(
                                      decoration: appInputDecoration(
                                          hint: 'DOB', errorText: _fieldErrors['date_of_birth']),
                                      isEmpty: _dob == null,
                                      child: Text(_dob == null ? '' : formatDate(_dob!)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _label('National ID'),
                        TextFormField(
                          controller: _nid,
                          decoration: appInputDecoration(
                              hint: 'NID (optional)', icon: Icons.badge_outlined, errorText: _fieldErrors['national_id']),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Weight (kg)'),
                                  TextFormField(
                                    controller: _weight,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (v) {
                                      final t = (v ?? '').trim();
                                      if (t.isEmpty) return null;
                                      final w = double.tryParse(t);
                                      if (w == null || w < 30 || w > 300) return '30–300 kg';
                                      return null;
                                    },
                                    decoration: appInputDecoration(hint: 'Weight', errorText: _fieldErrors['weight_kg']),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Available time'),
                                  DropdownButtonFormField<AvailableTime>(
                                    initialValue: _availableTime,
                                    decoration: appInputDecoration(hint: 'Any', errorText: _fieldErrors['available_time']),
                                    items: AvailableTime.values
                                        .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _availableTime = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _label('Last donation date'),
                        InkWell(
                          onTap: () => _pickDate(_lastDonation, (d) => setState(() => _lastDonation = d)),
                          child: InputDecorator(
                            decoration: appInputDecoration(
                                hint: 'Not recorded', errorText: _fieldErrors['last_donation_date']),
                            isEmpty: _lastDonation == null,
                            child: Text(_lastDonation == null ? '' : formatDate(_lastDonation!)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      TextButton.icon(
                        onPressed: _busy ? null : _deleteAccount,
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.primaryRed),
                        label: const Text('Delete my account',
                            style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Save Changes',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      );
}

