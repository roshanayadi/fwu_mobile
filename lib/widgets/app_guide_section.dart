import 'package:flutter/material.dart';
import '../screens/app_guide_screen.dart';

const _kGreen = Color(0xFF0F6E56);
const _kText1 = Color(0xFF0D1B2A);
const _kText2 = Color(0xFF6B7280);

class AppGuideSection extends StatelessWidget {
  final Color primaryGreen;
  const AppGuideSection({super.key, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppGuideScreen()),
        ),
        child: Container(
          color: Colors.transparent, // Ensures the whole row is clickable
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Guide & Support',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kText1,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Learn how to use features step-by-step',
                      style: TextStyle(
                        fontSize: 13,
                        color: _kText2,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kGreen.withValues(alpha: 0.1), _kGreen.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.15), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'View Guide',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kGreen,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: _kGreen, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
