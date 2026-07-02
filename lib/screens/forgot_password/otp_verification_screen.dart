import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/smtp_service.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String generatedOtp;

  const OtpVerificationScreen({super.key, required this.email, required this.generatedOtp});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _activeIndex = 0;
  String? _error;
  bool _isLoading = false;
  late String _currentValidOtp;

  @override
  void initState() {
    super.initState();
    _currentValidOtp = widget.generatedOtp;
    
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() => _activeIndex = i);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _verifyOtp() {
    final enteredOtp = _controllers.map((c) => c.text).join();
    if (enteredOtp.length < 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }

    if (enteredOtp == _currentValidOtp) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
    } else {
      setState(() {
        _error = 'Invalid verification code. Please try again.';
        for (var c in _controllers) { c.clear(); }
        _focusNodes[0].requestFocus();
      });
    }
  }

  void _resendOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final newOtp = SmtpService.generateOtp();
    final success = await SmtpService.sendOtpEmail(widget.email, newOtp);

    setState(() => _isLoading = false);

    if (success) {
      _currentValidOtp = newOtp;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New code sent successfully!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
      }
    } else {
      setState(() => _error = 'Failed to resend code');
    }
  }

  Color _getBorderColor(int index) {
    if (_error != null) return Colors.red.shade400;
    if (_activeIndex == index) return const Color(0xFF3B82F6);
    if (_controllers[index].text.isNotEmpty) return const Color(0xFF93C5FD);
    return const Color(0xFFE2E8F0);
  }

  @override
  Widget build(BuildContext context) {
    // Mask email for display securely
    final parts = widget.email.split('@');
    final maskedEmail = parts.length == 2 
        ? '${parts[0].length > 2 ? parts[0].substring(0, 2) : parts[0]}***@${parts[1]}' 
        : widget.email;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Beautiful Icon Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.blue.shade100.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                  ],
                ),
                child: const Icon(Icons.shield_rounded, size: 48, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Verify Your Account', 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)
              ),
              const SizedBox(height: 12),
              
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
                  children: [
                    const TextSpan(text: 'We have sent a 6-digit code to\n'),
                    TextSpan(text: maskedEmail, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              if (_error != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50, 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(_error!, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

              // Animated OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 58,
                    decoration: BoxDecoration(
                      color: _activeIndex == index ? Colors.blue.shade50.withOpacity(0.3) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getBorderColor(index),
                        width: _activeIndex == index ? 2.5 : 1.5,
                      ),
                      boxShadow: _activeIndex == index 
                          ? [BoxShadow(color: Colors.blue.withOpacity(0.15), blurRadius: 10, spreadRadius: 1)]
                          : [],
                    ),
                    child: Center(
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(
                           fontSize: 24, 
                           fontWeight: FontWeight.w700,
                           color: _error != null ? Colors.red.shade700 : const Color(0xFF0F172A)
                        ),
                        cursorColor: const Color(0xFF3B82F6),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (value.isNotEmpty && index == 5) {
                            _focusNodes[index].unfocus();
                            _verifyOtp(); // Auto trigger verify on last digit
                          }
                          setState(() => _error = null);
                        },
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 48),

              // Modern Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: _activeIndex == 5 ? 4 : 1,
                    shadowColor: Colors.blue.withOpacity(0.5),
                  ),
                  child: const Text('Verify Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 32),
              
              // Resend Area
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive code? ", style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                  _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : InkWell(
                          onTap: _resendOtp,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text('Resend', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w800, fontSize: 15)),
                          ),
                        ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
