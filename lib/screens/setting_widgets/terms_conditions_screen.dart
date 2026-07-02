import 'package:flutter/material.dart';

const _kBg = Color(0xFFF1F5F9);
const _kTextDark = Color(0xFF1E293B);

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FWU Portal Terms of Use',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextDark),
              ),
              SizedBox(height: 16),
              Text(
                '1. Acceptance of Terms\n'
                'By accessing or using the Far Western University (FWU) Mobile App, you agree to be bound by these terms. This app is for internal use by university students, admin, and faculty.\n\n'
                '2. User Accounts\n'
                'You are responsible for maintaining the confidentiality of your login credentials. Do not share your password with anyone. Any activity occurring under your account is your responsibility.\n\n'
                '3. Academic Integrity\n'
                'All exam forms filled, results viewed, and academic actions taken through this portal must adhere to the FWU Academic Integrity Policy.\n\n'
                '4. Payments\n'
                'Any digital payments (eSewa, Khalti, ConnectIPS) made through the app are processed by third-party gateways. FWU is not liable for transactions failing securely due to banking downtimes.\n\n'
                '5. Updates and Modifications\n'
                'FWU reserves the right to modify these terms. Continued use implies acceptance.',
                style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
