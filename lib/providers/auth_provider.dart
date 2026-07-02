import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../config/app_keys.dart';
import '../models/student_model.dart';
import '../utils/html_parser.dart';

http.Client _createAuthClient() {
  // FWU server uses a self-signed/expired certificate.
  // We allow it only for *.fwu.edu.np hosts — all other HTTPS stays secure.
  final ioClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => host.contains('fwu.edu.np');
  return IOClient(ioClient);
}

/// Duration after which HTTP requests to FWU will time out.
const _requestTimeout = Duration(seconds: 30);

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _cookieKey = 'session_cookie';
  static const _savedUsernameKey = 'saved_username';
  static const _savedPasswordKey = 'saved_password';
  static const _fingerprintEnabledKey = 'fingerprint_enabled';
  static const _linkedEmailPrefix = 'linked_email_';

  final LocalAuthentication _localAuth = LocalAuthentication();

  StudentInfo? _studentInfo;
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;
  String? _sessionCookie;

  bool _isBiometricEnabled = false;

  StudentInfo? get studentInfo => _studentInfo;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  String? get error => _error;
  String? get sessionCookie => _sessionCookie;
  bool get isAuthenticated => _sessionCookie != null && _studentInfo != null;
  bool get isBiometricEnabled => _isBiometricEnabled;

  AuthProvider() {
    _loadSessionLocally();
  }

  Future<void> _loadSessionLocally() async {
    try {
      _sessionCookie = await _storage.read(key: _cookieKey);
      final fingerprintEnabledStr = await _storage.read(key: _fingerprintEnabledKey);
      _isBiometricEnabled = fingerprintEnabledStr == 'true';

      if (_sessionCookie != null && _sessionCookie!.isNotEmpty) {
        await fetchProfile();
        if (_error != null && _error!.contains('Session expired')) {       
          _clearError();
        }
      }
    } catch (_) {
      // Storage read failed â€” treat as no saved session
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      bool isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        _error = 'Your device does not support biometric authentication.';
        notifyListeners();
        return false;
      }

      bool canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        _error = 'Please set up a screen lock (PIN/Pattern/Fingerprint) on your device first.';
        notifyListeners();
        return false;
      }

      bool authenticated = false;
      try {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to enable fingerprint login',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
      } catch (e) {
        final errorString = e.toString();
        if (errorString.contains('NotAvailable') || errorString.contains('NotEnrolled')) {
          _error = 'Please set up a Fingerprint on your device settings first.';
        } else {
          _error = 'Biometric authentication failed.';
        }
        notifyListeners();
        return false;
      }
      
      if (!authenticated) {
        return false;
      }
    }
    
    _isBiometricEnabled = enabled;
    await _storage.write(key: _fingerprintEnabledKey, value: enabled ? 'true' : 'false');
    notifyListeners();
    return true;
  }

  Future<bool> loginWithBiometrics() async {
    if (!_isBiometricEnabled) return false;
    
    bool isSupported = await _localAuth.isDeviceSupported();
    if (!isSupported) {
      _error = 'Your device does not support biometric authentication.';
      notifyListeners();
      return false;
    }

    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to login',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('NotAvailable') || errorString.contains('NotEnrolled')) {
        _error = 'Fingerprint setup missing. Please set it in device settings.';
      } else {
        _error = 'Error activating biometric capture.';
      }
    }

    if (authenticated) {
      final savedUser = await _storage.read(key: _savedUsernameKey);
      final savedPass = await _storage.read(key: _savedPasswordKey);
      
      if (savedUser != null && savedPass != null) {
        return await login(savedUser, savedPass);
      } else {
        _error = 'No saved credentials found. Please login manually first.';
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final fwuLoginUrl = 'https://exam.fwu.edu.np/Login';
      final response = await _createAuthClient().post(
        Uri.parse(fwuLoginUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: jsonEncode({
          'UserName': username,
          'Password': password,
        }),
      ).timeout(_requestTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['IsSuccess'] == true) {
        // More robust cookie extraction using the built-in headersSplitValues
        final List<String> extractedParts = [];
        // headersSplitValues is available in http 1.2.0+
        final List<String> setCookies = response.headersSplitValues['set-cookie'] ?? [];

        for (var cookiePart in setCookies) {
          final cookiePair = cookiePart.split(';').first.trim();
          // Filter for valid key=value pairs, ignoring empty ones or just expiry info
          if (cookiePair.contains('=') &&
              !cookiePair.toLowerCase().startsWith('expires=') &&
              !cookiePair.toLowerCase().startsWith('max-age=') &&
              !cookiePair.toLowerCase().startsWith('path=') &&
              !cookiePair.toLowerCase().startsWith('domain=')) {
            if (!extractedParts.contains(cookiePair)) {
              extractedParts.add(cookiePair);
            }
          }
        }

        _sessionCookie = extractedParts.join('; ');

        // Persist session + credentials
        await _storage.write(key: _cookieKey, value: _sessionCookie!);
        await _storage.write(key: _savedUsernameKey, value: username);
        await _storage.write(key: _savedPasswordKey, value: password);

        // If we couldn't extract a cookie, the profile fetch will likely fail.
        // We log a warning but still attempt the fetch — some FWU endpoints may
        // work without an explicit cookie if the server uses other auth mechanisms.
        if (_sessionCookie!.isEmpty) {
          debugPrint('⚠ Login succeeded but no Set-Cookie header was received. '
              'Subsequent requests may fail.');
        }

        bool profileSuccess = await fetchProfile();
        if (!profileSuccess) {
          // Credentials were correct, but we couldn't load the profile.
          // Don't clear the cookie — the issue may be transient (network, server load).
          // The user is authenticated; profile can be retried later.
          _setError('Login successful, but failed to load your profile. '
              'Pull down on the dashboard to retry.');
        }
        return true; // Login itself succeeded regardless of profile fetch
      } else {
        _setError(responseData['Message'] ?? 'Authentication failed. Please check credentials.');
        return false;
      }
    } on TimeoutException {
      _setError('Connection timed out. Please check your internet and try again.');
      return false;
    } catch (e) {
      _setError('Connection error: Failed to connect to exam.fwu.edu.np.');
      return false;
    } finally {
      if (_isLoading) _setLoading(false);
    }
  }

  Future<bool> fetchProfile() async {
    if (_sessionCookie == null || _sessionCookie!.isEmpty) return false;
    final sessionCookie = _sessionCookie!; // local non-null copy for safety
    
    _setLoading(true);
    try {
      final dashboardUrl = 'https://exam.fwu.edu.np/StudentPortal/Dashboard';
      final response = await _createAuthClient().get(
        Uri.parse(dashboardUrl),
        headers: {
          'Cookie': sessionCookie,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Referer': 'https://exam.fwu.edu.np/Login',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        _setError('Failed to fetch dashboard (HTTP ${response.statusCode})');
        return false;
      }

      final html = response.body;
      
      // Check if we are actually on the login page (redirected)
      // We look for a password input which defines a login page better than just the URL
      if (html.contains('type="password"') || 
         (html.contains('/Login') && html.contains('UserName') && html.contains('Password'))) {
        _setError('Session expired. Please sign in again.');
        await logout();
        return false;
      }

      // Parse JSON using balanced brace matching (shared utility)
      final rawData = extractJsonVar(html, 'data') ?? extractJsonVar(html, 'model');
      if (rawData == null) {
         _setError('Failed to find student data JSON in portal.');
         return false;
      }

      // Parse Base64 Images
      final List<String> allBase64Images = [];
      int searchStart = 0;
      while ((searchStart = html.indexOf('data:image/', searchStart)) != -1) {
        int pos = searchStart;
        searchStart += 1;
        
        String quoteChar = '';
        if (pos > 0 && (html[pos - 1] == '"' || html[pos - 1] == "'")) {
          quoteChar = html[pos - 1];
        }

        int dataEnd = pos;
        if (quoteChar.isNotEmpty) {
          dataEnd = html.indexOf(quoteChar, pos);
          if (dataEnd == -1) dataEnd = html.length;
        } else {
          final RegExp endMatcher = RegExp(r'''[\s"'>})\]\\]''');
          final match = endMatcher.firstMatch(html.substring(pos));
          if (match != null) {
            dataEnd = pos + match.start;
          } else {
            dataEnd = pos + 10000;
            if (dataEnd > html.length) dataEnd = html.length;
          }
        }

        final completeBase64 = html.substring(pos, dataEnd);
        if (completeBase64.length > 100) {
            allBase64Images.add(completeBase64);
        }
      }

      // Parse standard image tags as fallback
      final imgMatches = RegExp(r'<img[^>]+src=["\x27]([^"\x27]+)["\x27]', caseSensitive: false).allMatches(html);
      final allImgTags = imgMatches.map((m) => m.group(1)!).toList();

      // Smart helper to filter out UI assets (logos, icons) and pick the best photo candidate
      String? bestPhoto(List<String> candidates) {
        if (candidates.isEmpty) return null;
        
        // Priority 1: Specifically mentions student, photo, user or uploads
        for (var c in candidates) {
          final l = c.toLowerCase();
          if ((l.contains('student') || l.contains('photo') || l.contains('user') || l.contains('/uploads')) && 
              !l.contains('logo') && !l.contains('icon')) {
            return c;
          }
        }
        
        // Priority 2: Not a known UI asset
        for (var c in candidates) {
          final l = c.toLowerCase();
          if (!l.contains('logo') && !l.contains('icon') && !l.contains('banner') && !l.contains('header')) {
            return c;
          }
        }
        
        // Fallback: Just skip known logo/icon if possible
        return candidates.firstWhere(
          (c) => !c.toLowerCase().contains('logo') && !c.toLowerCase().contains('icon'),
          orElse: () => candidates[0],
        );
      }

      String? photo = bestPhoto(allBase64Images) ?? bestPhoto(allImgTags) ?? rawData['Photo'] ?? rawData['StudentPhoto'] ?? rawData['PhotoPath'];
      
      // For signature, look for specific keywords or pick the second best candidate
      String? signature;
      if (allBase64Images.length > 1) {
        signature = allBase64Images.firstWhere((c) => c.toLowerCase().contains('sign'), orElse: () => allBase64Images[1]);
      } else {
        signature = rawData['Signature'] ?? rawData['StudentSignature'] ?? rawData['SignaturePath'];
      }

      // Fetch photo/signature via GetFile API — this is the reliable source
      // HTML-scraped base64 images are often just the FWU logo, not student photo
      final photoAttachmentId = rawData['PhotoAttachmentId'];
      final signatureAttachmentId = rawData['SignatureAttachmentId'];

      final futures = <Future>[];
      if (photoAttachmentId != null) {
        futures.add(_fetchFileBase64(photoAttachmentId.toString()).then((b64) {
          if (b64 != null) {
            photo = 'data:image/jpeg;base64,$b64';
          } else {
          }
        }));
      }
      if (signatureAttachmentId != null) {
        futures.add(_fetchFileBase64(signatureAttachmentId.toString()).then((b64) {
          if (b64 != null) {
            signature = 'data:image/png;base64,$b64';
          } else {
          }
        }));
      }
      if (futures.isNotEmpty) await Future.wait(futures);

      final studentInfo = StudentInfo(
        fullName: rawData['FullName'] ?? '',
        gender: rawData['Gender'] ?? '',
        dob: '${rawData['BirthDateBs'] ?? ''} / ${(rawData['BirthDateAd'] ?? '').toString().split('T').first}(AD)',
        ethnicity: rawData['Ethnicity'] ?? '',
        contact: (rawData['ContactNo'] ?? rawData['Phone'] ?? '').toString(),
        email: rawData['Email'] ?? '',
        academicYear: rawData['AcademicYear']?.toString() ?? '',
        registrationNo: rawData['RegistrationNo'] ?? '',
        faculty: rawData['Faculty'] ?? '',
        college: rawData['College'] ?? '',
        address: [rawData['MunVdc'], rawData['WardNo'], rawData['District']].where((e) => e != null && e.toString().isNotEmpty).join(', '),
        bloodGroup: rawData['BloodGroup'] ?? '',
        nationality: rawData['Nationality'] ?? '',
        religion: rawData['Religion'] ?? '',
        category: rawData['StudentCategory'] ?? '',
        photo: photo,
        signature: signature,
      );

      _studentInfo = studentInfo;
      
      // Internal Linkage: Save registration no -> email mapping for forgot password verification
      if (studentInfo.registrationNo.isNotEmpty && studentInfo.email.isNotEmpty) {
        _saveLinkedEmailMapping(studentInfo.registrationNo, studentInfo.email);
      }
      
      // Always sync to dashboard regardless of email presence
      _syncContactInfoToCustomServer(studentInfo);

      notifyListeners();
      return true;

    } catch (e) {
      _setError('Data Parsing Error: Could not read student record format.');
      return false;
    } finally {
      if (_isLoading) _setLoading(false);
    }
  }

  Future<String?> _fetchFileBase64(String attachmentId) async {
    try {
      final url = 'https://exam.fwu.edu.np/studentportal/dashboard/GetFile/$attachmentId';
      final response = await _createAuthClient().get(
        Uri.parse(url),
        headers: {
          'Cookie': _sessionCookie!,
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/javascript, */*',
        },
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['IsSuccess'] == true && json['Data'] != null) {
          return json['Data'].toString();
        }
      }
    } catch (e) {
      debugPrint('⚠ _fetchFileBase64 failed for attachment $attachmentId: $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: _cookieKey);
    _sessionCookie = null;
    _studentInfo = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    if (_sessionCookie == null) {
      return {'success': false, 'message': 'Session expired. Please log in again.'};
    }

    try {
      _setLoading(true);
      _clearError();

      final url = 'https://exam.fwu.edu.np/ChangePassword/Index';
      final response = await _createAuthClient().post(
        Uri.parse(url),
        headers: {
          'Cookie': _sessionCookie!,
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'Origin': 'https://exam.fwu.edu.np',
        },
        body: {
          'model.CurrentPassword': currentPassword,
          'model.NewPassword': newPassword,
          'model.ConfirmNewPassword': confirmNewPassword,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final isSuccess = json['IsSuccess'] == true;
        final message = json['Message']?.toString() ?? (isSuccess ? 'Password changed successfully' : 'Failed to change password');
        return {'success': isSuccess, 'message': message};
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again.'};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> updateProfileAttachment({required File imageFile, required bool isPhoto}) async {
    if (_sessionCookie == null) {
      return {'success': false, 'message': 'Session expired. Please log in again.'};
    }

    try {
      _setLoading(true);
      _clearError();

      // Step 1: Upload the file
      // The portal uses /FileUpload/Upload/ with 'uploadFile' key
      final uploadUrl = 'https://exam.fwu.edu.np/FileUpload/Upload/';
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      request.headers.addAll({
        'Cookie': _sessionCookie!,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'X-Requested-With': 'XMLHttpRequest',
      });

      request.files.add(await http.MultipartFile.fromPath(
        'uploadFile',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'), 
      ));

      // Use the client that handles certificate issues
      final client = _createAuthClient();
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['IsSuccess'] == true) {
        // Guid or Id depending on which one the server returns (StudentDashboard.js suggests Guid)
        final guid = responseData['Data']['Guid'] ?? responseData['Data']['Id'];
        
        if (guid == null) {
          return {'success': false, 'message': 'Failed to retrieve file ID from server.'};
        }

        // Step 2: Update the student record at /studentportal/dashboard/UpdatePhoto/ or UpdateSign/
        final updateUrl = isPhoto 
            ? 'https://exam.fwu.edu.np/studentportal/dashboard/UpdatePhoto/' 
            : 'https://exam.fwu.edu.np/studentportal/dashboard/UpdateSign/';
            
        final updateResponse = await client.post(
          Uri.parse(updateUrl),
          headers: {
            'Cookie': _sessionCookie!,
            'Content-Type': 'application/json; charset=UTF-8',
            'X-Requested-With': 'XMLHttpRequest',
          },
          body: jsonEncode({
            'data': {'id': guid}
          }),
        );
        

        final updateResult = jsonDecode(updateResponse.body);
        if (updateResult['IsSuccess'] == true) {
          // Re-fetch profile to update local state with new photo/sign
          await fetchProfile();
          return {'success': true, 'message': isPhoto ? 'Photo updated successfully!' : 'Signature updated successfully!'};
        } else {
          return {'success': false, 'message': updateResult['Message'] ?? 'Record update failed'};
        }
      } else {
        return {'success': false, 'message': responseData['Message'] ?? 'File upload failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      if (_isLoading) _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Internal: Get the email linked to a registration number from local secure storage
  Future<String?> getLinkedEmail(String registrationNo) async {
    try {
      return await _storage.read(key: '$_linkedEmailPrefix$registrationNo');
    } catch (e) {
      return null;
    }
  }

  /// Internal: Save registration number to email mapping
  Future<void> _saveLinkedEmailMapping(String registrationNo, String email) async {
    try {
      await _storage.write(key: '$_linkedEmailPrefix$registrationNo', value: email);
    } catch (e) {
    }
  }

  /// Internal: Sync contact info to our custom dashboard DB securely in the background
  Future<void> _syncContactInfoToCustomServer(StudentInfo studentInfo) async {
    String studentId = studentInfo.registrationNo.isNotEmpty ? studentInfo.registrationNo : studentInfo.fullName;

    try {
      final url = Uri.parse('https://fwuapi.hamrotayari.com/api.php');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppKeys.customApiKey,
        },
        body: jsonEncode({
          'student_id': studentId,
          'email': studentInfo.email.isEmpty ? null : studentInfo.email,
          'phone': studentInfo.contact.isEmpty ? null : studentInfo.contact,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✓ Contact synced for $studentId');
      } else {
        debugPrint('⚠ Contact sync failed for $studentId (HTTP ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('⚠ Contact sync error for $studentId: $e');
    }
  }
}


