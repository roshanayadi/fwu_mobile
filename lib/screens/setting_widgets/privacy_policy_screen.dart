import 'package:flutter/material.dart';

const _kBg = Color(0xFFF1F5F9);
const _kTextDark = Color(0xFF1E293B);

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                'Data Protection Policy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextDark),
              ),
              SizedBox(height: 16),
              Text(
                '1. Information Collection\n'
                'We collect information upon registration and usage. This includes name, registration number, profile photo, and academic records to operate the Far Western University (FWU) Mobile App.\n\n'
                '2. How We Use Information\n'
                'Your data is securely maintained locally. We use it to process your exams, compute results securely, track notifications realistically, and offer services such as online forms.\n\n'
                '3. Information Sharing\n'
                'We do not sell, trade, or rent personal identification data to others. Academic details remain within University boards unless required legally.\n\n'
                '4. Security\n'
                'We employ standard security protocols over HTTPS APIs connecting to our portals reducing risks of data breaches.',
                style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
