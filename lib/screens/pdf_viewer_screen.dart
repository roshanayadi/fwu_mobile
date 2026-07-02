import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String category;
  final Color categoryColor;
  final bool autoDownload;

  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.category,
    required this.categoryColor,
    this.autoDownload = false,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

enum _ViewState { fetching, rendering, error, downloading, downloadDone }

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF0F6E56);
  static const _dark = Color(0xFF1E2328);

  _ViewState _state = _ViewState.fetching;
  double _fetchProgress = 0;
  double _downloadProgress = 0;
  String _errorMsg = '';
  String? _htmlContent;  // populated after bytes are fetched

  InAppWebViewController? _webController;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoDownload) {
        _saveToDocuments();
      } else {
        _fetchAndRender();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Step 1: Fetch bytes in Dart (no CORS), embed in PDF.js HTML ──────────
  Future<void> _fetchAndRender() async {
    // If it's a DOCX file, bypass PDF.js and use Microsoft Office Online Viewer
    if (widget.url.toLowerCase().endsWith('.docx')) {
      setState(() => _state = _ViewState.rendering);
      final encodedUrl = Uri.encodeComponent(widget.url);
      final docxUrl = 'https://view.officeapps.live.com/op/view.aspx?src=$encodedUrl';
      _webController?.loadUrl(urlRequest: URLRequest(url: WebUri(docxUrl)));
      return;
    }

    setState(() {
      _state = _ViewState.fetching;
      _fetchProgress = 0;
    });

    try {
      final request = http.Request('GET', Uri.parse(widget.url));
      final streamed = await http.Client().send(request);
      
      if (streamed.statusCode != 200) {
        throw Exception('Server returned error ${streamed.statusCode}');
      }

      final total = streamed.contentLength ?? 0;
      int received = 0;
      final chunks = <int>[];

      await streamed.stream.listen((chunk) {
        chunks.addAll(chunk);
        received += chunk.length;
        if (total > 0) setState(() => _fetchProgress = received / total);
      }).asFuture();

      final bytes = Uint8List.fromList(chunks);
      
      // Verify PDF magic bytes (%PDF-) to prevent rendering 404 HTML pages
      if (bytes.length >= 5) {
        final magic = String.fromCharCodes(bytes.take(5));
        if (magic != '%PDF-') {
          throw Exception('The file on the server is corrupted or missing (not a valid PDF).');
        }
      }

      if (!mounted) return;
      // Store HTML in state so initialData picks it up when WebView is built
      setState(() {
        _htmlContent = _buildHtml(bytes);
        _state = _ViewState.rendering;
      });
      
      // If webController is already created (e.g., from retry), load the data directly
      if (_webController != null) {
        _webController?.loadData(
          data: _htmlContent ?? '',
          mimeType: 'text/html',
          encoding: 'utf-8',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ViewState.error;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ─── Build PDF.js HTML with base64-embedded PDF ───────────────────────────
  String _buildHtml(Uint8List bytes) {
    final b64 = base64Encode(bytes);
    return '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=3">
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body { background:#323639; }
    #pages { width:100%; padding:8px 0; }
    canvas { display:block; margin:0 auto 8px; max-width:100%;
             box-shadow:0 3px 10px rgba(0,0,0,.5); }
    #msg { color:#fff; text-align:center; padding:40px 20px;
           font:16px sans-serif; opacity:.8; }
  </style>
</head>
<body>
  <div id="msg">Rendering pages...</div>
  <div id="pages"></div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
  <script>
    pdfjsLib.GlobalWorkerOptions.workerSrc =
      'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

    const b64 = '$b64';
    const bin = atob(b64);
    const buf = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);

    pdfjsLib.getDocument({ data: buf }).promise.then(function(pdf) {
      document.getElementById('msg').style.display = 'none';
      const container = document.getElementById('pages');
      const n = pdf.numPages;
      let rendered = 0;

      function renderPage(num) {
        pdf.getPage(num).then(function(page) {
          const ratio = window.devicePixelRatio || 1;
          const cssWidth = window.innerWidth - 16;
          const scale = cssWidth / page.getViewport({scale:1}).width;
          const vp = page.getViewport({scale: scale});
          
          const canvas = document.createElement('canvas');
          const ctx = canvas.getContext('2d');
          
          // High-DPI canvas scaling for crisp text
          canvas.width  = vp.width * ratio;
          canvas.height = vp.height * ratio;
          canvas.style.width  = vp.width + 'px';
          canvas.style.height = vp.height + 'px';
          
          ctx.scale(ratio, ratio);
          container.appendChild(canvas);
          
          page.render({canvasContext: ctx, viewport: vp})
              .promise.then(function() {
            rendered++;
            if (num < n) renderPage(num + 1);
          });
        });
      }
      renderPage(1);
    }).catch(function(err) {
      document.getElementById('msg').textContent = 'Render error: ' + err.message;
    });
  </script>
</body>
</html>''';
  }

  // ─── Save to Documents + open ─────────────────────────────────────────────
  Future<void> _saveToDocuments() async {
    setState(() {
      _state = _ViewState.downloading;
      _downloadProgress = 0;
    });

    try {
      final request = http.Request('GET', Uri.parse(widget.url));
      final streamed = await http.Client().send(request);
      
      if (streamed.statusCode != 200) {
        throw Exception('Server returned error ${streamed.statusCode}');
      }

      final total = streamed.contentLength ?? 0;
      int received = 0;
      final chunks = <int>[];

      await streamed.stream.listen((chunk) {
        chunks.addAll(chunk);
        received += chunk.length;
        if (total > 0) setState(() => _downloadProgress = received / total);
      }).asFuture();

      final dir = await getApplicationDocumentsDirectory();
      final ext = widget.url.endsWith('.docx') ? '.docx' : '.pdf';
      final path = '${dir.path}/${_sanitize(widget.title)}$ext';
      await File(path).writeAsBytes(chunks);

      setState(() => _state = _ViewState.downloadDone);
      if (!mounted) return;
      _showSuccessSnackbar();
      await OpenFilex.open(path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ViewState.error;
        _errorMsg = e.toString();
      });
    }
  }

  String _sanitize(String s) {
    final c = s.replaceAll(RegExp(r'[<>:"/\\|?*\u0000-\u001F]'), '_')
               .replaceAll(RegExp(r'\s+'), '_');
    return c.length > 60 ? c.substring(0, 60) : c;
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: _appBar(),
      body: _body(),
      floatingActionButton: _state == _ViewState.rendering ? _fab() : null,
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF161A1E),
      foregroundColor: Colors.white,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Row(children: [
            _badge(widget.category, widget.categoryColor),
            const SizedBox(width: 6),
            _badge(
                widget.url.endsWith('.docx') ? 'DOCX' : 'PDF',
                Colors.redAccent),
          ]),
        ],
      ),
      actions: [
        if (_state == _ViewState.rendering)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _fetchAndRender,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.9))),
      );

  Widget _body() {
    switch (_state) {
      case _ViewState.fetching:
        return _fetchingUI();
      case _ViewState.rendering:
        return _renderingUI();
      case _ViewState.error:
        return _errorUI();
      case _ViewState.downloading:
        return _downloadingUI();
      case _ViewState.downloadDone:
        return _downloadDoneUI();
    }
  }

  // ── Fetching bytes ────────────────────────────────────────────────────────
  Widget _fetchingUI() {
    return Container(
      color: _dark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) =>
                    Transform.scale(scale: _pulseAnim.value, child: child),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      size: 46, color: _primary),
                ),
              ),
              const SizedBox(height: 28),
              Text('Loading Document',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text('Fetching from FWU server...',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55))),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _fetchProgress > 0 ? _fetchProgress : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: _primary,
                  minHeight: 6,
                ),
              ),
              if (_fetchProgress > 0) ...[
                const SizedBox(height: 10),
                Text('${(_fetchProgress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primary)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // ── WebView rendering ─────────────────────────────────────────────────────
  Widget _renderingUI() {
    // If it's DOCX, initialData isn't used, we load URL directly
    final isDocx = widget.url.toLowerCase().endsWith('.docx');
    
    return InAppWebView(
      // _htmlContent is guaranteed non-null when state == rendering (for PDF)
      initialData: isDocx 
          ? null 
          : InAppWebViewInitialData(
              data: _htmlContent ?? '',
              mimeType: 'text/html',
              encoding: 'utf-8',
            ),
      initialUrlRequest: isDocx 
          ? URLRequest(url: WebUri('https://view.officeapps.live.com/op/view.aspx?src=${Uri.encodeComponent(widget.url)}'))
          : null,
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        builtInZoomControls: true,
        displayZoomControls: false,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
      ),
      onWebViewCreated: (ctrl) => _webController = ctrl,
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _errorUI() {
    return Container(
      color: _dark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded,
                    size: 42, color: Colors.red.shade400),
              ),
              const SizedBox(height: 20),
              Text('Could Not Load Document',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 10),
              Text(
                _errorMsg.isNotEmpty
                    ? 'Error: $_errorMsg\n\nYou can download the file and view it using your device\'s PDF reader.'
                    : 'You can download the file and view it using your device\'s PDF reader.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.55),
              ),
              const SizedBox(height: 32),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _fetchAndRender,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('Retry',
                        style:
                            GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveToDocuments,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('Download',
                        style:
                            GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Downloading ───────────────────────────────────────────────────────────
  Widget _downloadingUI() {
    return Container(
      color: _dark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) =>
                    Transform.scale(scale: _pulseAnim.value, child: child),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.download_rounded,
                      size: 44, color: _primary),
                ),
              ),
              const SizedBox(height: 28),
              Text('Downloading',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55))),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: _primary,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Text('${(_downloadProgress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _primary)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Download done ─────────────────────────────────────────────────────────
  Widget _downloadDoneUI() {
    return Container(
      color: _dark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check_circle_rounded, size: 50, color: _primary),
              ),
              const SizedBox(height: 24),
              Text('Downloaded!',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text('File saved to Documents folder.',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveToDocuments,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text('Open Again',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fab() {
    return FloatingActionButton.extended(
      onPressed: _saveToDocuments,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.download_rounded, size: 20),
      label: Text('Download',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Download Complete!',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white)),
                Text('Saved to Documents folder',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
