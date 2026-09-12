import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String destination; // Email or Phone number passed from previous screen

  const OtpVerificationScreen({
    super.key,
    this.destination = '+92 300 1234567', // Default sample placeholder
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers =
  List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(_otpLength, (_) => FocusNode());

  Timer? _timer;
  int _countdown = 45; // Resend countdown in seconds
  bool _canResend = false;
  bool _isLoading = false;

  static const Color primaryRed = Color(0xFFE53935);
  static const Color lightPink = Color(0xFFFFF5F5);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _countdown = 45;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      }
    });
  }

  String get _enteredOtp =>
      _controllers.map((controller) => controller.text).join();

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? primaryRed : Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onVerifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length < _otpLength) {
      _showSnack('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Wire to Riverpod OTP verification usecase
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isLoading = false);

    _showSnack('OTP Verified Successfully!', isError: false);

    // TODO: Navigate to Next Screen (Dashboard or Create New Password)
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleBasedRegistrationScreen()));
  }

  Future<void> _onResendOtp() async {
    if (!_canResend) return;

    _startResendTimer();
    _showSnack('A new OTP has been sent!', isError: false);
    // TODO: Call API to trigger OTP resend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Scrollable Form Area ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // --- 🖼️ Top Image.asset Header Placeholder ---
                    Center(
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: lightPink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'lib/core/constants/assets/animations/otp_verification.jpg', // 👈 Change to your image path
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.mark_email_read_outlined,
                              size: 72,
                              color: primaryRed,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Title & Destination Text ---
                    const Text(
                      'OTP Verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: textGrey,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                              text: 'Please enter the 6-digit code sent to\n'),
                          TextSpan(
                            text: widget.destination,
                            style: const TextStyle(
                              color: textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- 6-Digit OTP Boxes with Auto-Focus Shift ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        _otpLength,
                            (index) => _buildOtpBox(index),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // --- Resend Timer & Button ---
                    Center(
                      child: _canResend
                          ? TextButton(
                        onPressed: _onResendOtp,
                        child: const Text(
                          'Resend Code',
                          style: TextStyle(
                            color: primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                          : Text(
                        'Resend code in 00:${_countdown.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- Bottom Docked Verify Button ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
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
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onVerifyOtp,
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
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Verify & Continue',
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

  // --- Helper to build individual OTP digit input box ---
  Widget _buildOtpBox(int index) {
    return SizedBox(
      height: 54,
      width: 46,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            borderSide: const BorderSide(color: primaryRed, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Auto advance to next box
            if (index < _otpLength - 1) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus(); // Close keyboard on last digit
            }
          } else {
            // On backspace, shift focus to previous box
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }
}