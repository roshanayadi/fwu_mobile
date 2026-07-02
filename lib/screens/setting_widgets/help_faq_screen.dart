import 'package:flutter/material.dart';

const _kBg = Color(0xFFF1F5F9);
const _kTextDark = Color(0xFF1E293B);

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Help & FAQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          _buildFaqItem('How do I fill exam forms?', 'Navigate to Forms > Exam Forms in the Dashboard. Select your semester and proceed to checkout using the gateway of choice.'),
          _buildFaqItem('Why am I not seeing my results?', 'Results are visible only if published officially by FWU. Also, ensure your fee clearance is complete up to that semester.'),
          _buildFaqItem('How do I change my password?', 'Go to Settings > Change Password. Enter your current password and your new one to complete the process.'),
          _buildFaqItem('Payment failed but amount was deducted?', 'This is common in initial payment gateways due to timeouts. The amount usually reverses within 24-48 hours. If not, contact your bank.'),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextDark),
        ),
        collapsedIconColor: const Color(0xFF94A3B8),
        iconColor: const Color(0xFF0F6E56),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
          ),
        ],
      ),
    );
  }
}
