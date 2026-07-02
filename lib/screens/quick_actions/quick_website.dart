import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class QuickWebsiteScreen extends StatefulWidget {
  final String url;
  final String title;

  const QuickWebsiteScreen({
    super.key,
    this.url = 'https://www.fwu.edu.np',
    this.title = 'FWU Website',
  });

  @override
  State<QuickWebsiteScreen> createState() => _QuickWebsiteScreenState();
}

class _QuickWebsiteScreenState extends State<QuickWebsiteScreen> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _loading = true;
  bool _canGoBack = false;

  static const _primary = Color(0xFF0F6E56);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              widget.url,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _webViewController?.reload(),
          ),
          // Open in browser (optional)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'home') {
                _webViewController?.loadUrl(
                  urlRequest: URLRequest(url: WebUri(widget.url)),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'home',
                child: Row(children: [
                  Icon(Icons.home_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Go to Homepage'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          if (_loading)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              minHeight: 3,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),

          // WebView
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useOnDownloadStart: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                supportMultipleWindows: false,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (_, url) {
                if (mounted) setState(() => _loading = true);
              },
              onLoadStop: (_, url) async {
                if (mounted) {
                  setState(() => _loading = false);
                  _canGoBack = await _webViewController?.canGoBack() ?? false;
                  setState(() {});
                }
              },
              onProgressChanged: (_, progress) {
                if (mounted) setState(() => _progress = progress / 100);
              },
              onReceivedError: (_, __, error) {
                if (mounted) setState(() => _loading = false);
              },
            ),
          ),

          // Bottom nav bar
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _navBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  enabled: _canGoBack,
                  onTap: () => _webViewController?.goBack(),
                ),
                _navBtn(
                  icon: Icons.arrow_forward_ios_rounded,
                  enabled: false,
                  onTap: () => _webViewController?.goForward(),
                ),
                const Spacer(),
                _navBtn(
                  icon: Icons.home_outlined,
                  enabled: true,
                  onTap: () => _webViewController?.loadUrl(
                    urlRequest: URLRequest(url: WebUri(widget.url)),
                  ),
                ),
                _navBtn(
                  icon: Icons.refresh_rounded,
                  enabled: true,
                  onTap: () => _webViewController?.reload(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(
        icon,
        size: 20,
        color: enabled ? const Color(0xFF374151) : Colors.grey.shade300,
      ),
    );
  }
}
