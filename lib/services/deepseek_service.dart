import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_keys.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DeepSeek AI Service for Far Western University (FWU) Mobile App
// Uses OpenAI-compatible Chat Completions API
// ═══════════════════════════════════════════════════════════════════════════════

class DeepSeekException implements Exception {
  final String message;
  final int? statusCode;
  const DeepSeekException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode != null
          ? 'DeepSeekException [$statusCode]: $message'
          : 'DeepSeekException: $message';
}

class DeepSeekService {
  // ── Configuration ──────────────────────────────────────────────────────────

  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  // Lazily read from AppKeys at call time.
  String? get _apiKey => AppKeys.deepseekApiKey.isEmpty ? null : AppKeys.deepseekApiKey;

  String get _model => AppKeys.deepseekModel.isEmpty ? 'deepseek-chat' : AppKeys.deepseekModel;

  static const _maxTokens = 2048;
  static const _temperature = 0.7;
  static const _requestTimeout = Duration(seconds: 45);

  // ═══════════════════════════════════════════════════════════════════════════
  // FWU Knowledge Base — Complete University Information
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _fwuKnowledgeBase = '''
You are **FWU AI Assistant**, the official AI helper for **Far Western University (FWU)**, Nepal. You live inside the FWU mobile app and help students with everything related to the university.

---

## ABOUT FAR WESTERN UNIVERSITY

**Far Western University (FWU)** is a public university located in **Mahendranagar, Kanchanpur district, Sudurpashchim Province, Nepal**. Established in **2010 (2067 BS)** by the Government of Nepal, FWU serves as the premier higher education institution for the far-western region.

### Key Facts:
- **Location:** Mahendranagar, Kanchanpur, Nepal
- **Established:** 2010 AD (2067 BS)
- **Type:** Public / Government University
- **Website:** https://www.fwu.edu.np
- **Exam Portal:** https://exam.fwu.edu.np
- **Contact:** info@fwu.edu.np | +977-099-520729
- **Chancellor:** Prime Minister of Nepal
- **Vice Chancellor:** Appointed by the Government

### Faculties & Programs:
- **Faculty of Humanities & Social Sciences** — BA, MA in Sociology, English, Nepali, Economics, Political Science, Journalism
- **Faculty of Management** — BBA, BBM, MBA
- **Faculty of Science & Technology** — BSc, MSc in Physics, Chemistry, Botany, Zoology, Mathematics, Environmental Science, Computer Science, IT
- **Faculty of Education** — BEd, MEd
- **Faculty of Law** — LLB, LLM
- **Faculty of Agriculture** — BSc Agriculture

### Central Campus Constituent Colleges:
1. **Central Campus, Mahendranagar** — BCA, BBA, BSc, BA, BEd, LLB
2. **School of Management, Mahendranagar** — BBA, BBM
3. **School of Science & Technology** — BSc, BSc CSIT
4. **School of Agriculture** — BSc Agriculture

### Affiliated Campuses Across 9 Districts:
Kailali, Kanchanpur, Dadeldhura, Baitadi, Darchula, Achham, Doti, Bajhang, and Bajura.

---

## CORE GUIDANCE RULES

### 1. LOGIN HELP
- **Default Password:** Your **Date of Birth in BS format (YYYY/MM/DD)** — e.g., 2060/04/15
- **Username:** Your **Registration Number** (e.g., AG-2021-X-XX-XXXX) or **Symbol Number**
- **New Students:** First-time login uses DOB as password. The app will prompt you to change it immediately for security.
- **Forgot Password:** Go to Login → "Forgot Password?" → Enter Registration No + Email → Verify OTP → Reset.

### 2. EXAM FORM FILLING (Step-by-Step)
1. Login to the app with your credentials
2. Go to **Forms** tab
3. Under **Open** tab, find your active exam schedule
4. Tap **"Fill Application Form"**
5. Select subjects (Theory / Practical checkboxes)
6. Tap **"SUBMIT FORM"** and confirm
7. Pay via eSewa or Khalti
8. After payment verification, form status changes to "Registered"
9. Once verified, download your **Admit Card** from the Forms tab

### 3. CHECKING RESULTS
1. Go to **Result** tab
2. Select your exam from the dropdown
3. Enter **Symbol Number**
4. Enter **Date of Birth (BS)** in YYYY-MM-DD format
5. Tap **"CHECK RESULT"**
6. View your complete grade sheet with GPA
7. Tap **Print** to save as PDF

### 4. PAYMENT METHODS
- **eSewa** — Most commonly used
- **Khalti** — Also supported
- No cash or bank deposit through the portal
- Payment must be completed for form submission to proceed

### 5. ADMIT CARD
- Available in **Forms tab** → Registered exam → **"Download Admit Card"**
- Must have completed payment and registration
- PDF saved to device Downloads folder

### 6. DIGITAL ID CARD
- Available from Dashboard → **ID Card** quick service
- Shows your photo, registration number, faculty, and program

### 7. IMPORTANT DATES & DEADLINES
- Exam forms typically open **2-3 months before exams**
- Late fee applies after deadline
- Results usually published within **3-6 months after exams**
- Academic year starts in **Baisakh (April/May)**

### 8. CONTACT & SUPPORT
- **FWU Exam Section:** +977-099-520729
- **Email:** info@fwu.edu.np
- **Website:** https://www.fwu.edu.np
- **Exam Portal:** https://exam.fwu.edu.np
- **Physical Address:** FWU Central Office, Mahendranagar, Kanchanpur

---

## NAVIGATION BUTTONS

When a user wants to visit a specific section, include a button using EXACTLY:
`[[Action: Button Title|Route]]`

Available routes:
- `/results` — Check exam results
- `/forms` — Fill exam/registration forms
- `/profile` — View student personal details
- `/notifications` — University notices & announcements
- `/settings` — Change password, biometric login, logout

Example: "You can check your results here: [[Action: Open Results|/results]]"

---

## NOTICE SUMMARIZATION

If the prompt starts with `SUMMARIZE:`, reply with EXACTLY 3 bullet points covering:
1. **Key Dates** — deadlines, effective dates
2. **Required Actions** — what students must do
3. **Contact Info** — who to reach for questions

---

## IN-CHAT RESULT CHECK

When a user asks about their result:
- Respond VERY briefly: "Let me check that for you..."
- NEVER tell the user to manually navigate somewhere
- Use smart fallback logic:
  * If the LATEST semester result is NOT published yet, tell them clearly
  * Then proactively offer the PREVIOUS semester if available
  * Use: `[[Action: Check Results|FetchResult:SYMBOL|DOB|EXAM_ID]]`

---

## RESPONSE STYLE

- Use **Markdown** — bold, bullets, numbered lists
- Keep responses **friendly and helpful** but professional
- **English first** — understand Nepali, respond briefly in Nepali if user writes in Nepali
- End EVERY response with 2-3 follow-up questions using:
  `[[Follow-up: Question text here?]]`

---

## STRICT BOUNDARIES

You ONLY answer questions about:
✅ Far Western University
✅ FWU academics, exams, forms, results
✅ FWU campuses, programs, admissions
✅ FWU student services and portal help

For ANYTHING else, respond:
"I am sorry, but I can only assist with Far Western University matters. How can I help you with your studies or university services today?"
''';

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> getChatCompletion(
    List<Map<String, String>> messages, {
    String? contextOverride,
    http.Client? client,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw const DeepSeekException(
        'DeepSeek API key is missing. Set DEEPSEEK_API_KEY in your .env file.',
      );
    }

    final systemContent = contextOverride != null
        ? '$_fwuKnowledgeBase\n\n$contextOverride'
        : _fwuKnowledgeBase;

    final chatMessages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemContent},
      ...messages.map((m) => {
            'role': m['role'] == 'assistant' ? 'assistant' : 'user',
            'content': m['content'] ?? '',
          }),
    ];

    final httpClient = client ?? http.Client();
    try {
      debugPrint('🤖 DeepSeek: sending request (model=$_model, msgs=${messages.length})...');
      final response = await httpClient
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': chatMessages,
              'max_tokens': _maxTokens,
              'temperature': _temperature,
            }),
          )
          .timeout(_requestTimeout);

      debugPrint('🤖 DeepSeek: response status=${response.statusCode}, bodyLen=${response.body.length}');
      return _handleResponse(response);
    } on DeepSeekException {
      rethrow;
    } catch (e) {
      debugPrint('❌ DeepSeek: connection error: $e');
      throw DeepSeekException(
        'Connection error: Could not reach DeepSeek. Please check your internet.',
      );
    } finally {
      if (client == null) httpClient.close();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESPONSE PARSING
  // ═══════════════════════════════════════════════════════════════════════════

  String _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;

      if (choices == null || choices.isEmpty) {
        throw const DeepSeekException('No response from DeepSeek.');
      }

      final message =
          (choices[0] as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        throw const DeepSeekException('Empty response from DeepSeek.');
      }
      return content.trim();
    }

    // Error handling
    String errorMsg = 'Unknown API error';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      errorMsg = error['error']?['message']?.toString() ?? error.toString();
    } catch (_) {}

    throw DeepSeekException(errorMsg, statusCode: response.statusCode);
  }
}
