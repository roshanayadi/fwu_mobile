import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/app_keys.dart';

class SmtpService {
  static String get _username => AppKeys.smtpUser;
  static String get _password => AppKeys.smtpPass;

  static String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6 digit OTP
  }

  static Future<bool> sendOtpEmail(String recipientEmail, String otp) async {
    // In development without credentials, simulate success after a brief delay.
    // Set SMTP_USER / SMTP_PASS in .env for production.
    if (_username.isEmpty || _password.isEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }

    final smtpServer = gmail(_username, _password);

    final message = Message()
      ..from = Address(_username, 'Far-Western University')
      ..recipients.add(recipientEmail)
      ..subject = 'FWU Portal: Password Reset Verification Code'
      ..html =
          '''
        <div style="font-family: sans-serif; padding: 20px;">
          <h3>Your Verification Code</h3>
          <p>You requested to reset your password for the Far Western University Exam Portal.</p>
          <p>Please use the following 6-digit code to verify your identity:</p>
          <h2 style="color: #3B82F6; letter-spacing: 2px;">$otp</h2>
          <p>If you did not request this, please ignore this email.</p>
        </div>
      ''';

    try {
      await send(message, smtpServer);
      return true;
    } on MailerException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
