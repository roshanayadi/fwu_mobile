import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/result_provider.dart';
import '../../services/deepseek_service.dart';
import '../result_screen.dart';
import '../forms_screen.dart';
import '../profile_screen.dart';
import '../notifications_screen.dart';
import '../settings_screen.dart';
import '../../models/result_model.dart' as rm;
import '../../models/form_model.dart' as fm;
import '../../providers/form_provider.dart';
import '../../utils/pdf_generator.dart';

class QuickSupportScreen extends StatefulWidget {
  final String? initialMessage;
  const QuickSupportScreen({super.key, this.initialMessage});

  @override
  State<QuickSupportScreen> createState() => _QuickSupportScreenState();
}

class _QuickSupportScreenState extends State<QuickSupportScreen>
    with TickerProviderStateMixin {
  // ─── Design Tokens ──────────────────────────────────────────────────────────
  static const _primary = Color(0xFF6366F1);
  static const _primaryDark = Color(0xFF4F46E5);
  static const _userBubble = Color(0xFFEEF2FF);
  static const _assistantBubble = Color(0xFFFFFFFF);
  static const _bg = Color(0xFFF1F5F9);
  static const _textDark = Color(0xFF0F172A);
  static const _textMid = Color(0xFF475569);
  static const _textMuted = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _green = Color(0xFF0F6E56);
  static const _orange = Color(0xFFEA580C);

  // ─── Controllers ─────────────────────────────────────────────────────────────
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final DeepSeekService _aiService = DeepSeekService();

  // ─── State ───────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isTypingOut = false;
  bool _stopTyping = false;
  bool _autoScroll = true;
  http.Client? _activeClient; // for cancelling in-flight AI request
  final List<_ChatMessage> _messages = [];
  List<String> _suggestions = [];
  int? _lastUserMsgIndex; // for showing suggestion divider
  bool _isFetchingResult = false;

  // Animation
  late final AnimationController _dotAnim;

  // ─── Quick Chips ─────────────────────────────────────────────────────────────
  static const _quickChips = [
    _QuickChip(Icons.edit_document, 'Fill exam form', 'How to fill exam form?'),
    _QuickChip(Icons.lock_outline, 'Login password', 'Default password for login?'),
    _QuickChip(Icons.payment, 'Payment', 'Which payment is supported?'),
    _QuickChip(Icons.assignment, 'Results', 'How to check my results?'),
    _QuickChip(Icons.call, 'Contact FWU', 'Contact FWU support'),
    _QuickChip(Icons.card_giftcard, 'Admit Card', 'How to download admit card?'),
  ];

  @override
  void initState() {
    super.initState();
    _dotAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _prefetchData();
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.initialMessage!));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _dotAnim.dispose();
    super.dispose();
  }

  void _scrollDown() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Only auto-scroll if the user is near the bottom (within 150px).
  /// If they've scrolled up to read, don't interrupt.
  void _smartScrollDown() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 150;
    if (atBottom) {
      _scrollDown();
    }
  }

  void _prefetchData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<ResultProvider>(context, listen: false).fetchExams();
    if (auth.sessionCookie != null) {
      Provider.of<FormProvider>(context, listen: false)
          .fetchExamSchedules(auth.sessionCookie);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    final raw = text.trim();
    final lower = raw.toLowerCase();

    String display = raw;
    if (raw.startsWith('SUMMARIZE:')) {
      final title = raw.replaceFirst('SUMMARIZE:', '').split('\n').first.trim();
      display = '🔎 **Summarizing:** $title\n\n*Extracting key details…*';
    }

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: display, rawContent: raw));
      _isLoading = true;
      _suggestions = [];
      _lastUserMsgIndex = _messages.length - 1;
    });
    _textController.clear();
    _scrollDown();

    // ── Smart local intent detection (no AI needed) ────────────────────────────
    final resultWords = ['result', 'ग्रेड', 'grade', 'marks', 'score', 'check result', 'mero result'];
    final noticeWords = ['notice', 'notices', 'सूचना', 'notice k', 'what notice', 'latest notice', 'new notice', 'update'];
    final syllabusWords = ['syllabus', 'पाठ्यक्रम', 'course outline'];

    final isResult = resultWords.any((w) => lower.contains(w));
    final isNotice = noticeWords.any((w) => lower.contains(w));
    final isSyllabus = syllabusWords.any((w) => lower.contains(w));

    if (isResult) {
      final handled = await _handleResultIntent();
      if (handled) return;
    }
    if (isNotice) {
      final handled = await _handleNoticeIntent();
      if (handled) return;
    }
    if (isSyllabus) {
      final handled = await _handleSyllabusIntent();
      if (handled) return;
    }

    // ── Build context prompt ──────────────────────────────────────────────────
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resultProv = Provider.of<ResultProvider>(context, listen: false);
    final formProv = Provider.of<FormProvider>(context, listen: false);
    final student = auth.studentInfo;

    if (resultProv.exams.isEmpty) await resultProv.fetchExams();
    if (formProv.examSchedules.isEmpty && auth.sessionCookie != null) {
      await formProv.fetchExamSchedules(auth.sessionCookie);
    }

    final admitCards = formProv.examSchedules
        .where((s) => s.examRollNo != null && s.examRollNo!.isNotEmpty)
        .toList()
      ..sort((a, b) => b.examScheduleId.compareTo(a.examScheduleId));

    final ctx = StringBuffer();
    if (student != null) {
      ctx.writeln("[CONTEXT] ${student.fullName}, RegNo: ${student.registrationNo}, DOB: ${student.dob.split(' / ').first}");
    }
    if (admitCards.isNotEmpty) {
      ctx.writeln("[USER ADMIT CARDS]:");
      for (int i = 0; i < admitCards.length; i++) {
        final c = admitCards[i];
        ctx.writeln("- ${i == 0 ? 'LATEST' : 'PREV ${i + 1}'}: ${c.examScheduleName} | Roll: ${c.examRollNo}");
      }
    }
    if (resultProv.exams.isNotEmpty) {
      ctx.writeln("[PUBLISHED RESULTS]:");
      for (var e in resultProv.exams) {
        ctx.writeln("- ${e.name} (ID:${e.id})");
      }
    }
    ctx.writeln("[FALLBACK]: If LATEST admit card NOT in PUBLISHED list, say not out yet + offer PREVIOUS semester if published. Use FetchResult format.");

    // ── Call AI ───────────────────────────────────────────────────────────────
    _activeClient = http.Client();
    String reply;
    bool cancelled = false;
    try {
      reply = await _aiService.getChatCompletion(
        _messages
            .map((m) => {'role': m.role, 'content': m.rawContent ?? m.content})
            .toList(),
        contextOverride: ctx.toString(),
        client: _activeClient!,
      );
    } catch (e) {
      if (_stopTyping) {
        cancelled = true;
        reply = ''; // will be set to cancelled message below
      } else {
        reply = '**❌ Could not respond**\n\n${e.toString()}\n\n'
            'Check your internet or contact FWU at **+977-099-520729**.';
      }
    }
    _activeClient?.close();
    _activeClient = null;

    if (!mounted) return;

    if (cancelled) {
      // User pressed stop — don't add AI message, just reset state
      setState(() {
        _isLoading = false;
        _stopTyping = false;
      });
      return;
    }

    // ── Parse response ────────────────────────────────────────────────────────
    final suggestions =
        RegExp(r'\[\[Follow-up:\s*(.*?)\]\]').allMatches(reply).map((m) => m.group(1)!).toList();
    // Convert [[Action: Label|Route]] → markdown links, [[Follow-up]] → remove
    var clean = reply.replaceAll(RegExp(r'\[\[Follow-up:\s*(.*?)\]\]'), '').trim();
    clean = clean.replaceAllMapped(
      RegExp(r'\[\[Action:\s*(.*?)\|(.*?)\]\]'),
      (m) => '[${m.group(1)}](action:${m.group(2)})',
    );
    // If AI added natural follow-up questions, capture them; otherwise use parsed ones
    final extraFollowUps = RegExp(r'^(.*\?)$', multiLine: true).allMatches(clean).map((m) => m.group(1)!).toList();
    final allSuggestions = [...suggestions, ...extraFollowUps].take(3).toList();
    clean = clean.replaceAll(RegExp(r'\[\[Follow-up:\s*(.*?)\]\]'), '').trim();

    setState(() {
      _messages.add(_ChatMessage(role: 'assistant', content: ''));
      _isLoading = false;
      _stopTyping = false;
    });
    _typeOut(clean, allSuggestions);
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // TYPE-OUT ANIMATION
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<void> _typeOut(String text, List<String> suggestions) async {
    setState(() => _isTypingOut = true);
    final words = text.split(' ');
    final buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      if (!mounted) return;
      if (_stopTyping) {
        setState(() {
          _messages.last.content = text;
          _stopTyping = false;
          _isTypingOut = false;
        });
        break;
      }
      buffer.write((i == 0 ? '' : ' ') + words[i]);
      setState(() => _messages.last.content = buffer.toString());
      // Don't force-scroll during type-out — user can scroll freely
      int ms = 25;
      if (words[i].endsWith('.') || words[i].endsWith('!') || words[i].endsWith('?')) ms = 180;
      else if (words[i].endsWith(',') || words[i].endsWith(';')) ms = 90;
      await Future.delayed(Duration(milliseconds: ms));
    }
    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _isTypingOut = false;
      });
      _scrollDown();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // LOCAL INTENT HANDLERS (no AI needed)
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Auto-fetch & show student's most recent published result in-chat.
  Future<bool> _handleResultIntent() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resultProv = Provider.of<ResultProvider>(context, listen: false);
    final formProv = Provider.of<FormProvider>(context, listen: false);
    final student = auth.studentInfo;

    if (student == null || student.dob.isEmpty) {
      _finishWithMsg('**Result Check**\n\n⚠️ Student profile not loaded. Please login first and try again.');
      return true;
    }

    if (resultProv.exams.isEmpty) await resultProv.fetchExams();
    if (formProv.examSchedules.isEmpty && auth.sessionCookie != null) {
      await formProv.fetchExamSchedules(auth.sessionCookie);
    }

    final dob = student.dob.split(' / ').first;
    final admitCards = formProv.examSchedules
        .where((s) => s.examRollNo != null && s.examRollNo!.isNotEmpty)
        .toList()
      ..sort((a, b) => b.examScheduleId.compareTo(a.examScheduleId));

    if (admitCards.isEmpty) {
      _finishWithMsg('**Result Check**\n\n⚠️ No registered exams found for your account.');
      return true;
    }

    // Try each registered exam from latest to oldest
    for (final card in admitCards) {
      final exactId = card.examScheduleId.toString();
      final roll = card.examRollNo!;

      // Match with published exam by ID or name
      var matched = resultProv.exams.where((e) => e.id == exactId).firstOrNull;
      if (matched == null) {
        // Fuzzy match by name
        final cardWords = card.examScheduleName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
        int best = 0;
        for (var e in resultProv.exams) {
          final eWords = e.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
          int overlap = cardWords.intersection(eWords).length;
          if (overlap > best) { best = overlap; matched = e; }
        }
      }

      if (matched != null) {
        setState(() => _isFetchingResult = true);
        final ok = await resultProv.checkStudentResult(matched!.id, roll, dob, matched!.academicYearId);
        setState(() => _isFetchingResult = false);

        if (ok && resultProv.latestResult != null) {
          final r = resultProv.latestResult!;
          final buf = StringBuffer();
          buf.writeln('## 📊 Your Result\n');
          buf.writeln('**Name:** ${r.studentName}');
          buf.writeln('**Roll No:** ${r.symbolNo}');
          buf.writeln('**GPA:** **${r.gpa}**');
          buf.writeln('**Status:** ${r.resultStatus}');
          buf.writeln('**Level:** ${r.level ?? '-'}  |  **Semester:** ${r.semester ?? '-'}');
          buf.writeln('**Campus:** ${r.campusName ?? '-'}');
          buf.writeln();
          buf.writeln('### Subjects');
          buf.writeln('| Code | Subject | CH | TH | PR | Grade |');
          buf.writeln('|------|---------|-----|-----|-----|-------|');
          for (final s in r.subjects) {
            buf.writeln('| ${s.subjectCode} | ${s.subjectName} | ${s.creditHour} | ${s.thMarks} | ${s.prMarks} | ${s.finalGrade} |');
          }
          buf.writeln();
          buf.writeln('> ⚠️ *This is for information only. Verify from official records.*');
          buf.writeln();
          buf.writeln('[[Action: 📥 Download Official PDF|FetchResult:${r.symbolNo}|$dob|${matched!.id}]]');
          buf.writeln('[[Action: 🔍 Full Marksheet|/results?symbol=${r.symbolNo}&dob=$dob&examId=${matched!.id}]]');

          setState(() {
            _isLoading = false;
            _messages.add(_ChatMessage(role: 'assistant', content: buf.toString()));
            _suggestions = ['Check another semester?', 'Download admit card?'];
          });
          _scrollDown();
          return true;
        }
      }
    }

    // No published results found
    _finishWithMsg('**Result Check**\n\n📭 No published result found for your registered exams yet.\n\n'
        'Results are typically published 3-6 months after exams. Keep checking! 🔄');
    return true;
  }

  /// Fetch and show the 2 latest notices in-chat.
  Future<bool> _handleNoticeIntent() async {
    setState(() => _isFetchingResult = true);
    try {
      final client = http.Client();
      final res = await client.get(
        Uri.parse('https://fwuexam.edu.np/notice.html'),
      ).timeout(const Duration(seconds: 10));
      final body = res.body;
      client.close();

      // Parse notices from HTML
      final doc = parse(body);
      final modals = doc.querySelectorAll('.modal-body');
      final List<_Notice> notices = [];

      for (final modal in modals) {
        final a = modal.querySelector('a');
        final titleEl = modal.querySelector('.notice-card-title');
        if (a == null || titleEl == null || a.attributes['href'] == null) continue;
        String link = a.attributes['href']!;
        if (!link.startsWith('http')) link = 'https://fwuexam.edu.np/${link.replaceFirst(RegExp(r'^/+'), '')}';
        final dateEl = modal.querySelector('p.fw-medium');
        notices.add(_Notice(title: titleEl.text.trim(), date: dateEl?.text.trim() ?? '', link: link));
      }

      // Fallback: grab anchor text
      if (notices.isEmpty) {
        for (final a in doc.querySelectorAll('a')) {
          final t = a.text.trim();
          if (t.length > 15 && t.split(' ').length > 3) {
            notices.add(_Notice(title: t, date: '', link: a.attributes['href'] ?? ''));
          }
        }
      }

      if (notices.isEmpty) {
        _finishWithMsg('**Latest Notices**\n\n📭 No notices found right now. Check [fwu.edu.np](https://www.fwu.edu.np/notice.html).');
        return true;
      }

      // Show top 2
      final top2 = notices.take(2).toList();
      final buf = StringBuffer('## 📢 Latest Notices\n\n');
      for (int i = 0; i < top2.length; i++) {
        final n = top2[i];
        buf.writeln('### ${i + 1}. ${n.title}');
        if (n.date.isNotEmpty) buf.writeln('📅 ${n.date}');
        buf.writeln('[[Action: View Full Notice|${n.link}]]');
        buf.writeln();
      }
      buf.writeln('[View All Notices](https://www.fwu.edu.np/notice.html)');

      _finishWithMsg(buf.toString());
    } catch (e) {
      _finishWithMsg('**Latest Notices**\n\n❌ Could not fetch notices. Check your internet connection.');
    }
    return true;
  }

  /// Provide syllabus in downloadable format.
  Future<bool> _handleSyllabusIntent() async {
    // FWU syllabus links by faculty
    final buf = StringBuffer('## 📚 FWU Syllabus\n\n');
    buf.writeln('Select your program to download the syllabus:\n');

    final syllabi = [
      ('BCA Syllabus', 'https://fwu.edu.np/syllabus/bca'),
      ('BBA Syllabus', 'https://fwu.edu.np/syllabus/bba'),
      ('BSc CSIT Syllabus', 'https://fwu.edu.np/syllabus/csit'),
      ('BEd Syllabus', 'https://fwu.edu.np/syllabus/bed'),
      ('BA Syllabus', 'https://fwu.edu.np/syllabus/ba'),
      ('LLB Syllabus', 'https://fwu.edu.np/syllabus/llb'),
      ('BSc Agriculture', 'https://fwu.edu.np/syllabus/agriculture'),
    ];

    for (final s in syllabi) {
      buf.writeln('[[Action: Download ${s.$1}|${s.$2}]]');
      buf.writeln();
    }

    buf.writeln('---');
    buf.writeln('💡 *Syllabus will open in your browser for download.*\n');
    buf.writeln('[[Follow-up: BCA 4th semester syllabus?]]');
    buf.writeln('[[Follow-up: When are exams?]]');

    _finishWithMsg(buf.toString());
    return true;
  }

  /// Helper: finish loading and add an assistant message
  void _finishWithMsg(String markdown) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isFetchingResult = false;
      _messages.add(_ChatMessage(role: 'assistant', content: markdown));
      _suggestions = [];
    });
    _scrollDown();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<void> _handleAction(String route) async {
    // Open URLs in browser
    if (route.startsWith('http://') || route.startsWith('https://')) {
      final uri = Uri.parse(route);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (route.startsWith('FetchResult:')) {
      final parts = route.replaceFirst('FetchResult:', '').split('|');
      if (parts.length < 3) return;
      final symbol = parts[0], dob = parts[1], examId = parts[2];
      final yearId = parts.length > 3 ? parts[3] : null;

      setState(() => _isFetchingResult = true);
      _scrollDown();
      final rp = Provider.of<ResultProvider>(context, listen: false);
      final ok = await rp.checkStudentResult(examId, symbol, dob, yearId);
      if (!mounted) return;
      setState(() => _isFetchingResult = false);
      if (ok && rp.latestResult != null) {
        final r = rp.latestResult!;
        final buf = StringBuffer();
        buf.writeln('## 📊 Your Result\n');
        buf.writeln('**Name:** ${r.studentName}');
        buf.writeln('**Roll No:** ${r.symbolNo}');
        buf.writeln('**GPA:** **${r.gpa}**  |  **Status:** ${r.resultStatus}');
        buf.writeln();
        buf.writeln('| Code | Subject | CH | TH | PR | Grade |');
        buf.writeln('|------|---------|-----|-----|-----|-------|');
        for (final s in r.subjects) {
          buf.writeln('| ${s.subjectCode} | ${s.subjectName} | ${s.creditHour} | ${s.thMarks} | ${s.prMarks} | ${s.finalGrade} |');
        }
        buf.writeln();
        buf.writeln('[[Action: 📥 Download PDF|pdf:${r.symbolNo}]]');
        buf.writeln('[[Action: 🔍 Full Marksheet|/results?symbol=${r.symbolNo}&dob=$dob&examId=${r.examScheduleId}]]');
        _messages.add(_ChatMessage(role: 'assistant', content: buf.toString()));
      } else {
        _messages.add(_ChatMessage(
            role: 'assistant',
            content: '❌ Could not fetch result. ${rp.error ?? "Unknown error"}'));
      }
      _scrollDown();
      return;
    }

    // Download PDF action
    if (route.startsWith('pdf:')) {
      final symbol = route.replaceFirst('pdf:', '');
      final rp = Provider.of<ResultProvider>(context, listen: false);
      if (rp.latestResult != null && rp.latestResult!.symbolNo == symbol) {
        await PdfGenerator.generateAndPrintResult(rp.latestResult!);
      }
      return;
    }

    Widget? screen;
    if (route.startsWith('/results')) {
      final uri = Uri.parse(route);
      screen = ResultScreen(symbolNo: uri.queryParameters['symbol'], dob: uri.queryParameters['dob'], examId: uri.queryParameters['examId'], academicYearId: uri.queryParameters['yearId']);
    } else {
      switch (route) {
        case '/results': screen = const ResultScreen(); break;
        case '/forms': screen = FormsScreen(); break;
        case '/profile': screen = ProfileScreen(); break;
        case '/notifications': screen = const NotificationsScreen(); break;
        case '/settings': screen = SettingsScreen(); break;
      }
    }
    if (screen != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body: Column(children: [
        Expanded(child: _messages.isEmpty ? _emptyState() : _chatList()),
        _inputBar(bottom),
      ]),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black12,
      centerTitle: false,
      title: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.auto_awesome_rounded, color: _primary, size: 20),
        ),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FWU Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
          Text('Online • Always ready', style: TextStyle(fontSize: 11, color: _textMuted, fontWeight: FontWeight.w500)),
        ]),
      ]),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: _textMuted), onPressed: _clearChat, tooltip: 'Clear chat'),
        IconButton(icon: const Icon(Icons.call_outlined, size: 20, color: _primary), onPressed: () => _launch('tel:+977099520729'), tooltip: 'Call FWU'),
        const SizedBox(width: 4),
      ],
    );
  }

  void _clearChat() => setState(() { _messages.clear(); _suggestions = []; });

  // ═══════════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _emptyState() {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 500;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 24, vertical: 24),
        child: Column(children: [
          const SizedBox(height: 16),
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primary, Color(0xFF818CF8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 24),
          const Text('How can I help you?\n', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textDark, height: 1.3)),
          const Text('Ask anything about exam forms, results, admissions or university services.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _textMid, height: 1.5)),
          const SizedBox(height: 32),
          // Quick action chips
          Wrap(spacing: 10, runSpacing: 10, children: _quickChips.map((chip) => _buildQuickChip(chip)).toList()),
          const SizedBox(height: 48),
          // Footer
          Text('🔒 Your data stays private', style: TextStyle(fontSize: 11, color: _textMuted.withValues(alpha: 0.7))),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildQuickChip(_QuickChip chip) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _send(chip.query),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(chip.icon, size: 18, color: _primary),
            const SizedBox(width: 8),
            Text(chip.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // CHAT LIST
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _chatList() {
    final extraItems = (_isLoading || _isFetchingResult ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(top: 12, bottom: 16, left: 12, right: 12),
      itemCount: _messages.length + extraItems,
      itemBuilder: (_, i) {
        if (i < _messages.length) return _bubble(_messages[i], i);
        final offset = i - _messages.length;
        if ((_isLoading || _isFetchingResult) && offset == 0) return _typingIndicator();
        return const SizedBox.shrink();
      },
    );
  }

  // ─── MESSAGE BUBBLE ──────────────────────────────────────────────────────────
  Widget _bubble(_ChatMessage msg, int index) {
    final isUser = msg.role == 'user';
    final isLast = index == _messages.length - 1;
    final isConsecutive = index > 0 && _messages[index - 1].role == msg.role;

    // Convert [[Action: Label|Route]] → markdown link
    final clean = msg.content
        .replaceAllMapped(
          RegExp(r'\[\[Action:\s*(.*?)\|(.*?)\]\]'),
          (m) => '[${m.group(1)}](action:${m.group(2)})',
        )
        .trim();

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        top: isConsecutive ? 4 : (index == 0 ? 0 : 20),
        bottom: isLast ? 8 : 0,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label
          if (!isConsecutive)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                    size: 14,
                    color: isUser ? _primary : _green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isUser ? 'You' : 'FWU Assistant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isUser ? _primary : _green,
                    ),
                  ),
                ],
              ),
            ),
          // Content — pure markdown, no card container
          MarkdownBody(
            data: clean.isEmpty ? '…' : clean,
            selectable: true,
            onTapLink: (text, href, title) {
              if (href != null && href.startsWith('action:')) {
                _handleAction(href.replaceFirst('action:', ''));
              }
            },
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 15, height: 1.7, color: _textDark, fontWeight: FontWeight.w400),
              strong: TextStyle(color: _textDark, fontWeight: FontWeight.w800),
              listBullet: TextStyle(color: _green, fontSize: 14),
              h2: TextStyle(color: _textDark, fontWeight: FontWeight.w800, fontSize: 18, height: 1.3),
              h3: TextStyle(color: _textDark, fontWeight: FontWeight.w700, fontSize: 15, height: 1.3),
              code: TextStyle(backgroundColor: _bg, fontSize: 13, color: _textDark),
              blockquote: TextStyle(color: _textMid, fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
          // Typing dots
          if (_isTypingOut && isLast && !isUser)
            Padding(padding: const EdgeInsets.only(top: 8), child: _dotPulse()),
        ],
      ),
    );
  }

  // ─── DOT PULSE (inside typing bubble) ─────────────────────────────────────────
  Widget _dotPulse() {
    if (!_dotAnim.isAnimating) _dotAnim.repeat();
    return AnimatedBuilder(
      animation: _dotAnim,
      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
        final o = ((_dotAnim.value * 2 - i * 0.3) % 1.0).clamp(0.0, 1.0);
        return Container(
          width: 6, height: 6,
          margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.3 + o * 0.5), shape: BoxShape.circle),
        );
      })),
    );
  }

  // ─── TYPING INDICATOR ─────────────────────────────────────────────────────────
  Widget _typingIndicator() {
    if (!_dotAnim.isAnimating) _dotAnim.repeat();
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 8, bottom: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: _assistantBubble, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border, width: 0.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (_isFetchingResult) ...[
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
              const SizedBox(width: 10),
              const Text('Fetching result…', style: TextStyle(fontSize: 13, color: _textMuted, fontStyle: FontStyle.italic)),
            ] else ...[
              AnimatedBuilder(
                animation: _dotAnim,
                builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
                  final o = ((_dotAnim.value * 2 - i * 0.3) % 1.0).clamp(0.0, 1.0);
                  return Container(
                    width: 7, height: 7,
                    margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                    decoration: BoxDecoration(color: _primary.withValues(alpha: 0.3 + o * 0.5), shape: BoxShape.circle),
                  );
                })),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // INPUT BAR
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _inputBar(double bottomPad) {
    final canSend = _textController.text.trim().isNotEmpty && !_isLoading;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPad + 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -2))]),
      child: SafeArea(top: false, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // Auto-scroll toggle
        if (_messages.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _autoScroll = !_autoScroll),
            child: Container(
              width: 40, height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _autoScroll ? Colors.transparent : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _autoScroll ? _border.withValues(alpha: 0.5) : const Color(0xFFF59E0B),
                  width: _autoScroll ? 1 : 1.5,
                ),
              ),
              child: Icon(
                _autoScroll ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 20,
                color: _autoScroll ? _textMuted : const Color(0xFFB45309),
              ),
            ),
          ),
        // Text field
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(24), border: Border.all(color: _focusNode.hasFocus ? _primary.withValues(alpha: 0.4) : _border)),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) { if (v.trim().isNotEmpty) _send(v); },
              decoration: const InputDecoration(
                hintText: 'Ask about FWU…',
                hintStyle: TextStyle(color: _textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14.5, color: _textDark, height: 1.4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send / Stop button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: (_isLoading || _isTypingOut) ? Colors.red.shade400 : (canSend ? _primary : _textMuted.withValues(alpha: 0.3)),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon((_isLoading || _isTypingOut) ? Icons.stop_rounded : Icons.arrow_upward_rounded, color: Colors.white, size: 22),
            onPressed: () {
              if (_isLoading || _isTypingOut) {
                // Cancel: stop type-out AND kill in-flight HTTP
                setState(() => _stopTyping = true);
                _activeClient?.close();
              } else if (canSend) {
                _send(_textController.text);
              }
            },
            padding: EdgeInsets.zero,
          ),
        ),
      ])),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatMessage {
  final String role;
  String content;
  final String? rawContent;
  final DateTime time;
  _ChatMessage({required this.role, required this.content, this.rawContent}) : time = DateTime.now();
}

class _QuickChip {
  final IconData icon;
  final String label;
  final String query;
  const _QuickChip(this.icon, this.label, this.query);
}

class _Notice {
  final String title;
  final String date;
  final String link;
  const _Notice({required this.title, required this.date, required this.link});
}
