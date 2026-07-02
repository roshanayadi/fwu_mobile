import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/latest_update_card.dart' show Notice;

const _kPrimary = Color(0xFF0F6E56);
const _kPrimaryDark = Color(0xFF1a3a6b);
const _kBg = Color(0xFFF1F5F9);
const _kTextDark = Color(0xFF1E293B);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Notice> notices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedNotices();
    _fetchNotices();
  }

  Future<void> _loadCachedNotices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cached = prefs.getString('cached_notices_full');
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        if (mounted) {
          setState(() {
            notices = decoded.map((e) => Notice.fromJson(e as Map<String, dynamic>)).toList();
            loading = false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchNotices() async {
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse("https://fwuexam.edu.np/notice.html"),
      ).timeout(const Duration(seconds: 10));
      final body = response.body;

      var document = parse(body);
      var modals = document.querySelectorAll('.modal-body');
      List<Notice> fetchedNotices = [];

      for (var modal in modals) {
        var a = modal.querySelector('a');
        if (a != null && a.attributes['href'] != null) {
          var titleEl = modal.querySelector('.notice-card-title');
          var dateEl = modal.querySelector('p.fw-medium');

          if (titleEl != null) {
            String titleStr = titleEl.text.trim();
            String linkStr = a.attributes['href']!;
            String dateStr = dateEl != null ? dateEl.text.trim() : "";

            if (!linkStr.startsWith('http')) {
              linkStr = 'https://fwuexam.edu.np/' + linkStr.replaceFirst(RegExp(r'^/+'), '');
            }

            if (titleStr.length > 5) {
              fetchedNotices.add(Notice(title: titleStr, date: dateStr, link: linkStr));
            }
          }
        }
      }

      if (fetchedNotices.isEmpty) {
        var links = document.querySelectorAll("a");
        for (var a in links) {
          String text = a.text.trim();
          if (text.length > 15 && text.split(" ").length > 3) {
            fetchedNotices.add(Notice(title: text, date: "", link: a.attributes['href'] ?? ""));
          }
        }
      }

      if (mounted) {
        setState(() {
          notices = fetchedNotices;
          loading = false;
        });
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_notices_full', jsonEncode(fetchedNotices.map((n) => n.toJson()).toList()));
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open notice file')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Notifications & Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kTextDark),
      ),
      body: loading && notices.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _fetchNotices,
              color: _kPrimary,
              child: notices.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Center(child: Text("No updates found.", style: TextStyle(color: Colors.grey))),
                        )
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: notices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final n = notices[index];
                        // First 2 items are considered strictly "unread" for visual effect 
                        // unless you implement a real 'read status' local DB
                        final isNew = index < 2;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _launchUrl(n.link),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isNew ? _kPrimary.withOpacity(0.3) : const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isNew ? _kPrimary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.campaign_outlined,
                                      color: isNew ? _kPrimary : Colors.grey.shade600,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  height: 1.4,
                                                  fontWeight: isNew ? FontWeight.w800 : FontWeight.w600,
                                                  color: _kTextDark,
                                                ),
                                              ),
                                            ),
                                            if (isNew)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8, top: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'NEW',
                                                  style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(
                                                  n.date.isNotEmpty ? n.date : 'Recently',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.picture_as_pdf_rounded, size: 14, color: _kPrimaryDark.withOpacity(0.8)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'View PDF',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: _kPrimaryDark.withOpacity(0.8),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
