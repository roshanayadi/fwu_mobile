import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import '../models/form_model.dart';
import '../utils/html_parser.dart';

/// Shared HTTP client that allows FWU's self-signed certificate.
http.Client _createClient() {
  final ioClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => host.contains('fwu.edu.np');
  return IOClient(ioClient);
}

class FormProvider extends ChangeNotifier {
  List<ExamSchedule> _examSchedules = [];
  ExamFormData? _currentForm;
  bool _isLoading = false;
  String? _error;
  String? _submitMessage;

  List<ExamSchedule> get examSchedules => _examSchedules;
  ExamFormData? get currentForm => _currentForm;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get submitMessage => _submitMessage;

  static const _fwuBase = 'https://exam.fwu.edu.np';
  static const _ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// Fetch ExamSchedules — tries /StudentPortal/Dashboard first, then /StudentPortal
  Future<void> fetchExamSchedules(String? sessionCookie) async {
    if (sessionCookie == null || sessionCookie.isEmpty) {
      _error = 'Please login first.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try both pages — Dashboard is more reliable, /StudentPortal has ExamSchedules
      final urls = [
        '$_fwuBase/StudentPortal/Dashboard',
        '$_fwuBase/StudentPortal',
      ];

      Map<String, dynamic>? data;
      for (final url in urls) {
        try {
          final response = await _createClient().get(
            Uri.parse(url),
            headers: {
              'Cookie': sessionCookie,
              'User-Agent': _ua,
              'Accept': 'text/html,application/xhtml+xml,*/*',
              'Referer': '$_fwuBase/Login',
            },
          ).timeout(const Duration(seconds: 30));


          if (response.statusCode != 200) continue;

          final html = response.body;
          if (html.contains('type="password"') ||
              (html.contains('UserName') && html.contains('Password'))) {
            _error = 'Session expired. Please login again.';
            _isLoading = false;
            notifyListeners();
            return;
          }

          data = extractJsonVar(html, 'data') ?? extractJsonVar(html, 'model');
          if (data != null && data['ExamSchedules'] != null) {
            break;
          }
        } catch (e) {
        }
      }

      if (data == null) {
        _error = 'Could not load portal data.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final schedulesList = data['ExamSchedules'] as List? ?? [];
      _examSchedules = schedulesList
          .map((s) => ExamSchedule.fromJson(s as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _error = 'Connection error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize + load the exam form for a given schedule
  Future<ExamFormData?> fetchExamForm(
    int studentAdmissionId,
    int examScheduleId,
    String sessionCookie,
  ) async {
    _isLoading = true;
    _error = null;
    _currentForm = null;
    notifyListeners();

    try {
      // Step 1: POST Initialize
      final initBody = 'studentAdmissionId=$studentAdmissionId&examScheduleId=$examScheduleId';
      final initResponse = await _createClient().post(
        Uri.parse('$_fwuBase/StudentPortal/Application/Initialize'),
        headers: {
          'Cookie': sessionCookie,
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': _ua,
        },
        body: initBody,
      ).timeout(const Duration(seconds: 30));


      if (initResponse.statusCode == 200) {
        try {
          final initJson = jsonDecode(initResponse.body);
          if (initJson['IsSuccess'] != true) {
            _error = initJson['Message'] ?? 'Failed to initialize form.';
            _isLoading = false;
            notifyListeners();
            return null;
          }
        } catch (_) {
          // Non-JSON response may be OK (redirect)
        }
      }

      // Step 2: GET the form page
      final formResponse = await _createClient().get(
        Uri.parse('$_fwuBase/StudentPortal/Application/Index'),
        headers: {
          'Cookie': sessionCookie,
          'User-Agent': _ua,
          'Accept': 'text/html,application/xhtml+xml,*/*',
        },
      ).timeout(const Duration(seconds: 30));

      if (formResponse.statusCode != 200) {
        _error = 'Failed to load form (HTTP ${formResponse.statusCode})';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final html = formResponse.body;
      final data = extractJsonVar(html, 'data') ?? extractJsonVar(html, 'model');
      if (data == null) {
        _error = 'Could not parse form data.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Detect page type
      String pageType = 'unknown';
      String? pageMessage;
      final msgMatch = RegExp(r'<div class="ibox-content">\s*<p>(.*?)</p>').firstMatch(html);
      if (msgMatch != null) pageMessage = msgMatch.group(1)?.trim();

      if (data['SubjectGroups'] != null) {
        pageType = 'examForm';
      } else if (pageMessage != null && pageMessage.toLowerCase().contains('expired')) {
        pageType = 'expired';
      } else if (data['PaymentAmount'] != null) {
        pageType = 'payment';
      }

      final subjectGroups = (data['SubjectGroups'] as List? ?? [])
          .map((g) => SubjectGroup.fromJson(g as Map<String, dynamic>))
          .toList();

      final examSchedule = data['ExamSchedule'] as Map<String, dynamic>? ?? {};
      final studentInfo = data['StudentInfo'] as Map<String, dynamic>? ?? {};

      _currentForm = ExamFormData(
        rawModel: data,
        subjectGroups: subjectGroups,
        isRegular: data['IsRegular'] == true,
        examScheduleId: data['ExamScheduleId'],
        examRegistrationId: data['ExamRegistrationId'],
        examScheduleName: examSchedule['ExamScheduleName']?.toString(),
        studentName: studentInfo['FullName']?.toString(),
        programName: studentInfo['ProgramName']?.toString(),
        pageType: pageType,
        message: pageMessage,
        paymentAmount: (data['PaymentAmount'] ?? 0).toDouble(),
        ratePerSubject: (data['RatePerSubject'] ?? 0).toDouble(),
        isSeparatePaymentForPractical: data['IsSeparatePaymentForPractical'] == true,
        isPaid: data['IsPaid'] == true,
        moduleSettings: data['ModuleSettings'] as Map<String, dynamic>? ?? {},
        practicalSubjectsCount: data['PracticalSubjectsCount'] ?? 0,
      );

      return _currentForm;
    } catch (e) {
      _error = 'Error loading form: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit the form by POSTing the full model with subject selections
  Future<bool> submitExamForm(String sessionCookie) async {
    if (_currentForm == null) {
      _error = 'No form loaded.';
      return false;
    }

    _isLoading = true;
    _error = null;
    _submitMessage = null;
    notifyListeners();

    try {
      // Update the raw model with current checkbox selections
      final model = Map<String, dynamic>.from(_currentForm!.rawModel);
      final groups = model['SubjectGroups'] as List? ?? [];
      for (int gi = 0; gi < _currentForm!.subjectGroups.length; gi++) {
        final group = _currentForm!.subjectGroups[gi];
        for (int ti = 0; ti < group.subjectTypes.length; ti++) {
          final type = group.subjectTypes[ti];
          for (int si = 0; si < type.subjects.length; si++) {
            final sub = type.subjects[si];
            if (gi < groups.length) {
              final gTypes = (groups[gi] as Map)['SubjectTypes'] as List? ?? [];
              if (ti < gTypes.length) {
                final tSubs = (gTypes[ti] as Map)['Subjects'] as List? ?? [];
                if (si < tSubs.length) {
                  (tSubs[si] as Map)['IsTheorySelected'] = sub.isTheorySelected;
                  (tSubs[si] as Map)['IsPracticalSelected'] = sub.isPracticalSelected;
                }
              }
            }
          }
        }
      }

      // Flatten to form-encoded (matches jQuery $.param() bracket notation)
      final params = <String, String>{};
      void flatten(dynamic obj, String prefix) {
        if (obj is List) {
          for (int i = 0; i < obj.length; i++) {
            flatten(obj[i], '$prefix[$i]');
          }
        } else if (obj is Map) {
          for (final key in obj.keys) {
            flatten(obj[key], prefix.isEmpty ? '$key' : '$prefix[$key]');
          }
        } else {
          params[prefix] = obj?.toString() ?? '';
        }
      }
      flatten(model, '');

      final response = await _createClient().post(
        Uri.parse('$_fwuBase/StudentPortal/Application/Index'),
        headers: {
          'Cookie': sessionCookie,
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': _ua,
          'Referer': '$_fwuBase/StudentPortal/Application/Index',
        },
        body: params.entries.map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}'
        ).join('&'),
      ).timeout(const Duration(seconds: 30));


      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body);
          if (json['IsSuccess'] == true) {
            _submitMessage = json['Message'] ?? 'Form submitted successfully!';
            return true;
          } else {
            _error = json['Message'] ?? 'Submission failed.';
            return false;
          }
        } catch (_) {
          // Non-JSON response — could be a redirect/success page
          _submitMessage = 'Form submitted.';
          return true;
        }
      } else {
        _error = 'Submission failed (HTTP ${response.statusCode})';
        return false;
      }
    } catch (e) {
      _error = 'Error submitting form: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initiate payment with a specific gateway. Returns a URL to open in browser,
  /// or null on failure.
  Future<Map<String, dynamic>?> payWithGateway(String gateway, String sessionCookie) async {
    if (_currentForm == null) {
      _error = 'No form loaded.';
      return null;
    }

    final endpointMap = {
      'esewa': '/studentportal/application/Esewa',
      'khalti': '/studentportal/application/Khalti',
      'connectips': '/studentportal/application/ConnectIps',
      'hbl': '/studentportal/application/HBL',
    };

    final endpoint = endpointMap[gateway];
    if (endpoint == null) {
      _error = 'Unknown gateway.';
      return null;
    }

    try {
      // Update practicalSubjectsCount in rawModel
      final model = Map<String, dynamic>.from(_currentForm!.rawModel);
      model['PracticalSubjectsCount'] = _currentForm!.practicalSubjectsCount;
      model['TotalAmount'] = _currentForm!.totalAmount;

      // Flatten to form-encoded: model.Key=Value
      final params = <String, String>{};
      void flattenModel(dynamic obj, String prefix) {
        if (obj is List) {
          for (int i = 0; i < obj.length; i++) {
            flattenModel(obj[i], '$prefix[$i]');
          }
        } else if (obj is Map) {
          for (final key in obj.keys) {
            flattenModel(obj[key], prefix.isEmpty ? 'model.$key' : '$prefix.$key');
          }
        } else {
          params[prefix] = obj?.toString() ?? '';
        }
      }
      flattenModel(model, '');


      final response = await _createClient().post(
        Uri.parse('$_fwuBase$endpoint'),
        headers: {
          'Cookie': sessionCookie,
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': _ua,
          'Referer': '$_fwuBase/StudentPortal/Application/Index',
        },
        body: params.entries.map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}'
        ).join('&'),
      ).timeout(const Duration(seconds: 30));


      if (response.statusCode != 200) {
        _error = 'Payment request failed (HTTP ${response.statusCode})';
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['IsSuccess'] != true) {
        _error = json['Message']?.toString() ?? 'Payment initiation failed.';
        return null;
      }

      final gdata = json['Data'] as Map<String, dynamic>? ?? {};
      return {'gateway': gateway, ...gdata};
    } catch (e) {
      _error = 'Payment error: $e';
      return null;
    }
  }

  /// Build a payment gateway URL for form-POST gateways (eSewa, ConnectIPS, HBL).
  /// Returns a data: URI that auto-submits or just returns gateway data.
  String? buildGatewayFormHtml(String gateway, Map<String, dynamic> gdata) {
    String? actionUrl;
    Map<String, String> fields = {};

    if (gateway == 'esewa') {
      actionUrl = gdata['PostUrl']?.toString();
      fields = {
        'amount': gdata['Amount']?.toString() ?? '',
        'tax_amount': '0',
        'total_amount': gdata['Amount']?.toString() ?? '',
        'transaction_uuid': gdata['InvoiceNo']?.toString() ?? '',
        'product_code': (gdata['ProductCode'] ?? gdata['MerchantCode'])?.toString() ?? '',
        'product_service_charge': '0',
        'product_delivery_charge': '0',
        'success_url': gdata['SuccessUrl']?.toString() ?? '',
        'failure_url': (gdata['FailureUrl'] ?? gdata['FailUrl'])?.toString() ?? '',
        'signed_field_names': gdata['SignedFieldNames']?.toString() ?? 'total_amount,transaction_uuid,product_code',
        'signature': gdata['Signature']?.toString() ?? '',
      };
    } else if (gateway == 'connectips') {
      actionUrl = gdata['GatewayUrl']?.toString();
      fields = {
        'MERCHANTID': gdata['MerchantId']?.toString() ?? '',
        'APPID': gdata['AppId']?.toString() ?? '',
        'APPNAME': gdata['AppName']?.toString() ?? '',
        'TXNID': gdata['TxnId']?.toString() ?? '',
        'TXNDATE': gdata['TxnDate']?.toString() ?? '',
        'TXNCRNCY': gdata['TransactionCurrency']?.toString() ?? '',
        'TXNAMT': gdata['Amount']?.toString() ?? '',
        'REFERENCEID': gdata['ReferenceId']?.toString() ?? '',
        'REMARKS': gdata['Remarks']?.toString() ?? '',
        'PARTICULARS': gdata['Particulars']?.toString() ?? '',
        'TOKEN': gdata['Token']?.toString() ?? '',
      };
    } else if (gateway == 'hbl') {
      actionUrl = gdata['PostUrl']?.toString();
      fields = {
        'paymentGatewayID': gdata['PaymentGatewayId']?.toString() ?? '',
        'invoiceNo': gdata['InvoiceNo']?.toString() ?? '',
        'productDesc': gdata['ProductDesc']?.toString() ?? '',
        'amount': gdata['Amount']?.toString() ?? '',
        'currencyCode': gdata['CurrencyCode']?.toString() ?? '',
        'userDefined1': gdata['UserDefined1']?.toString() ?? '',
        'userDefined2': gdata['UserDefined2']?.toString() ?? '',
        'userDefined3': gdata['UserDefined3']?.toString() ?? '',
        'userDefined4': gdata['UserDefined4']?.toString() ?? '',
        'hashValue': gdata['HashValue']?.toString() ?? '',
        'nonSecure': gdata['NonSecure']?.toString() ?? '',
      };
    }

    if (actionUrl == null) {
      return null;
    }

    // Build auto-submit HTML page
    final inputsHtml = fields.entries
      .map((e) => '<input type="hidden" name="${_htmlEscape(e.key)}" value="${_htmlEscape(e.value)}">')
      .join('\n');

    return '''<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>body{display:flex;justify-content:center;align-items:center;height:100vh;margin:0;font-family:sans-serif;background:#f5f5f5;}p{color:#666;font-size:16px;}</style>
</head><body>
<p>Redirecting to payment gateway...</p>
<form id="pf" method="POST" action="${_htmlEscape(actionUrl)}">
$inputsHtml
</form>
<script>document.getElementById('pf').submit();</script>
</body></html>''';
  }

  static String _htmlEscape(String s) {
    return s.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  }

  /// Download admit card PDF for the given exam schedule
  Future<String?> downloadAdmitCard(int examScheduleId, String sessionCookie) async {
    _error = null;
    try {
      final url = Uri.parse('$_fwuBase/registration/default/downloadadmitcardbystudent?examscheduleId=$examScheduleId');

      final request = http.Request('GET', url);
      request.headers.addAll({
        'Cookie': sessionCookie,
        'User-Agent': _ua,
        'Accept': 'application/pdf,*/*',
      });
      request.followRedirects = true;
      request.maxRedirects = 5;

      final streamedResponse = await _createClient().send(request).timeout(const Duration(seconds: 60));
      if (streamedResponse.statusCode != 200) {
        _error = 'Failed to download admit card (${streamedResponse.statusCode}).';
        return null;
      }

      final bytes = await streamedResponse.stream.toBytes();
      if (bytes.isEmpty) {
        _error = 'Empty response from server.';
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/admit_card_$examScheduleId.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      _error = 'Download failed: $e';
      return null;
    }
  }

}
