import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_keys.dart';
import '../../providers/auth_provider.dart';
import '../../services/smtp_service.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _regController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _regController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final email = _emailController.text.trim();
    final regNo = _regController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    if (regNo.isEmpty) {
      setState(() => _error = 'Please enter your Registration Number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Try fetching from remote API first
      final authProvider = context.read<AuthProvider>();
      String? linkedEmail = await authProvider.getLinkedEmail(regNo); // Load local as fallback

      try {
        final url = Uri.parse('https://fwuapi.hamrotayari.com/get_contact.php');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': AppKeys.customApiKey,
          },
          body: jsonEncode({'student_id': regNo}),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['email'] != null) {
            linkedEmail = data['email'];
          } else if (data['error'] != null && linkedEmail == null) {
             setState(() {
                _error = data['error'];
                _isLoading = false;
             });
             return;
          }
        }
      } catch (e) {
      }

      if (linkedEmail == null || linkedEmail.isEmpty) {
        setState(() {
          _error = 'Registration number not found in our records.';
          _isLoading = false;
        });
        return;
      }

      // 2. Validate linked email matches user input
      if (linkedEmail.toLowerCase() != email.toLowerCase()) {
        String masked = 'unknown';
        if (linkedEmail.contains('@')) {
           final parts = linkedEmail.split('@');
           if (parts[0].length > 2) {
             masked = '${parts[0].substring(0, 1)}***${parts[0].substring(parts[0].length - 1)}@${parts[1]}';
           } else {
             masked = '***@${parts[1]}';
           }
        }
        setState(() {
          _error = 'Incorrect. Hint: Your registered email looks like $masked';
          _isLoading = false;
        });
        return;
      }

      // 3. Email is verified, proceed with OTP
      final otp = SmtpService.generateOtp();
      final success = await SmtpService.sendOtpEmail(email, otp);

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(email: email, generatedOtp: otp),
          ),
        );
      } else {
        setState(() => _error = 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_rounded, size: 40, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 24),
            const Text('Reset Password', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text(
              'Enter your registered email address and registration number to receive a verification code.',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),

            TextField(
              controller: _regController,
              decoration: _inputDecoration(label: 'Registration Number', icon: Icons.badge_rounded),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(label: 'Email Address', icon: Icons.email_rounded),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Send Verification Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
    );
  }
}
