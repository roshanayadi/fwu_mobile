import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;

class PaymentWebViewScreen extends StatefulWidget {
  final String gatewayHtml;
  final String title;

  /// Called when FWU redirects to a success URL
  final VoidCallback? onPaymentSuccess;

  /// Called when FWU redirects to a failure/cancel URL
  final VoidCallback? onPaymentFailure;

  const PaymentWebViewScreen({
    super.key,
    required this.gatewayHtml,
    required this.title,
    this.onPaymentSuccess,
    this.onPaymentFailure,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  bool _loading = true;
  double _progress = 0;

  Future<void> _confirmClose() async {
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Payment?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to close? If your payment is still processing, it may not be completed.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (shouldClose == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _downloadAndSaveFile(Uri url, {String? suggestedFilename}) async {
    try {
      // Show downloading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Downloading...'),
              ],
            ),
            duration: const Duration(seconds: 30),
            backgroundColor: const Color(0xFF0F6E56),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      // Determine filename
      String filename = suggestedFilename ?? '';
      if (filename.isEmpty) {
        // Try from content-disposition header
        final disposition = response.headers['content-disposition'] ?? '';
        final match = RegExp(r'filename[*]?="?([^";]+)"?').firstMatch(disposition);
        if (match != null) {
          filename = match.group(1)!.trim();
        }
      }
      if (filename.isEmpty) {
        // Fallback: use last path segment
        filename = url.pathSegments.isNotEmpty ? url.pathSegments.last : 'download';
      }
      // Ensure an extension
      if (!filename.contains('.')) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('pdf')) {
          filename += '.pdf';
        } else if (contentType.contains('jpeg') || contentType.contains('jpg')) {
          filename += '.jpg';
        } else if (contentType.contains('png')) {
          filename += '.png';
        } else {
          filename += '.bin';
        }
      }

      // Save to Downloads-like directory
      Directory saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          saveDir = await getApplicationDocumentsDirectory();
        }
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }

      // Avoid overwriting — append number if file exists
      String savePath = '${saveDir.path}/$filename';
      int counter = 1;
      while (await File(savePath).exists()) {
        final dotIndex = filename.lastIndexOf('.');
        final name = dotIndex > 0 ? filename.substring(0, dotIndex) : filename;
        final ext = dotIndex > 0 ? filename.substring(dotIndex) : '';
        savePath = '${saveDir.path}/${name}_($counter)$ext';
        counter++;
      }

      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved: ${file.uri.pathSegments.last}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(savePath),
            ),
            backgroundColor: const Color(0xFF0F6E56),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// Shows a beautiful success/failure dialog and pops back with result
  Future<void> _showPaymentResultDialog({required bool success}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: success
                    ? const Color(0xFFD5F5E3)
                    : const Color(0xFFFFE5E5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: success
                    ? const Color(0xFF1E8449)
                    : const Color(0xFFD32F2F),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Payment Successful!' : 'Payment Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: success
                    ? const Color(0xFF1E8449)
                    : const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              success
                  ? 'Your payment has been received.\nYou can now fill in your exam form.'
                  : 'Your payment was not completed.\nPlease try again or choose another method.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF555555),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: success
                      ? const Color(0xFF0F6E56)
                      : const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  success ? 'Continue' : 'Try Again',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Fire callback and pop WebView
    if (mounted) {
      if (success) {
        widget.onPaymentSuccess?.call();
      } else {
        widget.onPaymentFailure?.call();
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
          title: Text(widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmClose,
          ),
        ),
        body: Column(
          children: [
            if (_loading)
              LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null, minHeight: 2),
            Expanded(
              child: InAppWebView(
                initialData: InAppWebViewInitialData(data: widget.gatewayHtml),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  domStorageEnabled: true,
                  supportMultipleWindows: false,
                  javaScriptCanOpenWindowsAutomatically: true,
                  useOnDownloadStart: true,
                ),
                onWebViewCreated: (controller) {
                },
                onLoadStart: (controller, url) {
                  if (mounted) setState(() => _loading = true);
                },
                onLoadStop: (controller, url) {
                  if (mounted) setState(() => _loading = false);
                },
                onProgressChanged: (controller, progress) {
                  if (mounted) setState(() => _progress = progress / 100);
                },
                onReceivedError: (controller, request, error) {
                },
                onReceivedHttpError: (controller, request, response) {
                },
                onDownloadStartRequest: (controller, request) async {
                  await _downloadAndSaveFile(
                    request.url,
                    suggestedFilename: request.suggestedFilename,
                  );
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url;
                  if (url != null) {
                    final urlStr = url.toString().toLowerCase();

                    // ── Payment SUCCESS detection ──────────────────────────
                    // FWU redirects to these patterns on successful payment:
                    // - /studentportal/application/esewaverify
                    // - /studentportal/application/khaltiverify
                    // - /studentportal/application/connectipsverify
                    // - /studentportal/application/hblverify
                    // - any URL containing 'success', 'complete', 'thankyou', 'paid'
                    final isSuccess =
                        urlStr.contains('verify') ||
                        urlStr.contains('success') ||
                        urlStr.contains('complete') ||
                        urlStr.contains('thankyou') ||
                        urlStr.contains('thank-you') ||
                        urlStr.contains('/paid') ||
                        (urlStr.contains('fwu.edu.np') && urlStr.contains('payment') && urlStr.contains('ok'));

                    // ── Payment FAILURE / CANCEL detection ────────────────
                    final isFailure =
                        urlStr.contains('fail') ||
                        urlStr.contains('cancel') ||
                        urlStr.contains('decline') ||
                        urlStr.contains('error') && urlStr.contains('payment');

                    if (isSuccess) {
                      if (mounted) {
                        _showPaymentResultDialog(success: true);
                      }
                      return NavigationActionPolicy.CANCEL;
                    }

                    if (isFailure) {
                      if (mounted) {
                        _showPaymentResultDialog(success: false);
                      }
                      return NavigationActionPolicy.CANCEL;
                    }

                    // ── File download detection ────────────────────────────
                    if (urlStr.endsWith('.pdf') ||
                        urlStr.endsWith('.jpg') ||
                        urlStr.endsWith('.png') ||
                        urlStr.endsWith('.jpeg') ||
                        urlStr.endsWith('.doc') ||
                        urlStr.endsWith('.docx') ||
                        urlStr.endsWith('.xls') ||
                        urlStr.endsWith('.xlsx') ||
                        (urlStr.contains('download') && urlStr.contains('file'))) {
                      _downloadAndSaveFile(url);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
