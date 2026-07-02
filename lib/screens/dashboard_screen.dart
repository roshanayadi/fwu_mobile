import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../widgets/latest_update_card.dart';
import '../widgets/rate_us_card.dart';
import '../widgets/app_guide_section.dart';
import 'notifications_screen.dart';
import 'result_screen.dart';
import 'forms_screen.dart';
import 'quick_actions/quick_website.dart';
import 'quick_actions/quick_support.dart';
import 'quick_actions/digital_id_screen.dart';
import 'syllabus_screen.dart';
import 'quick_actions/all_services_screen.dart';
import 'quick_actions/academic_calendar_screen.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF0F6E56);
const _kGold = Color(0xFFEF9F27);
const _kCardBg = Colors.white;
const _kText1 = Color(0xFF0D1B2A);
const _kText2 = Color(0xFF6B7280);
const _kDivider = Color(0xFFF1F3F5);

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const DashboardScreen({super.key, this.onProfileTap});
  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

// ignore: library_private_types_in_public_api
class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  final GlobalKey<LatestUpdateCardState> _noticesKey = GlobalKey();
  bool _isCompact = false;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final c = _scrollController.offset > 20;
      if (c != _isCompact) setState(() => _isCompact = c);
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final newNow = DateTime.now();
        if (_now.minute != newNow.minute) {
          setState(() => _now = newNow);
        }
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Nepali date ──────────────────────────────────────────────────────────────
  static const _bsMonths = [
    'बैशाख',
    'जेठ',
    'असार',
    'साउन',
    'भदौ',
    'असोज',
    'कार्तिक',
    'मंसिर',
    'पुष',
    'माघ',
    'फागुन',
    'चैत',
  ];

  static const Map<int, List<int>> _bsDays = {
    2082: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2083: [31, 31, 32, 31, 31, 30, 30, 30, 29, 30, 30, 30],
  };
  static final _refAD = DateTime(2025, 4, 14);

  Map<String, int> _adToBS(DateTime ad) {
    int diff = ad.difference(_refAD).inDays;
    int y = 2082, m = 0, d = 1;
    while (diff > 0) {
      final months = _bsDays[y] ?? _bsDays[2082]!;
      final rem = months[m] - d + 1;
      if (diff < rem) {
        d += diff;
        diff = 0;
      } else {
        diff -= rem;
        d = 1;
        m++;
        if (m == 12) {
          m = 0;
          y++;
        }
      }
    }
    return {'year': y, 'month': m + 1, 'day': d};
  }

  // ── Auth helpers ─────────────────────────────────────────────────────────────
  String? _lastPhotoString;
  ImageProvider? _cachedUserPhoto;

  ImageProvider? _getUserPhoto(dynamic user) {
    if (user == null) return null;
    final photo = user.photo as String?;
    if (photo == null || photo.isEmpty) return null;

    if (photo == _lastPhotoString && _cachedUserPhoto != null) {
      return _cachedUserPhoto;
    }

    _lastPhotoString = photo;
    if (photo.startsWith('data:image')) {
      try {
        _cachedUserPhoto = MemoryImage(base64Decode(photo.split(',').last));
      } catch (_) {
        _cachedUserPhoto = null;
      }
    } else if (photo.startsWith('http')) {
      _cachedUserPhoto = NetworkImage(photo);
    } else {
      _cachedUserPhoto = null;
    }
    return _cachedUserPhoto;
  }

  Future<void> _handleRefresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await Future.wait([
      auth.fetchProfile(),
      _noticesKey.currentState?.fetchNotices() ?? Future.value(),
    ]);
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.studentInfo;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Layer 1 — gradient base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB8EFD8),
                  Color(0xFFD4E8FF),
                  Color(0xFFEDE8FF),
                  Color(0xFFFFF3D4),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
          // Layer 1b — soft colour blobs
          Positioned(
            top: -80,
            left: -60,
            child: _blob(220, const Color(0xFF0F6E56), 0.18),
          ),
          Positioned(
            top: 100,
            right: -70,
            child: _blob(180, const Color(0xFF6366F1), 0.15),
          ),
          Positioned(
            top: 380,
            left: -40,
            child: _blob(150, const Color(0xFF0EA5E9), 0.12),
          ),
          Positioned(
            top: 600,
            right: -30,
            child: _blob(160, const Color(0xFFEF9F27), 0.13),
          ),
          Positioned(
            bottom: 150,
            left: 30,
            child: _blob(120, const Color(0xFF14B8A6), 0.14),
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: _blob(100, const Color(0xFF8B5CF6), 0.12),
          ),
          // Layer 2 — full-screen frosted glass
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.white.withValues(alpha: 0.55)),
            ),
          ),
          // Layer 3 — actual content
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: _kGreen,
              backgroundColor: _kCardBg,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 110),
                children: [
                  _buildHeader(user),
                  _buildHero(),

                        _buildDateTimeStrip(),
                        const SizedBox(height: 12),
                        _buildServicesSection(),
                        const SizedBox(height: 8),
                        LatestUpdateCard(key: _noticesKey),
                        const SizedBox(height: 20),
                        _buildPromoBanner(),
                        const SizedBox(height: 16),
                        Container(height: 1, color: _kDivider),
                        const SizedBox(height: 8),
                        AppGuideSection(primaryGreen: _kGreen),
                        const SizedBox(height: 12),
                        const RateUsCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Blob helper ──────────────────────────────────────────────────────────────
  Widget _blob(double size, Color color, double opacity) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(dynamic user) {
    final userImg = _getUserPhoto(user);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.fromLTRB(
        16,
        _isCompact ? 10 : 16,
        16,
        _isCompact ? 10 : 16,
      ),
      color: Colors.transparent,
      child: Row(
        children: [
          Container(
            width: _isCompact ? 44 : 52,
            height: _isCompact ? 44 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: _kGreen.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kGreen.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              'assets/images/fwu_logo.png',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Far Western',
                  style: TextStyle(
                    fontSize: _isCompact ? 17 : 20,
                    fontWeight: FontWeight.w700,
                    color: _kGreen,
                    fontFamily: 'serif',
                    height: 1,
                  ),
                ),
                const Text(
                  'UNIVERSITY',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 9,
                      color: _kGreen.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Mahendranagar, Kanchanpur',
                      style: TextStyle(
                        fontSize: 9,
                        color: _kGreen.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildHeaderIcon(Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => widget.onProfileTap?.call(),
            child: Container(
              width: _isCompact ? 36 : 42,
              height: _isCompact ? 36 : 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
                image: userImg != null
                    ? DecorationImage(image: userImg, fit: BoxFit.cover)
                    : null,
              ),
              child: userImg == null
                  ? Icon(
                      Icons.person_rounded,
                      color: Colors.grey.shade500,
                      size: _isCompact ? 18 : 22,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        ),
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kText2, size: 18),
        ),
      ),
    );
  }

  // ─── HERO BANNER ─────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/banner.jpg', fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: [0.0, 0.4, 0.75, 1.0],
                colors: [
                  Color(0x00000000),
                  Color(0x30000000),
                  Color(0x990A4D3C),
                  Color(0xE00A4D3C),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Far Western University',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _kGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'EXCELLENCE IN EDUCATION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DATE-TIME STRIP ─────────────────────────────────────────────────────────
  Widget _buildDateTimeStrip() {
    final bs = _adToBS(_now);
    final monthName = _bsMonths[bs['month']! - 1];
    final isPM = _now.hour >= 12;
    final h12 = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final hStr = h12.toString().padLeft(2, '0');
    final mStr = _now.minute.toString().padLeft(2, '0');
    final ampm = isPM ? 'PM' : 'AM';
    const _kRed = Color(0xFFC62828); // Deeper, bolder red

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          // Nepali date
          const Icon(Icons.calendar_today_rounded, size: 14, color: _kRed),
          const SizedBox(width: 6),
          Text(
            '${bs['day']} $monthName ${bs['year']} BS',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kRed,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          // Live clock
          Text(
            '$hStr:$mStr',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _kRed,
              letterSpacing: 2.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            ampm,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _kRed,
            ),
          ),
        ],
      ),
    );
  }


  // ─── SERVICES ────────────────────────────────────────────────────────────────
  static const _services = [
    _Svc(Icons.badge_rounded, 'ID Card', Color(0xFF6366F1)),
    _Svc(Icons.emoji_events_rounded, 'Result', Color(0xFFEF9F27)),
    _Svc(Icons.description_rounded, 'Forms', Color(0xFF0EA5E9)),
    _Svc(Icons.language_rounded, 'Website', Color(0xFF0F6E56)),
    _Svc(Icons.campaign_rounded, 'Notices', Color(0xFFE53935)),
    _Svc(Icons.event_rounded, 'Events', Color(0xFF8B5CF6)),
    _Svc(Icons.newspaper_rounded, 'News', Color(0xFF14B8A6)),
    _Svc(Icons.menu_book_rounded, 'Syllabus', Color(0xFFF59E0B)),
    _Svc(Icons.thumb_up_alt_rounded, 'Follow', Color(0xFFEC4899)),
    _Svc(Icons.calendar_month_rounded, 'Calendar', Color(0xFF3B82F6)),
  ];

  Widget _buildServicesSection() {
    // ── Outer: full-screen-width background band ─────────────────────────────
    return Container(
      width: double.infinity,
      color: const Color(0xFFDDF0EA), // soft mint-green tint
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Inner: previous-style rounded white card ────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
                  child: Row(
                    children: [
                      const Text(
                        'Quick Services',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kText1,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllServicesScreen(),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'See All',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kGreen,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: _kGreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _services.length,
                    itemBuilder: (context, i) {
                      final svc = _services[i];
                      return _ServiceChip(
                        svc: svc,
                        onTap: () => _go(svc.label),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROMO BANNER ────────────────────────────────────────────────────────────
  Widget _buildPromoBanner() {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Image.asset(
        'assets/images/bnr.jpeg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F6E56), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: Colors.white54, size: 36),
                SizedBox(height: 8),
                Text('Add bnr.jpeg to assets/images/', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }




  // ─── NAVIGATION ──────────────────────────────────────────────────────────────
  void _go(String label) {
    Widget? dest;
    switch (label) {
      case 'ID Card':
        dest = const DigitalIdScreen();
        break;
      case 'Result':
        dest = ResultScreen();
        break;
      case 'Forms':
        dest = FormsScreen();
        break;
      case 'Website':
        dest = const QuickWebsiteScreen(
          url: 'https://www.fwu.edu.np',
          title: 'FWU Website',
        );
        break;
      case 'Notices':
        dest = const QuickWebsiteScreen(
          url: 'https://www.fwu.edu.np/notice.html',
          title: 'Notices',
        );
        break;
      case 'Events':
        dest = const QuickWebsiteScreen(
          url: 'https://www.fwu.edu.np/events.html',
          title: 'Events',
        );
        break;
      case 'News':
        dest = const QuickWebsiteScreen(
          url: 'https://www.fwu.edu.np/news.html',
          title: 'News',
        );
        break;
      case 'Support':
        dest = const QuickSupportScreen();
        break;
      case 'Syllabus':
        dest = const SyllabusScreen();
        break;
      case 'Calendar':
        dest = const AcademicCalendarScreen();
        break;
      case 'Follow':
        _showFollowSheet();
        return;
    }
    if (dest != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => dest!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label — Coming Soon!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFollowSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connect With Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _kText1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Stay updated with the latest university news',
              style: TextStyle(
                color: _kText2,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _socialBtn(
                  'Facebook',
                  Icons.facebook_rounded,
                  const Color(0xFF1877F2),
                  'https://www.facebook.com/fwu.edu.np',
                ),
                _socialBtn(
                  'YouTube',
                  Icons.play_circle_fill_rounded,
                  const Color(0xFFFF0000),
                  'https://www.youtube.com/@FarWesternUniversity',
                ),
                _socialBtn(
                  'Website',
                  Icons.public_rounded,
                  _kGreen,
                  'https://fwu.edu.np',
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _socialBtn(String label, IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri))
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kText1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Service data ─────────────────────────────────────────────────────────────
class _Svc {
  final IconData icon;
  final String label;
  final Color color;
  const _Svc(this.icon, this.label, this.color);
}

// ─── Service chip ─────────────────────────────────────────────────────────────
class _ServiceChip extends StatefulWidget {
  final _Svc svc;
  final VoidCallback onTap;
  const _ServiceChip({required this.svc, required this.onTap});
  @override
  State<_ServiceChip> createState() => _ServiceChipState();
}

class _ServiceChipState extends State<_ServiceChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.0,
    upperBound: 1.0,
  );
  late final Animation<double> _scaleAnim = Tween(
    begin: 1.0,
    end: 0.91,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.svc.icon, size: 34, color: const Color(0xFF2D3142)),
              const SizedBox(height: 8),
              Text(
                widget.svc.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A4A4A),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
