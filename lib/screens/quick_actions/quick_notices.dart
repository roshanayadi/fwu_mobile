import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'quick_website.dart';
import 'quick_support.dart';


/// HTTP client that bypasses SSL certificate errors for fwu.edu.np
http.Client _createFwuClient() {
  final ioClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true; // bypass SSL for notices
  return IOClient(ioClient);
}


class FwuNotice {
  final String title;
  final String date;
  final String url;

  FwuNotice({required this.title, required this.date, required this.url});
}

class QuickNoticesScreen extends StatefulWidget {
  const QuickNoticesScreen({super.key});

  @override
  State<QuickNoticesScreen> createState() => _QuickNoticesScreenState();
}

class _QuickNoticesScreenState extends State<QuickNoticesScreen> {
  List<FwuNotice> _notices = [];
  bool _loading = true;
  String? _error;

  static const _primary = Color(0xFF7C3AED);
  static const _noticeUrl = 'https://www.fwu.edu.np/notice.html';

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = _createFwuClient();
      final response = await client
          .get(Uri.parse(_noticeUrl), headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,*/*',
          })
          .timeout(const Duration(seconds: 15));
      client.close();

      if (response.statusCode != 200) {
        setState(() {
          _error = 'Failed to load notices (HTTP ${response.statusCode})';
          _loading = false;
        });
        return;
      }

      // Try decoding as UTF-8 (modern standard), fallback to Latin1 if it fails
      String html;
      try {
        html = utf8.decode(response.bodyBytes);
      } catch (_) {
        html = latin1.decode(response.bodyBytes, allowInvalid: true);
      }
      
      final notices = _parseNotices(html);


      setState(() {
        _notices = notices.take(4).toList(); // Top 4 only
        _loading = false;
      });
    } on TimeoutException {
      setState(() {
        _error = 'Request timed out. FWU website is slow or unreachable.';
        _loading = false;
      });
    } on SocketException catch (e) {
      setState(() {
        _error = 'Network error: ${e.message}';
        _loading = false;
      });
    } on HandshakeException catch (e) {
      setState(() {
        _error = 'SSL error: ${e.message}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.runtimeType} — $e';
        _loading = false;
      });
    }
  }

  /// Parse notice items from FWU notice page HTML.
  /// Each notice block looks like:
  ///   <h2><a href="/notice-detail/XXXX.html">Title</a></h2>
  ///   ...date text...
  List<FwuNotice> _parseNotices(String html) {
    final notices = <FwuNotice>[];

    // Broaden regex to find any anchor tag with a notice-detail link
    // This is more resilient if the H2 class or structure changes
    final noticeRegex = RegExp(
      r'<a[^>]+href="([^"]*notice-detail\/[^"]+)"[^>]*>([\s\S]*?)<\/a>',
      caseSensitive: false,
    );

    // Match date pattern like: Oct 15, 2025
    final dateRegex = RegExp(
      r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},\s+\d{4}',
    );

    final allMatches = noticeRegex.allMatches(html).toList();
    final uniqueLinks = <String>{};

    for (var match in allMatches) {
      final href = match.group(1) ?? '';
      var rawTitle = match.group(2) ?? '';

      // Clean HTML tags from title
      String title = rawTitle
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Skip "Read More" links or empty titles to avoid duplicates
      if (title.isEmpty || 
          title.toLowerCase() == 'read more' || 
          title.toLowerCase().contains('readmore')) continue;
      
      // Ensure we don't add the same notice twice (h2 link + read more button)
      if (uniqueLinks.contains(href)) continue;
      uniqueLinks.add(href);

      if (title.isEmpty) continue;

      // Handle both absolute and relative URLs (with or without leading slash)
      String fullUrl = href;
      if (!href.startsWith('http')) {
        fullUrl = href.startsWith('/') ? 'https://www.fwu.edu.np$href' : 'https://www.fwu.edu.np/$href';
      }

      // Find date in the surrounding HTML snippet
      final snippetStart = match.end;
      final snippetEnd = (snippetStart + 500).clamp(0, html.length);
      final snippet = html.substring(snippetStart, snippetEnd);
      final dateMatch = dateRegex.firstMatch(snippet);
      final date = dateMatch?.group(0) ?? '';

      notices.add(FwuNotice(title: title, date: date, url: fullUrl));
      
      // Stop after 20 notices to keep it fast
      if (notices.length >= 20) break;
    }

    return notices;
  }

  void _openNotice(FwuNotice notice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuickWebsiteScreen(
          url: notice.url,
          title: 'Notice',
        ),
      ),
    );
  }

  Future<void> _summarizeNotice(FwuNotice notice) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: _primary)),
    );

    try {
      final client = _createFwuClient();
      final response = await client.get(Uri.parse(notice.url)).timeout(const Duration(seconds: 15));
      client.close();

      if (mounted) Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        String html;
        try {
          html = utf8.decode(response.bodyBytes);
        } catch (_) {
          html = latin1.decode(response.bodyBytes, allowInvalid: true);
        }
        // Truncate to a reasonable limit (Approx 3,500 characters) to avoid API errors
        String text = html
            .replaceAll(RegExp(r'<script[\s\S]*?<\/script>'), '')
            .replaceAll(RegExp(r'<style[\s\S]*?<\/style>'), '')
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        if (text.length > 3500) {
          text = '${text.substring(0, 3500)}... [TRUNCATED]';
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuickSupportScreen(
                initialMessage: "SUMMARIZE: ${notice.title}\n\nCONTENT: $text",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch notice content for summarization.')),
        );
      }
    }
  }

  void _openAllNotices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuickWebsiteScreen(
          url: _noticeUrl,
          title: 'All Notices',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Notices',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchNotices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
                  SizedBox(height: 16),
                  Text(
                    'Loading latest notices...',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 64, color: Colors.purple.shade200),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchNotices,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Header banner
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primary,
                            _primary.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.campaign_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latest Notices',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Far Western University',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Top ${_notices.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notice cards
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _notices.length,
                        itemBuilder: (context, index) {
                          final notice = _notices[index];
                          return _buildNoticeCard(notice, index);
                        },
                      ),
                    ),

                    // View All button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _openAllNotices,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text(
                            'View All Notices',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(color: _primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNoticeCard(FwuNotice notice, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openNotice(notice),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _primary.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Color(0xFF1E293B),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 12,
                                color: _primary.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              notice.date,
                              style: TextStyle(
                                fontSize: 11,
                                color: _primary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _summarizeNotice(notice),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, size: 12, color: _primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'AI Summary',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
