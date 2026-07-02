import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/result_provider.dart';
import '../models/result_model.dart';
import '../providers/form_provider.dart';
import 'result_display_screen.dart';

const _kPrimary = Color(0xFF0F6E56);
const _kBg = Color(0xFFF1F5F9);
const _kTextDark = Color(0xFF1E293B);
const _kTextMuted = Color(0xFF94A3B8);
const _kBorder = Color(0xFFE2E8F0);
const _kSurface = Color(0xFFFFFFFF);

class ResultScreen extends StatefulWidget {
  final String? examId;
  final String? symbolNo;
  final String? dob;
  final String? academicYearId;

  const ResultScreen({
    super.key,
    this.examId,
    this.symbolNo,
    this.dob,
    this.academicYearId,
  });

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _symbolController = TextEditingController();
  final _dobController = TextEditingController();
  ExamSchedule? _selectedExam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final resultProv = Provider.of<ResultProvider>(context, listen: false);
      final formProv = Provider.of<FormProvider>(context, listen: false);

      if (widget.dob != null) {
        _dobController.text = widget.dob!;
      } else if (auth.studentInfo != null) {
        _dobController.text = auth.studentInfo!.dob.split(' / ').first;
      }

      if (widget.symbolNo != null) {
        _symbolController.text = widget.symbolNo!;
      } else if (auth.studentInfo != null &&
          auth.studentInfo!.registrationNo.isNotEmpty) {
        _symbolController.text = auth.studentInfo!.registrationNo;
      }

      await Future.wait([
        resultProv.fetchExams(),
        if (formProv.examSchedules.isEmpty)
          formProv.fetchExamSchedules(auth.sessionCookie),
      ]);

      if (resultProv.exams.isNotEmpty && mounted) {
        // Find Closed/Verified exams that have Roll Numbers (Admit Cards)
        final admitCards = formProv.examSchedules
            .where((s) => s.examRollNo != null && s.examRollNo!.isNotEmpty)
            .toList();
        admitCards.sort((a, b) => b.examScheduleId.compareTo(a.examScheduleId));

        bool foundValidResult = false;

        // System automatically tests exams, starting from latest semester backwards
        for (final registeredExam in admitCards) {
          final exactRollNo = registeredExam.examRollNo;
          final exactIdStr = registeredExam.examScheduleId.toString();

          // 1. Try exact ID match first
          ExamSchedule? matchedExam = resultProv.exams
              .where((e) => e.id == exactIdStr)
              .firstOrNull;

          if (matchedExam == null) {
            // 2. Fallback to smart title matching
            final stopWords = {
              'of',
              'in',
              'and',
              'for',
              'the',
              'to',
              'result',
              'examination',
              'semester',
              'year',
              'level',
            };

            final cleanRegName = registeredExam.examScheduleName
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9\s]'), '');
            final regWords = cleanRegName
                .split(RegExp(r'\s+'))
                .where((w) => w.length > 1 && !stopWords.contains(w))
                .toSet();

            int maxOverlap = 0;
            if (regWords.isNotEmpty) {
              for (final e in resultProv.exams) {
                final cleanPubName = e.name.toLowerCase().replaceAll(
                  RegExp(r'[^a-z0-9\s]'),
                  '',
                );
                final pubWords = cleanPubName
                    .split(RegExp(r'\s+'))
                    .where((w) => w.length > 1 && !stopWords.contains(w))
                    .toSet();

                int overlap = regWords.intersection(pubWords).length;

                if (overlap > maxOverlap) {
                  maxOverlap = overlap;
                  matchedExam = e;
                }
              }
            }
          }

          if (matchedExam != null &&
              exactRollNo != null &&
              exactRollNo.isNotEmpty &&
              _dobController.text.isNotEmpty) {
            // Found a match, system automatically tests if the result is published
            final success = await resultProv.checkStudentResult(
              matchedExam.id,
              exactRollNo,
              _dobController.text,
              matchedExam.academicYearId,
            );

            if (success) {
              if (mounted) {
                setState(() {
                  _selectedExam = matchedExam;
                  _symbolController.text = exactRollNo;
                });
              }
              foundValidResult = true;
              break; // Found the most recent published result, stop checking previous semesters
            } else {
              // If it failed, clear the error so it doesn't show on the UI while iterating
              resultProv.clearResult();
            }
          }
        }

        if (!foundValidResult && mounted) {
          // If no result was found for any of their admitted exams, set to first default
          setState(() {
            if (widget.examId != null) {
              _selectedExam = resultProv.exams.firstWhere(
                (e) => e.id == widget.examId,
                orElse: () => resultProv.exams.first,
              );
            } else {
              _selectedExam = resultProv.exams.first;
            }

            if (widget.symbolNo != null) {
              _symbolController.text = widget.symbolNo!;
            } else if (admitCards.isNotEmpty) {
              _symbolController.text = admitCards.first.examRollNo!;
            } else if (auth.studentInfo != null &&
                auth.studentInfo!.registrationNo.isNotEmpty) {
              _symbolController.text = auth.studentInfo!.registrationNo;
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _checkResult() async {
    if (_selectedExam == null) {
      _showSnack('Please select an exam');
      return;
    }
    if (_symbolController.text.isEmpty) {
      _showSnack('Enter symbol number');
      return;
    }

    final resultProv = Provider.of<ResultProvider>(context, listen: false);
    final success = await resultProv.checkStudentResult(
      _selectedExam!.id,
      _symbolController.text,
      _dobController.text,
      _selectedExam!.academicYearId,
    );

    if (success && mounted && resultProv.latestResult != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultDisplayScreen(result: resultProv.latestResult!),
        ),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: _kTextDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultProv = Provider.of<ResultProvider>(context);
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── HEADER ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 20, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: _kTextDark,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ] else ...[
                    const SizedBox(width: 10),
                  ],
                  const Expanded(
                    child: Text(
                      'Results',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── CONTENT ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => resultProv.fetchExams(),
                color: _kPrimary,
                backgroundColor: _kSurface,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    // ── Search Form Card ──
                    _buildFormCard(resultProv),
                    const SizedBox(height: 16),

                    // ── Global Loading Indicator ──
                    if (resultProv.isLoading) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _kPrimary,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          "Fetching academic records...",
                          style: TextStyle(
                            color: _kTextMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    // ── Error ──
                    if (resultProv.error != null) ...[
                      const SizedBox(height: 20),
                      _buildError(resultProv.error!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(ResultProvider resultProv) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 16),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: _kPrimary, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Result Query Parameters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Exam'),
                const SizedBox(height: 6),
                _buildExamPicker(resultProv),
                const SizedBox(height: 16),
                _buildLabel('Symbol Number'),
                const SizedBox(height: 6),
                _buildInput(
                  controller: _symbolController,
                  hint: 'Enter symbol number',
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildLabel('Date of Birth (BS)'),
                const SizedBox(height: 6),
                _buildInput(
                  controller: _dobController,
                  hint: 'YYYY-MM-DD',
                  icon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 24),

                // Embedded Search Button inside expanded form
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: resultProv.isLoading ? null : _checkResult,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: resultProv.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'CHECK RESULT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── LABEL ────────────────────────────────────────────────────────────────
  Widget _buildLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: _kTextMuted,
      letterSpacing: 1.5,
    ),
  );

  // ─── EXAM PICKER ──────────────────────────────────────────────────────────
  Widget _buildExamPicker(ResultProvider resultProv) {
    return GestureDetector(
      onTap: () => _showExamPicker(resultProv),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.assignment_outlined, color: _kPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedExam?.name ?? 'Choose an exam...',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedExam == null ? _kTextMuted : _kTextDark,
                  fontWeight: _selectedExam != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ─── TEXT INPUT ───────────────────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _kTextDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _kTextMuted,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: _kPrimary, size: 18),
        filled: true,
        fillColor: _kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ─── ERROR ────────────────────────────────────────────────────────────────
  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EXAM PICKER SHEET ────────────────────────────────────────────────────
  void _showExamPicker(ResultProvider resultProv) {
    if (resultProv.exams.isEmpty && !resultProv.isLoading) {
      resultProv.fetchExams();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExamPickerSheet(
        exams: resultProv.exams,
        onSelected: (exam) {
          setState(() => _selectedExam = exam);
          Navigator.pop(context);
        },
      ),
    );
  }
}

//  EXAM PICKER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════
class _ExamPickerSheet extends StatefulWidget {
  final List<ExamSchedule> exams;
  final Function(ExamSchedule) onSelected;
  const _ExamPickerSheet({required this.exams, required this.onSelected});

  @override
  __ExamPickerSheetState createState() => __ExamPickerSheetState();
}

class __ExamPickerSheetState extends State<_ExamPickerSheet> {
  late List<ExamSchedule> _filtered;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.exams;
  }

  void _filter(String q) => setState(() {
    _filtered = q.isEmpty
        ? widget.exams
        : widget.exams
              .where((e) => e.name.toLowerCase().contains(q.toLowerCase()))
              .toList();
  });

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Exam',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: _kTextMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _search,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search exam...',
                  hintStyle: const TextStyle(fontSize: 13, color: _kTextMuted),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: _kPrimary,
                    size: 19,
                  ),
                  filled: true,
                  fillColor: _kBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _filter,
              ),
            ),
            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No exams found',
                            style: TextStyle(color: _kTextMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(left: 64),
                        child: Divider(height: 1, color: Colors.grey.shade100),
                      ),
                      itemBuilder: (context, i) {
                        final exam = _filtered[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.assignment_outlined,
                              color: _kPrimary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            exam.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kTextDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.grey.shade300,
                          ),
                          onTap: () => widget.onSelected(exam),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
