import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/geo/location_draft_provider.dart';
import '../../../core/models/blood_request.dart';
import '../../../core/models/enums.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/map/approximate_location_map.dart';
import '../../DonorMatching/presentation/donor_matching_screen.dart';
import '../state/blood_request_providers.dart';

/// `POST /blood-requests`. Every field validates inline; the submit button
/// stays disabled until the form is complete, and stays busy through the
/// request so a retry can't double-post.
class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  static const _maxUnits = 20; // backend MAX_UNITS
  static const _draftKey = 'request-location';

  final _formKey = GlobalKey<FormState>();
  final _patientController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');
  final _hospitalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();

  BloodType? _bloodType;
  UrgencyLevel _urgency = UrgencyLevel.urgent;
  DateTime _requiredBy = DateTime.now().add(const Duration(hours: 6));
  PickedLocation? _location;
  bool _busy = false;
  bool _submittedOnce = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    final phone = ref.read(currentUserProvider)?.phone;
    if (phone != null) _phoneController.text = phone;
    // A pick that survived a backgrounded app.
    final draft = ref.read(locationDraftProvider.notifier).of(_draftKey);
    if (draft != null && draft.isValid) {
      _location = draft;
      if (draft.displayAddress != null) _areaController.text = draft.displayAddress!;
    }
    for (final c in [_patientController, _unitsController, _hospitalController, _phoneController, _areaController]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _patientController.dispose();
    _unitsController.dispose();
    _hospitalController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // --- validators ------------------------------------------------------------

  String? _validatePatient(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Patient name is required';
    if (t.length > 120) return 'At most 120 characters';
    return null;
  }

  String? _validateUnits(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter how many units';
    final n = int.tryParse(t);
    if (n == null) return 'Whole numbers only';
    if (n < 1) return 'At least 1 unit';
    if (n > _maxUnits) return 'At most $_maxUnits units per request';
    return null;
  }

  String? _validateArea(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Describe the area, e.g. Gulshan, Karachi';
    if (t.length > 120) return 'At most 120 characters';
    return null;
  }

  String? get _dateError => _requiredBy.isAfter(DateTime.now()) ? null : 'Must be in the future';
  String? get _locationError =>
      _location == null ? 'Pin the patient’s location' : (!_location!.isValid ? 'Invalid location — pick again' : null);
  String? get _bloodError => _bloodType == null ? 'Select the blood group needed' : null;

  bool get _isValid =>
      _validatePatient(_patientController.text) == null &&
      _validateUnits(_unitsController.text) == null &&
      validatePhone(_phoneController.text) == null &&
      _validateArea(_areaController.text) == null &&
      _hospitalController.text.trim().length <= 120 &&
      _dateError == null &&
      _locationError == null &&
      _bloodError == null;

  // --- pickers ---------------------------------------------------------------

  Future<void> _pickRequiredBy() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _requiredBy.isAfter(DateTime.now()) ? _requiredBy : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'When is the blood needed by?',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_requiredBy));
    if (time == null) return;
    setState(() => _requiredBy = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _pickLocation() async {
    final picked = await context.push<PickedLocation>(
      AppRoutes.locationPicker,
      extra: LocationPickerMode.pick,
    );
    if (picked == null || !mounted) return;
    if (!picked.isValid) {
      showSnack(context, 'That location is invalid — please pick again.', isError: true);
      return;
    }
    setState(() {
      _location = picked;
      if (_areaController.text.trim().isEmpty && (picked.displayAddress?.isNotEmpty ?? false)) {
        _areaController.text = picked.displayAddress!;
      }
    });
  }

  // --- submit ---------------------------------------------------------------

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submittedOnce = true;
      _fieldErrors = const {};
    });
    final formOk = _formKey.currentState!.validate();
    if (!formOk || !_isValid) {
      showSnack(context, _bloodError ?? _locationError ?? _dateError ?? 'Please fix the highlighted fields', isError: true);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final created = await ref.read(myRequestsProvider.notifier).create(BloodRequestCreate(
            patientName: _patientController.text.trim(),
            bloodTypeNeeded: _bloodType!,
            unitsNeeded: int.parse(_unitsController.text.trim()),
            urgencyLevel: _urgency,
            requiredBy: _requiredBy,
            hospitalName: _hospitalController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            latitude: _location!.latitude,
            longitude: _location!.longitude,
            areaLabel: _areaController.text.trim(),
          ));
      if (!mounted) return;
      ref.read(locationDraftProvider.notifier).clear(_draftKey);
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

  // --- UI -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final autovalidate = _submittedOnce ? AutovalidateMode.always : AutovalidateMode.onUserInteraction;
    final radiusKm = switch (_urgency) {
      UrgencyLevel.critical => 25,
      UrgencyLevel.urgent => 15,
      UrgencyLevel.routine => 8,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('New blood request')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xxl),
                child: Form(
                  key: _formKey,
                  autovalidateMode: autovalidate,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('Patient name'),
                      TextFormField(
                        controller: _patientController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: 120,
                        validator: _validatePatient,
                        decoration: _decor('Who needs the blood', Icons.person_outline, 'patient_name')
                            .copyWith(counterText: _counter(_patientController.text.length, 120)),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _label('Blood group needed'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: BloodType.values
                            .map((b) => ChoiceChip(
                                  label: Text(b.label),
                                  selected: _bloodType == b,
                                  labelStyle: TextStyle(
                                    color: _bloodType == b ? Colors.white : AppColors.textDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  onSelected: (_) => setState(() => _bloodType = b),
                                ))
                            .toList(),
                      ),
                      _inlineError(_submittedOnce ? (_fieldErrors['blood_type_needed'] ?? _bloodError) : _fieldErrors['blood_type_needed']),
                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Units needed'),
                                TextFormField(
                                  controller: _unitsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                                  textInputAction: TextInputAction.next,
                                  validator: _validateUnits,
                                  decoration: _decor('1–$_maxUnits', Icons.water_drop_outlined, 'units_needed'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Urgency'),
                                DropdownButtonFormField<UrgencyLevel>(
                                  initialValue: _urgency,
                                  isExpanded: true,
                                  decoration: _decor('Urgency', null, 'urgency_level'),
                                  items: UrgencyLevel.values
                                      .map((u) => DropdownMenuItem(
                                            value: u,
                                            child: Row(
                                              children: [
                                                Icon(Icons.circle, size: 10, color: AppColors.urgency(u.apiValue)),
                                                const SizedBox(width: 8),
                                                Text(u.label, style: const TextStyle(fontSize: 14)),
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
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Donors within $radiusKm km are notified first; the radius widens automatically if nobody responds.',
                        style: AppText.caption,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _label('Required by'),
                      InkWell(
                        borderRadius: AppRadius.lgAll,
                        onTap: _pickRequiredBy,
                        child: InputDecorator(
                          decoration: _decor('Required by', Icons.event_outlined, 'required_by').copyWith(
                            errorText: _fieldErrors['required_by'] ?? (_submittedOnce ? _dateError : null),
                            suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 18),
                          ),
                          child: Text(
                            '${formatDateTime(_requiredBy)}  (${untilLabel(_requiredBy)})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _label('Hospital (optional)'),
                      TextFormField(
                        controller: _hospitalController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: 120,
                        validator: (v) => (v ?? '').trim().length > 120 ? 'At most 120 characters' : null,
                        decoration: _decor('Exact registered name for verification', Icons.local_hospital_outlined, 'hospital_name')
                            .copyWith(counterText: _counter(_hospitalController.text.length, 120)),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'If this matches a registered hospital, the request is hospital-backed and reaches donors only after the hospital verifies it.',
                        style: AppText.caption,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _label('Contact phone'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'))],
                        textInputAction: TextInputAction.next,
                        validator: validatePhone,
                        decoration: _decor('Number donors can call', Icons.phone_outlined, 'contact_phone'),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _label('Location'),
                      _LocationField(
                        location: _location,
                        error: _submittedOnce ? _locationError : null,
                        onTap: _pickLocation,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _areaController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        maxLength: 120,
                        validator: _validateArea,
                        onFieldSubmitted: (_) => _isValid && !_busy ? _submit() : null,
                        decoration: _decor('Area label shown to donors', Icons.map_outlined, 'area_label')
                            .copyWith(counterText: _counter(_areaController.text.length, 120)),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Donors see this label and a ~500 m circle — never the exact pin.',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            BottomActionBar(
              child: AppButton(
                label: _isValid ? 'Post request' : 'Complete the form to post',
                icon: Icons.send_rounded,
                enabled: _isValid,
                busy: _busy,
                height: 54,
                onPressed: _isValid ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decor(String hint, IconData? icon, String field) =>
      appInputDecoration(hint: hint, icon: icon, errorText: _fieldErrors[field]);

  /// Show the counter only when the user is near the limit.
  String? _counter(int length, int max) => length >= max * 0.8 ? '$length / $max' : '';

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text, style: AppText.label),
      );

  Widget _inlineError(String? error) => AnimatedSize(
        duration: AppDurations.fast,
        child: error == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(error, style: const TextStyle(color: AppColors.critical, fontSize: 11)),
              ),
      );
}

class _LocationField extends StatelessWidget {
  final PickedLocation? location;
  final String? error;
  final VoidCallback onTap;
  const _LocationField({required this.location, required this.error, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = location;
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.normal,
            decoration: BoxDecoration(
              color: l == null ? AppColors.bgGrey : AppColors.successBg,
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                color: hasError
                    ? AppColors.critical
                    : l == null
                        ? AppColors.borderGrey
                        : AppColors.successGreen.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                if (l != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                    child: IgnorePointer(
                      child: ApproximateLocationMap(point: l.latLng, exact: true, height: 120),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        l == null ? Icons.add_location_alt_outlined : Icons.place_rounded,
                        color: l == null ? AppColors.textGrey : AppColors.successGreen,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l == null
                              ? 'Pin the patient’s location on the map'
                              : (l.displayAddress ?? 'Location pinned — tap to adjust'),
                          style: AppText.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(l == null ? 'Pick' : 'Change',
                          style: AppText.label.copyWith(color: AppColors.primaryRed)),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(error!, style: const TextStyle(color: AppColors.critical, fontSize: 11)),
          ),
      ],
    );
  }
}
