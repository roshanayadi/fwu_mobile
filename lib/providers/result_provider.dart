import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/result_model.dart';

/// Shared HTTP client that allows FWU's self-signed certificate.
http.Client _createResultClient() {
  final ioClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => host.contains('fwu.edu.np');
  return IOClient(ioClient);
}

class ResultProvider extends ChangeNotifier {
  List<ExamSchedule> _exams = [];
  bool _isLoading = false;
  String? _error;
  ExamResult? _latestResult;

  List<ExamSchedule> get exams => _exams;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ExamResult? get latestResult => _latestResult;

  Future<void> fetchExams() async {
    _setLoading(true);
    _error = null;
    try {
      final fwuUrl = 'https://exam.fwu.edu.np/Result';
      final response = await _createResultClient().get(
        Uri.parse(fwuUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        }
      );

      if (response.statusCode == 200) {
        final html = response.body;
        // The exam list is embedded in a script tag as a JSON model
        // Look for: var model = { ... };
        final modelMatch = RegExp(r'var\s+model\s*=\s*(\{[\s\S]*?\});').firstMatch(html);
        
        if (modelMatch != null && modelMatch.group(1) != null) {
          final model = jsonDecode(modelMatch.group(1)!);
          final List<dynamic> examList = model['ExamSchedules'] ?? [];
          _exams = examList.map((e) => ExamSchedule.fromJson({
            'id': e['Id'],
            'name': e['Description'],
            'academicYearId': e['AcademicYearId'],
          })).toList();
        } else {
          _error = 'Could not find exam schedules in page source.';
        }
      } else {
        _error = 'Failed to load exams: HTTP ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Connection Error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkStudentResult(String examId, String symbolNo, String dob, String? academicYearId) async {
    _setLoading(true);
    _error = null;
    _latestResult = null;
    try {
      final fwuResultUrl = 'https://exam.fwu.edu.np/Result/Index';
      
      // Construct form data for FWU API directly
      Map<String, String> body = {
        'model[ExamScheduleId]': examId,
        'model[SymbolNo]': symbolNo,
        'model[DateOfBirthBS]': dob,
        'model[AcademicYearId]': academicYearId ?? '',
      };

      final response = await _createResultClient().post(
        Uri.parse(fwuResultUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // print full response for debugging purposes
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['IsSuccess'] == true && jsonResponse['Data'] != null) {
          final data = jsonResponse['Data'];
          // Sometimes it might just be the direct object, sometimes it might be nested
          _latestResult = ExamResult.fromFwuJson(data, examId: examId);
          return true;
        } else {
          _error = jsonResponse['Message'] ?? 'Result not found or invalid response from university server.';
          return false;
        }
      } else {
        _error = 'University Server Error: HTTP ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _error = 'Connection Error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearResult() {
    _latestResult = null;
    _error = null;
    notifyListeners();
  }
}
