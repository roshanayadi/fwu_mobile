import 'package:flutter/material.dart';
import '../models/result_model.dart';
import '../utils/pdf_generator.dart';

const _kPrimary = Color(0xFF0F6E56);
const _kPrimaryLight = Color(0xFFE1F5EE);
const _kBg = Color(0xFFF1F5F9);
const _kTextDark = Color(0xFF1E293B);
const _kTextMid = Color(0xFF475569);
const _kSurface = Color(0xFFFFFFFF);

class ResultDisplayScreen extends StatelessWidget {
  final ExamResult result;

  const ResultDisplayScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── HEADER ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: _kTextDark,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Exam Result',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  if (result.subjects.isEmpty)
                    _buildDebugJson()
                  else
                    OfficialMarksheet(result: result),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugJson() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEBUG JSON:',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          SelectableText(
            result.rawJson.toString(),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  OFFICIAL MARKSHEET  —  horizontally scrollable, improved design
// ═══════════════════════════════════════════════════════════════════════════
class OfficialMarksheet extends StatelessWidget {
  final ExamResult result;
  const OfficialMarksheet({super.key, required this.result});

  static const double _sheetWidth = 700.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section title + print button ──────────────────────────
        Row(
          children: [
            const Text(
              'Grade Sheet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                PdfGenerator.generateAndPrintResult(result);
              },
              icon: const Icon(Icons.print_rounded, size: 15),
              label: const Text(
                'Print',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Horizontal scroll wrapper ─────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: _sheetWidth,
            child: Container(
              decoration: BoxDecoration(
                color: _kSurface,
                border: Border.all(color: _kTextDark, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──
                  _buildHeader(),
                  // ── Divider ──
                  Container(height: 1, color: const Color(0xFFCBD5E1)),
                  // ── Student Info ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildStudentInfoBox(),
                  ),
                  // ── Marks Table ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildMarksTable(),
                  ),
                  // ── Footer ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: _buildFooterNote(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      color: const Color(0xFFF8FAFC),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/fwu_logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title block
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Far Western University',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Office of the Controller of Examinations',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Mahendranagar, Kanchanpur',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: _kTextMid),
                ),
                SizedBox(height: 8),
                AcademicRecordBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Student Info Box ─────────────────────────────────────────────────────
  Widget _buildStudentInfoBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Name', result.studentName),
                _infoRow('Campus', result.campusName ?? '—'),
                _infoRow('Faculty', result.facultyName ?? '—'),
                _infoRow('Level', result.level ?? '—'),
                _infoRow('Program', result.programName ?? '—'),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Right column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Roll No', result.symbolNo),
                _infoRow('Regd No', result.registrationNo ?? '—'),
                _infoRow('Year / Semester', result.semester ?? '—'),
                _infoRow('Exam Year', result.examYear ?? '—'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kTextMid,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _kTextMid,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Marks Table ──────────────────────────────────────────────────────────
  Widget _buildMarksTable() {
    return Table(
      border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(1.6), // Course Code
        1: FlexColumnWidth(4.0), // Course Title
        2: FlexColumnWidth(1.1), // Credit Hours
        3: FlexColumnWidth(1.8), // Obtained Marks (TH|PR)
        4: FlexColumnWidth(1.2), // Final Grade
        5: FlexColumnWidth(1.2), // Grade Value
        6: FlexColumnWidth(1.2), // Grade Point
        7: FlexColumnWidth(1.4), // Remarks
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // ── Header row ──
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFEFF6FF)),
          children: [
            _thCell('Course\nCode'),
            _thCell('Course Title'),
            _thCell('Credit\nHours'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Obtained\nMarks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 0.8, color: const Color(0xFFCBD5E1)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'TH',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: _kTextMid,
                          ),
                        ),
                      ),
                      Container(
                        width: 0.8,
                        height: 10,
                        color: const Color(0xFFCBD5E1),
                      ),
                      Expanded(
                        child: Text(
                          'PR',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: _kTextMid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _thCell('Final\nGrade'),
            _thCell('Grade\nValue'),
            _thCell('Grade\nPoint'),
            _thCell('Remarks'),
          ],
        ),

        // ── Data rows ──
        ...result.subjects.map(
          (s) => TableRow(
            children: [
              _tdCell(s.subjectCode),
              _tdCell(s.subjectName, align: TextAlign.left),
              _tdCell(s.creditHour),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.thMarks,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: _kTextDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Container(
                      width: 0.8,
                      height: 12,
                      color: const Color(0xFFCBD5E1),
                    ),
                    Expanded(
                      child: Text(
                        s.prMarks,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: _kTextDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _tdCell(s.finalGrade, bold: true),
              _tdCell(s.gradeValue),
              _tdCell(s.gradePoint),
              _tdCell(
                s.remark,
                textColor: s.remark.toLowerCase().contains('pass')
                    ? const Color(0xFF15803D)
                    : (s.remark.toLowerCase().contains('fail')
                          ? Colors.red.shade700
                          : null),
                bold: true,
              ),
            ],
          ),
        ),

        // ── Total row ──
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
          children: [
            _tdCell(''),
            _tdCell('Total', align: TextAlign.right, bold: true),
            _tdCell(result.totalCreditHour ?? '', bold: true),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(result.totalGradePoint ?? '', bold: true),
            _tdCell(''),
          ],
        ),

        // ── GPA row ──
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
          children: [
            _tdCell(''),
            _tdCell(
              'GPA (Grade Point Average):',
              align: TextAlign.right,
              bold: true,
            ),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(result.gpa, bold: true, textColor: _kPrimary),
            _tdCell(''),
          ],
        ),

        // ── Result row ──
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
          children: [
            _tdCell(''),
            _tdCell('Result:', align: TextAlign.right, bold: true),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(
              result.resultStatus,
              bold: true,
              textColor: result.resultStatus.toLowerCase().contains('pass')
                  ? const Color(0xFF15803D)
                  : Colors.red.shade700,
            ),
            _tdCell(''),
          ],
        ),
      ],
    );
  }

  Widget _thCell(String text, {bool sub = false}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: sub ? 9 : 9.5,
          fontWeight: FontWeight.w700,
          color: sub ? _kTextMid : _kTextDark,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _tdCell(
    String text, {
    TextAlign align = TextAlign.center,
    bool bold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          color: textColor ?? _kTextDark,
          height: 1.3,
        ),
      ),
    );
  }

  // ── Footer Note ──────────────────────────────────────────────────────────
  Widget _buildFooterNote() {
    final today = DateTime.now();
    final dateStr =
        '${_monthName(today.month)} ${today.day.toString().padLeft(2, '0')}, ${today.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: const Color(0xFFE2E8F0)),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              'Date: ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _kTextMid,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 10, color: _kTextDark),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        // Custom Disclaimer Message explicitly requested
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.gavel_rounded,
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DISCLAIMER: The results published here are for immediate information to the examinees. '
                  'These cannot be treated as original mark sheets. Please verify your marks from the '
                  'official records maintained by the university administration.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade900,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthName(int m) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m];
}

// ─── Academic Record Badge ────────────────────────────────────────────────
class AcademicRecordBadge extends StatelessWidget {
  const AcademicRecordBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF9FE1CB)),
      ),
      child: const Text(
        'ACADEMIC RECORD',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF085041),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
