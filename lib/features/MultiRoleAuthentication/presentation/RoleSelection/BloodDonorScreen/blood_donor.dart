import 'package:flutter/material.dart';
import 'package:blood_donation_app/features/MultiRoleAuthentication/presentation/LoginScreen/login_screen.dart'; // Adjust path if needed

enum UserRole { donor, requester }

class RoleBasedRegistrationScreen extends StatefulWidget {
  const RoleBasedRegistrationScreen({super.key});

  @override
  State<RoleBasedRegistrationScreen> createState() =>
      _RoleBasedRegistrationScreenState();
}

class _RoleBasedRegistrationScreenState
    extends State<RoleBasedRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  static const Color primaryRed = Color(0xFFE53935);
  static const Color lightPink = Color(0xFFFFF5F5);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  UserRole _selectedRole = UserRole.donor;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  // Shared fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nidController = TextEditingController();
  final _mobileController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedGender;
  DateTime? _dateOfBirth;
  String? _selectedBloodGroup;

  // Donor-only fields
  DateTime? _lastDonationDate;
  String? _selectedAvailableTime;
  final _weightController = TextEditingController();
  bool? _willingToDonateNow;

  // Requester-only fields
  final _unitsRequiredController = TextEditingController();
  DateTime? _requiredByDate;
  String? _selectedUrgency;

  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];
  static const List<String> _bloodGroupOptions = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];
  static const List<String> _availableTimeOptions = [
    'Morning', 'Afternoon', 'Evening', 'Anytime',
  ];
  static const List<String> _urgencyOptions = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nidController.dispose();
    _mobileController.dispose();
    _locationController.dispose();
    _weightController.dispose();
    _unitsRequiredController.dispose();
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
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryRed),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickLocation() async {
    setState(() => _locationController.text = 'Fetching current location...');
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _locationController.text = 'Karachi, Sindh, PK');
  }

  bool _validateExtraFields() {
    if (_selectedGender == null) {
      _showSnack('Please select your gender');
      return false;
    }
    if (_dateOfBirth == null) {
      _showSnack('Please select your date of birth');
      return false;
    }
    if (_locationController.text.trim().isEmpty) {
      _showSnack('Please provide your location');
      return false;
    }
    if (_selectedBloodGroup == null) {
      _showSnack('Please select your blood group');
      return false;
    }
    if (_selectedRole == UserRole.donor) {
      if (_willingToDonateNow == null) {
        _showSnack('Please indicate if you are willing to donate now');
        return false;
      }
    } else {
      if (_unitsRequiredController.text.trim().isEmpty) {
        _showSnack('Please enter units required');
        return false;
      }
      if (_requiredByDate == null) {
        _showSnack('Please select the required-by date');
        return false;
      }
      if (_selectedUrgency == null) {
        _showSnack('Please select urgency');
        return false;
      }
    }
    if (!_agreedToTerms) {
      _showSnack('Please agree to the consent checkbox to continue');
      return false;
    }
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryRed),
    );
  }

  Future<void> _onSubmit() async {
    final isFormValid = _formKey.currentState!.validate();
    final isExtraValid = _validateExtraFields();
    if (!isFormValid || !isExtraValid) return;

    setState(() => _isLoading = true);

    // TODO: Wire to Riverpod registration use case
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDonor = _selectedRole == UserRole.donor;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      const SizedBox(height: 16),

                      // --- Profile Photo Picker ---
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Integrate image_picker
                          },
                          child: Stack(
                            children: [
                              Container(
                                height: 88,
                                width: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: lightPink,
                                  border: Border.all(
                                    color: primaryRed.withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: primaryRed,
                                  size: 40,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  height: 30,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryRed,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // --- First / Last Name ---
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: _decoration('First Name'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: _decoration('Last Name'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // --- NIC Number ---
                      TextFormField(
                        controller: _nidController,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('NIC Number'),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

                      const SizedBox(height: 14),

                      // --- Mobile Number ---
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: _decoration('Mobile Number'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length < 10) return 'Enter a valid number';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // --- Gender / Date of Birth ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              isExpanded: true,
                              decoration: _decoration('Gender'),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: textGrey,
                              ),
                              items: _genderOptions
                                  .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(
                                  g,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedGender = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDate(
                                initialDate: _dateOfBirth,
                                onPicked: (d) =>
                                    setState(() => _dateOfBirth = d),
                              ),
                              child: InputDecorator(
                                decoration: _decoration('Date of Birth')
                                    .copyWith(
                                  suffixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    color: textGrey,
                                    size: 18,
                                  ),
                                ),
                                child: Text(
                                  _dateOfBirth == null
                                      ? ''
                                      : _formatDate(_dateOfBirth!),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // --- Location ---
                      TextFormField(
                        controller: _locationController,
                        readOnly: true,
                        decoration: _decoration('Location').copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.my_location_rounded,
                              color: primaryRed,
                              size: 20,
                            ),
                            onPressed: _pickLocation,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // --- Blood Group ---
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBloodGroup,
                        isExpanded: true,
                        decoration: _decoration('Enter Your Blood Group'),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: textGrey,
                        ),
                        items: _bloodGroupOptions
                            .map((bg) => DropdownMenuItem(
                          value: bg,
                          child: Text(
                            bg,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedBloodGroup = value),
                      ),

                      const SizedBox(height: 28),

                      // --- Role Toggle ---
                      _buildRoleToggle(),

                      const SizedBox(height: 20),

                      // --- Conditional Fields ---
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: isDonor
                            ? _buildDonorFields()
                            : _buildRequesterFields(),
                      ),

                      const SizedBox(height: 20),

                      // --- Consent Checkbox ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _agreedToTerms,
                              activeColor: primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (value) => setState(
                                      () => _agreedToTerms = value ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                isDonor
                                    ? 'I voluntarily consent to donate blood and agree to any necessary medical checks before donation.'
                                    : 'I confirm this request is genuine and understand that final donor eligibility is decided by qualified medical staff.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textGrey,
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

            // --- Bottom Submit Button & Sign In Link ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSubmit,
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
                            : Text(
                          isDonor ? 'Become a Donor' : 'Submit Request',
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
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: textGrey, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                                  (route) => false,
                            );
                          },
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              color: primaryRed,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorFields() {
    return Column(
      key: const ValueKey('donor_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(
                  initialDate: _lastDonationDate,
                  onPicked: (d) => setState(() => _lastDonationDate = d),
                ),
                child: InputDecorator(
                  decoration: _decoration('Last Donation').copyWith(
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      color: textGrey,
                      size: 18,
                    ),
                  ),
                  child: Text(
                    _lastDonationDate == null
                        ? ''
                        : _formatDate(_lastDonationDate!),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedAvailableTime,
                isExpanded: true,
                decoration: _decoration('Available Time'),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textGrey,
                ),
                items: _availableTimeOptions
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    t,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedAvailableTime = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Weight (kg)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final weight = double.tryParse(v.trim());
                  if (weight == null || weight < 45) {
                    return 'Min. 45 kg';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<bool>(
                initialValue: _willingToDonateNow,
                isExpanded: true,
                decoration: _decoration('Donate now?'),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textGrey,
                ),
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text('Yes', style: TextStyle(fontSize: 14)),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('No', style: TextStyle(fontSize: 14)),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _willingToDonateNow = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequesterFields() {
    return Column(
      key: const ValueKey('requester_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _unitsRequiredController,
                keyboardType: TextInputType.number,
                decoration: _decoration('Units Required'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(
                  initialDate: _requiredByDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  onPicked: (d) => setState(() => _requiredByDate = d),
                ),
                child: InputDecorator(
                  decoration: _decoration('Required By').copyWith(
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      color: textGrey,
                      size: 18,
                    ),
                  ),
                  child: Text(
                    _requiredByDate == null
                        ? ''
                        : _formatDate(_requiredByDate!),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _selectedUrgency,
          isExpanded: true,
          decoration: _decoration('Urgency'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textGrey),
          items: _urgencyOptions
              .map((u) => DropdownMenuItem(
            value: u,
            child: Text(
              u,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ))
              .toList(),
          onChanged: (value) => setState(() => _selectedUrgency = value),
        ),
      ],
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: lightPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0E0)),
      ),
      child: Row(
        children: [
          _buildRoleTab(
            label: 'I WANT TO\nDONATE BLOOD',
            role: UserRole.donor,
          ),
          const SizedBox(width: 6),
          _buildRoleTab(
            label: 'I NEED\nBLOOD',
            role: UserRole.requester,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab({required String label, required UserRole role}) {
    final bool isActive = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
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
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: isActive ? Colors.white : textGrey,
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

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}