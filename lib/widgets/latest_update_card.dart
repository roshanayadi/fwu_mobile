import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kGreen   = Color(0xFF0F6E56);
const _kText1   = Color(0xFF0D1B2A);
const _kText2   = Color(0xFF6B7280);
const _kDivider = Color(0xFFF1F3F5);

class Notice {
  final String title;
  final String date;
  final String link;
  Notice({required this.title, required this.date, required this.link});

  Map<String, dynamic> toJson() => {'title': title, 'date': date, 'link': link};
  factory Notice.fromJson(Map<String, dynamic> j) =>
      Notice(title: j['title'] ?? '', date: j['date'] ?? '', link: j['link'] ?? '');
}

class LatestUpdateCard extends StatefulWidget {
  const LatestUpdateCard({super.key});
  @override
  State<LatestUpdateCard> createState() => LatestUpdateCardState();
}

class LatestUpdateCardState extends State<LatestUpdateCard>
    with SingleTickerProviderStateMixin {
  List<Notice> notices = [];
  bool loading = true;
  bool showAll = false;
  late final AnimationController _shimmerCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _loadCache();
    fetchNotices();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_notices');
      if (cached != null && mounted) {
        final decoded = jsonDecode(cached) as List<dynamic>;
        setState(() {
          notices = decoded.map((e) => Notice.fromJson(e as Map<String, dynamic>)).toList();
          loading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> fetchNotices() async {
    if (notices.isEmpty && mounted) setState(() => loading = true);
    try {
      final client = http.Client();
      final res = await client
          .get(Uri.parse('https://fwuexam.edu.np/notice.html'))
          .timeout(const Duration(seconds: 10));
      final body = res.body;
      final doc = parse(body);
      final modals = doc.querySelectorAll('.modal-body');

      List<Notice> fetched = [];
      for (final modal in modals) {
        final a = modal.querySelector('a');
        if (a == null || a.attributes['href'] == null) continue;
        final titleEl = modal.querySelector('.notice-card-title');
        final dateEl = modal.querySelector('p.fw-medium');
        if (titleEl == null) continue;
        String link = a.attributes['href']!;
        if (!link.startsWith('http')) {
          link = 'https://fwuexam.edu.np/${link.replaceFirst(RegExp(r'^/+'), '')}';
        }
        final title = titleEl.text.trim();
        if (title.length > 5) {
          fetched.add(Notice(title: title, date: dateEl?.text.trim() ?? '', link: link));
        }
      }

      if (fetched.isEmpty) {
        for (final a in doc.querySelectorAll('a')) {
          final text = a.text.trim();
          if (text.length > 15 && text.split(' ').length > 3) {
            fetched.add(Notice(title: text, date: '', link: a.attributes['href'] ?? ''));
          }
        }
      }

      if (mounted) {
        setState(() { notices = fetched; loading = false; });
        try {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('cached_notices', jsonEncode(fetched.map((n) => n.toJson()).toList()));
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  // Rotating accent colors for notice rows
  static const _accentColors = [
    Color(0xFF0F6E56), // green
    Color(0xFF6366F1), // indigo
    Color(0xFF0EA5E9), // sky
    Color(0xFFEF9F27), // gold
    Color(0xFF14B8A6), // teal
  ];

  @override
  Widget build(BuildContext context) {
    final count = showAll ? notices.length : notices.length.clamp(0, 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header — no icon, plain text ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              const Text('Latest Notices', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kText1)),
              if (!loading && notices.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('(${notices.length})', style: const TextStyle(fontSize: 12, color: _kText2, fontWeight: FontWeight.w500)),
              ],
              const Spacer(),
              if (!loading && notices.length > 2)
                GestureDetector(
                  onTap: () => setState(() => showAll = !showAll),
                  child: Row(
                    children: [
                      Text(showAll ? 'See Less' : 'See All', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
                      Icon(showAll ? Icons.keyboard_arrow_up_rounded : Icons.chevron_right_rounded, size: 16, color: _kGreen),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        Container(height: 1, color: _kDivider),


        // ── Body ─────────────────────────────────────────────────────────────
        if (loading)
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: List.generate(3, (i) => _shimmerRow(_shimmerCtrl.value, i)),
              ),
            ),
          )
        else if (notices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                    child: const Icon(Icons.inbox_rounded, color: Color(0xFFCBD5E1), size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text('No notices available', style: TextStyle(color: _kText2, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          )
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: count,
              separatorBuilder: (_, __) => Container(height: 1, color: _kDivider),
              itemBuilder: (context, i) => _NoticeRow(
                notice: notices[i],
                index: i,
                accent: _accentColors[i % _accentColors.length],
              ),
            ),
          ),
      ],
    );
  }


  Widget _shimmerRow(double progress, int index) {
    final shimmerColor = ColorTween(
      begin: const Color(0xFFE2E8F0),
      end: const Color(0xFFF8FAFC),
    ).lerp((progress + index * 0.2) % 1.0)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(width: 3, height: 40, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 7),
                Container(height: 10, width: 120, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 52, height: 30, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(10))),
        ],
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  final Notice notice;
  final int index;
  final Color accent;
  const _NoticeRow({required this.notice, required this.index, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(notice.link);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left accent bar + number
              Column(
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(width: 2, height: 24, decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(1))),
                ],
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText1, height: 1.45),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notice.date.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 11, color: _kText2),
                          const SizedBox(width: 4),
                          Text(notice.date, style: const TextStyle(fontSize: 11, color: _kText2, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Premium view button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.12), accent.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 11, color: accent),
                    const SizedBox(width: 4),
                    Text('View', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
