import 'package:flutter/material.dart';

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'App Guide & Documentation',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text(
            'Below is the official documentation for using the FWU application. It details how to access and utilize various features efficiently.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          const _GuideBlock(
            title: '1. Dashboard Navigation',
            description: 'The Dashboard is the first screen you see after logging in. It gives you a quick overview of university updates and features.',
            steps: [
              'The top section displays your profile overview and dynamic calendar dates.',
              'Quick Services section provides one-tap access to all key modules.',
              'The notices section shows the latest university announcements.',
              'Tap the bell icon on the top right for instant notifications.',
              'Pull down anywhere on the screen to refresh context data.',
            ],
          ),
          const _GuideBlock(
            title: '2. Digital ID Card',
            description: 'Your student identity card is securely stored directly on your phone.',
            steps: [
              'Tap "ID Card" in Quick Services.',
              'Your official data including symbol number, faculty, and year are shown.',
              'Your profile photo and digital signature appear automatically on the card.',
              'This screen can be presented at university events for immediate verification.',
              'The card caches locally and loads instantly without internet access.',
            ],
          ),
          const _GuideBlock(
            title: '3. Exam Results',
            description: 'Check your semester results securely without manual data entry.',
            steps: [
              'Tap "Result" in Quick Services.',
              'Your symbol number and respective semester are auto-filled dynamically.',
              'If current results are unreleased, the system adapts and references the last published semester.',
              'Academic marks, GPA, and grades are formatted in a clean table.',
              'You can securely download your official marksheet record as a PDF.',
            ],
          ),
          const _GuideBlock(
            title: '4. Official Documents & Forms',
            description: 'Quickly browse and query all official university forms.',
            steps: [
              'Tap "Forms" in Quick Services.',
              'Available documents are systematically listed by appropriate categories.',
              'Use the integrated search capability to locate specific forms instantly.',
              'Tap any listed form to securely download or print it via your web browser built-in handler.',
            ],
          ),
          const _GuideBlock(
            title: '5. Academic Syllabus',
            description: 'Query the fully updated course syllabus for your enrolled program.',
            steps: [
              'Tap "Syllabus" in Quick Services.',
              'Select parameters like Faculty and Program dynamically.',
              'Filter by semester to target specific required subject listings.',
              'The interface seamlessly opens the official FWU portal for detailed module descriptions.',
            ],
          ),
          const _GuideBlock(
            title: '6. Academic Calendar',
            description: 'View the integrated university academic schedule tied to Bikram Sambat (BS).',
            steps: [
              'Tap "Calendar" in Quick Services.',
              'Navigate chronologically between months using the designated arrows.',
              'Colored markers signify underlying academic thresholds (Exams, Holidays, etc.).',
              'Tap any marked date cell to surface detailed administrative event information.',
            ],
          ),
          const _GuideBlock(
            title: '7. AI Support Assistance',
            description: 'Get automated answers regarding FWU protocols via an integrated AI support chat.',
            steps: [
              'Tap "Support" in Quick Services.',
              'Formulate queries directly into the lower chat interface.',
              'The AI contextualizes data and responds immediately with relevant logic.',
              'Advanced feature: Request automated summarization for long text or university notices.',
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),
          const Text(
            'For operational constraints or extended help, utilize the AI Support module or consult the university IT division.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Formal Document Block ─────────────────────────────────────────────────────

class _GuideBlock extends StatelessWidget {
  final String title;
  final String description;
  final List<String> steps;

  const _GuideBlock({
    required this.title,
    required this.description,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.map((step) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 12),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: Color(0xFF94A3B8),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
