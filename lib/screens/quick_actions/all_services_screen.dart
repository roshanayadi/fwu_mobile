import 'package:flutter/material.dart';
import '../result_screen.dart';
import '../forms_screen.dart';
import '../syllabus_screen.dart';
import '../notifications_screen.dart';
import 'quick_website.dart';
import 'quick_support.dart';
import 'digital_id_screen.dart';
import 'academic_calendar_screen.dart';

class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final Color primaryGreen = const Color(0xFF0F6E56);
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<_ServiceItem> _allServices = [
    _ServiceItem(Icons.calendar_month_rounded,'Calendar', 'Nepali BS academic calendar',     const Color(0xFF0F6E56), const Color(0xFFE6F6EF)),
    _ServiceItem(Icons.badge_rounded,       'ID Card',     'Access your digital student ID card', const Color(0xFF14B8A6), const Color(0xFFF0FDFA)),
    _ServiceItem(Icons.emoji_events_rounded,'Result',      'Check your semester exam results',     const Color(0xFF1D4ED8), const Color(0xFFEFF6FF)),
    _ServiceItem(Icons.description_rounded, 'Forms',       'Download and fill university forms',   const Color(0xFFC2410C), const Color(0xFFFFF7ED)),
    _ServiceItem(Icons.language_rounded,    'Website',     'Visit the official FWU website',       const Color(0xFF0F6E56), const Color(0xFFE6F6EF)),
    _ServiceItem(Icons.campaign_rounded,    'Notices',     'Read latest university notices',       const Color(0xFF7C3AED), const Color(0xFFFAF5FF)),
    _ServiceItem(Icons.event_rounded,       'Events',      'Upcoming university events',           const Color(0xFFDB2777), const Color(0xFFFDF2F8)),
    _ServiceItem(Icons.newspaper_rounded,   'News',        'Latest news from FWU',                 const Color(0xFF0891B2), const Color(0xFFECFEFF)),
    _ServiceItem(Icons.menu_book_rounded,   'Syllabus',    'Browse course syllabus',               const Color(0xFFD97706), const Color(0xFFFFFBEB)),
    _ServiceItem(Icons.support_agent_rounded,'Support',   'Get help and support',                 const Color(0xFF059669), const Color(0xFFECFDF5)),
    _ServiceItem(Icons.notifications_rounded,'Notifications','View all notifications',             const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
    _ServiceItem(Icons.thumb_up_alt_rounded,'Follow',      'Follow FWU on social media',           const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
    _ServiceItem(Icons.payment_rounded,     'Payment',     'Fee payment and transactions',         const Color(0xFF0891B2), const Color(0xFFECFEFF)),
  ];

  List<_ServiceItem> get _filtered {
    if (_query.isEmpty) return _allServices;
    return _allServices.where((s) =>
      s.label.toLowerCase().contains(_query.toLowerCase()) ||
      s.subtitle.toLowerCase().contains(_query.toLowerCase())
    ).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleTap(_ServiceItem item) {
    switch (item.label) {
      case 'Calendar':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicCalendarScreen()));
        break;
      case 'ID Card':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalIdScreen()));
        break;
      case 'Result':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen()));
        break;
      case 'Forms':
        Navigator.push(context, MaterialPageRoute(builder: (_) => FormsScreen()));
        break;
      case 'Website':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickWebsiteScreen(url: 'https://www.fwu.edu.np', title: 'FWU Website')));
        break;
      case 'Notices':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickWebsiteScreen(url: 'https://www.fwu.edu.np/notice.html', title: 'Notices')));
        break;
      case 'Events':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickWebsiteScreen(url: 'https://www.fwu.edu.np/events.html', title: 'Events')));
        break;
      case 'News':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickWebsiteScreen(url: 'https://www.fwu.edu.np/news.html', title: 'News')));
        break;
      case 'Syllabus':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SyllabusScreen()));
        break;
      case 'Support':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickSupportScreen()));
        break;
      case 'Notifications':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.label} — Coming Soon!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'All Services',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Search bar ──────────────────────────────
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'Search services...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: primaryGreen, size: 22),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Results count ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                _query.isEmpty
                    ? '${filtered.length} services available'
                    : '${filtered.length} result${filtered.length == 1 ? '' : 's'} for "$_query"',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ),

            // ── Grid ─────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No services found',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            splashColor: item.color.withValues(alpha: 0.08),
                            onTap: () => _handleTap(item),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: item.bgColor,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(item.icon, color: item.color, size: 26),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.subtitle,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: Colors.grey.shade400,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  const _ServiceItem(this.icon, this.label, this.subtitle, this.color, this.bgColor);
}
