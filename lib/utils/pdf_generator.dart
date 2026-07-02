import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/result_model.dart';

class PdfGenerator {
  /// Approximate Nepali Bikram Sambat date string for PDF footers.
  /// Uses a lookup table covering the 2080s BS (2020s AD).
  static String _bsDateString() {
    const bsMonths = [
      'Baisakh', 'Jestha', 'Asar', 'Shrawan', 'Bhadra',
      'Asoj', 'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra',
    ];
    const Map<int, List<int>> bsDays = {
      2082: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
      2083: [31, 31, 32, 31, 31, 30, 30, 30, 29, 30, 30, 30],
    };
    final ad = DateTime.now();
    final refAD = DateTime(2025, 4, 14); // 2082-01-01 BS
    int diff = ad.difference(refAD).inDays;
    int y = 2082, m = 0, d = 1;
    while (diff > 0) {
      final months = bsDays[y] ?? bsDays[2082]!;
      final rem = months[m] - d + 1;
      if (diff < rem) {
        d += diff;
        diff = 0;
      } else {
        diff -= rem;
        d = 1;
        m++;
        if (m == 12) { m = 0; y++; }
      }
    }
    return '${bsMonths[m]} $d, $y';
  }

  static Future<void> generateAndPrintResult(ExamResult result) async {
    final pdf = pw.Document();

    // Load logo
    final logoData = await rootBundle.load('assets/images/fwu_logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.portrait,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // HEADER
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(logoImage),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Far Western University',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Office of the Controller of Examinations',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Mahendranagar, Kanchanpur',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Academic Record',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 60), // balance the row for centering
                ],
              ),
              pw.SizedBox(height: 16),

              // STUDENT INFO
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _infoRow('Name', result.studentName),
                          _infoRow('Campus', result.campusName ?? '—'),
                          _infoRow('Faculty', result.facultyName ?? '—'),
                          _infoRow('Level', result.level ?? '—'),
                          _infoRow('Program', result.programName ?? '—'),
                        ],
                      ),
                    ),
                    pw.Container(
                      width: 1,
                      height: 60,
                      color: PdfColors.grey300,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _infoRow('Roll No', result.symbolNo),
                          _infoRow('Regd No', result.registrationNo ?? '—'),
                          _infoRow('Year/Sem', result.semester ?? '—'),
                          _infoRow('Exam Year', result.examYear ?? '—'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // MARKS TABLE
              _buildTable(result),

              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Text(
                    'Date: ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Note: This Grade Sheet is for general idea of grade(s) you secured. '
                'This is not for official use. If any mistakes appear; record at '
                'Administration ledger will be referred.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on: ${_bsDateString()} BS (${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} AD)',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Prompt user to print/save as PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'FWU_Result_${result.symbolNo}.pdf',
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            ': ',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(ExamResult result) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2), // Code
        1: pw.FlexColumnWidth(3.0), // Title
        2: pw.FlexColumnWidth(1.0), // CH
        3: pw.FlexColumnWidth(1.4), // TH/PR
        4: pw.FlexColumnWidth(1.2), // Final Grade
        5: pw.FlexColumnWidth(1.2), // Value
        6: pw.FlexColumnWidth(1.2), // Point
        7: pw.FlexColumnWidth(1.4), // Remarks
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _thCell('Course\nCode'),
            _thCell('Course Title'),
            _thCell('Credit\nHours'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Obtained\nMarks',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(height: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'TH',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Container(
                        width: 0.5,
                        height: 10,
                        color: PdfColors.grey400,
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'PR',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
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
        // Subjects
        ...result.subjects.map(
          (s) => pw.TableRow(
            children: [
              _tdCell(s.subjectCode),
              _tdCell(s.subjectName, align: pw.TextAlign.left),
              _tdCell(s.creditHour),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        s.thMarks,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Container(
                      width: 0.5,
                      height: 12,
                      color: PdfColors.grey400,
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        s.prMarks,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ],
                ),
              ),
              _tdCell(s.finalGrade, bold: true),
              _tdCell(s.gradeValue),
              _tdCell(s.gradePoint),
              _tdCell(s.remark),
            ],
          ),
        ),
        // Total
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tdCell(''),
            _tdCell('Total', bold: true, align: pw.TextAlign.right),
            _tdCell(result.totalCreditHour ?? '', bold: true),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(result.totalGradePoint ?? '', bold: true),
            _tdCell(''),
          ],
        ),
        // GPA
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tdCell(''),
            _tdCell(
              'GPA (Grade Point Average):',
              bold: true,
              align: pw.TextAlign.right,
            ),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(result.gpa, bold: true),
            _tdCell(''),
          ],
        ),
        // Result
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tdCell(''),
            _tdCell('Result:', bold: true, align: pw.TextAlign.right),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(''),
            _tdCell(result.resultStatus, bold: true),
            _tdCell(''),
          ],
        ),
      ],
    );
  }

  static pw.Widget _thCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _tdCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
