import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../DonorMatching/presentation/donor_matching_screen.dart';
import '../state/blood_request_providers.dart';

/// `POST /blood-requests`. Naming a registered hospital makes the request
/// hospital-backed: it waits for that hospital's verification before donors
/// are notified. Otherwise it goes live immediately.
class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();

  BloodType? _bloodType;
  int _units = 1;
  UrgencyLevel _urgency = UrgencyLevel.urgent;
  DateTime _requiredBy = DateTime.now().add(const Duration(hours: 6));
  PickedLocation? _location;
  bool _busy = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    final phone = ref.read(currentUserProvider)?.phone;
    if (phone != null) _phoneController.text = phone;
  }

  @override
  void dispose() {
    _patientController.dispose();
    _hospitalController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickRequiredBy() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _requiredBy,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryRed),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_requiredBy),
    );
    if (time == null) return;
    setState(() {
      _requiredBy = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickLocation() async {
    final picked = await context.push<PickedLocation>(
      AppRoutes.locationPicker,
      extra: LocationPickerMode.pick,
    );
    if (picked == null) return;
    setState(() {
      _location = picked;
      if (_areaController.text.trim().isEmpty && picked.label != null) {
        _areaController.text = picked.label!;
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    if (_bloodType == null) return _fail('Select the blood group needed');
    if (_location == null) return _fail('Pin the patient’s location on the map');
    if (!_requiredBy.isAfter(DateTime.now())) return _fail('Required-by must be in the future');

    setState(() => _busy = true);
    try {
      final created = await ref.read(myRequestsProvider.notifier).create(BloodRequestCreate(
            patientName: _patientController.text.trim(),
            bloodTypeNeeded: _bloodType!,
            unitsNeeded: _units,
            urgencyLevel: _urgency,
            requiredBy: _requiredBy,
            hospitalName: _hospitalController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            latitude: _location!.latitude,
            longitude: _location!.longitude,
            areaLabel: _areaController.text.trim(),
          ));
      if (!mounted) return;
      showSnack(
        context,
        created.isHospitalBacked
            ? 'Request submitted — ${created.hospitalNameText} will verify it before donors are notified.'
            : 'Request is live. Compatible donors within ${created.currentRadiusKm.toStringAsFixed(0)} km are being notified.',
      );
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

  void _fail(String m) => showSnack(context, m, isError: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
        title: const Text('New Blood Request',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
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
                      _label('Patient name'),
                      TextFormField(
                        controller: _patientController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Patient name is required' : null,
                        decoration: appInputDecoration(
                          hint: 'Who needs the blood',
                          icon: Icons.person_outline,
                          errorText: _fieldErrors['patient_name'],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Blood group needed'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: BloodType.values
                            .map((b) => ChoiceChip(
                                  label: Text(b.label),
                                  selected: _bloodType == b,
                                  selectedColor: AppColors.primaryRed,
                                  showCheckmark: false,
                                  labelStyle: TextStyle(
                                    color: _bloodType == b ? Colors.white : AppColors.textDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  onSelected: (_) => setState(() => _bloodType = b),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Units needed'),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.bgGrey,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.borderGrey),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed:
                                            _units > 1 ? () => setState(() => _units--) : null,
                                        icon: const Icon(Icons.remove_rounded),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text('$_units',
                                              style: const TextStyle(
                                                  fontSize: 18, fontWeight: FontWeight.w900)),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed:
                                            _units < 20 ? () => setState(() => _units++) : null,
                                        icon: const Icon(Icons.add_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Urgency'),
                                DropdownButtonFormField<UrgencyLevel>(
                                  initialValue: _urgency,
                                  isExpanded: true,
                                  decoration: appInputDecoration(hint: 'Urgency'),
                                  items: UrgencyLevel.values
                                      .map((u) => DropdownMenuItem(
                                            value: u,
                                            child: Row(
                                              children: [
                                                Icon(Icons.circle,
                                                    size: 10,
                                                    color: AppColors.urgency(u.apiValue)),
                                                const SizedBox(width: 8),
                                                Text(u.label,
                                                    style: const TextStyle(fontSize: 14)),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _urgency = v ?? _urgency),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search radius starts at ${switch (_urgency) {
                          UrgencyLevel.critical => 25,
                          UrgencyLevel.urgent => 15,
                          UrgencyLevel.routine => 8,
                        }} km and widens automatically if no donor responds.',
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5),
                      ),
                      const SizedBox(height: 16),

                      _label('Required by'),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _pickRequiredBy,
                        child: InputDecorator(
                          decoration: appInputDecoration(
                            hint: 'Required by',
                            errorText: _fieldErrors['required_by'],
                          ).copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_outlined,
                                color: AppColors.textGrey, size: 18),
                          ),
                          child: Text(
                            '${formatDateTime(_requiredBy)}  (${untilLabel(_requiredBy)})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Hospital (optional)'),
                      TextFormField(
                        controller: _hospitalController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: appInputDecoration(
                          hint: 'Exact registered name for verification',
                          icon: Icons.local_hospital_outlined,
                          errorText: _fieldErrors['hospital_name'],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'If this matches a registered hospital, the request is hospital-backed and goes to donors only after the hospital verifies it.',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 11.5),
                      ),
                      const SizedBox(height: 16),

                      _label('Contact phone'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: validatePhone,
                        decoration: appInputDecoration(
                          hint: 'Number donors can call',
                          icon: Icons.phone_outlined,
                          errorText: _fieldErrors['contact_phone'],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Location'),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _pickLocation,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _location == null ? AppColors.bgGrey : AppColors.successBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _location == null
                                    ? AppColors.borderGrey
                                    : AppColors.successGreen.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _location == null ? Icons.add_location_alt_outlined : Icons.place_rounded,
                                color: _location == null ? AppColors.textGrey : AppColors.successGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _location == null
                                      ? 'Pin the patient’s location on the map'
                                      : 'Pinned: ${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _areaController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Describe the area (e.g. Gulshan, Karachi)' : null,
                        decoration: appInputDecoration(
                          hint: 'Area label shown to donors',
                          icon: Icons.map_outlined,
                          errorText: _fieldErrors['area_label'],
                        ),
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
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
                      elevation: 4,
                      shadowColor: AppColors.primaryRed.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Post Request',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      );
}
