import 'package:flutter/material.dart';

// ─── Nepali Calendar Data ────────────────────────────────────────────────────

const _nepMonths = [
  'बैशाख', 'जेठ', 'असार', 'साउन',
  'भदौ', 'असोज', 'कार्तिक', 'मंसिर',
  'पुष', 'माघ', 'फागुन', 'चैत',
];

const _nepMonthsRoman = [
  'Baisakh', 'Jestha', 'Ashadh', 'Shrawan',
  'Bhadra', 'Ashwin', 'Kartik', 'Mangsir',
  'Poush', 'Magh', 'Falgun', 'Chaitra',
];

const _weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// Days in each month: year → list of 12 month-day-counts
const Map<int, List<int>> _daysInMonth = {
  2082: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
  2083: [31, 31, 32, 31, 31, 30, 30, 30, 29, 30, 30, 30],
};

// Reference: Baisakh 1, 2082 = Monday → weekday index 1 (Sun=0)
const int _refYear = 2082;
const int _refMonth = 0; // 0-indexed
const int _refStartWeekday = 1; // Monday

int _daysFromRef(int year, int month) {
  int days = 0;
  for (int y = _refYear; y < year; y++) {
    final m = _daysInMonth[y] ?? _daysInMonth[2082]!;
    days += m.reduce((a, b) => a + b);
  }
  final monthList = _daysInMonth[year] ?? _daysInMonth[2082]!;
  for (int m = _refMonth; m < month; m++) {
    days += monthList[m];
  }
  return days;
}

int _startWeekday(int year, int month) {
  final delta = _daysFromRef(year, month);
  return (_refStartWeekday + delta) % 7;
}

// ─── Academic Events ─────────────────────────────────────────────────────────

class _AcEvent {
  final int bsYear;
  final int bsMonth; // 1-indexed
  final int bsDay;
  final String title;
  final Color color;
  const _AcEvent(this.bsYear, this.bsMonth, this.bsDay, this.title, this.color);
}

final List<_AcEvent> _events = [
  // 2082
  _AcEvent(2082, 1, 1,  'Nepali New Year / Academic Year Start', const Color(0xFFDC2626)),
  _AcEvent(2082, 1, 5,  'Semester I Admission Deadline',         const Color(0xFF1D4ED8)),
  _AcEvent(2082, 1, 14, 'Orientation Program',                   const Color(0xFF059669)),
  _AcEvent(2082, 2, 1,  'Semester I Classes Begin',              const Color(0xFF059669)),
  _AcEvent(2082, 4, 15, 'Mid-Term Exam — Sem I',                 const Color(0xFFD97706)),
  _AcEvent(2082, 5, 30, 'Semester I Internal Exam',              const Color(0xFFD97706)),
  _AcEvent(2082, 6, 15, 'Semester I End / Vacation',             const Color(0xFF7C3AED)),
  _AcEvent(2082, 6, 20, 'Semester II Admission Open',            const Color(0xFF1D4ED8)),
  _AcEvent(2082, 7, 1,  'Semester II Classes Begin',             const Color(0xFF059669)),
  _AcEvent(2082, 8, 10, 'Mid-Term Exam — Sem II',                const Color(0xFFD97706)),
  _AcEvent(2082, 9, 5,  'Semester II Internal Exam',             const Color(0xFFD97706)),
  _AcEvent(2082, 10, 1, 'Semester II Final Exam',                const Color(0xFFDC2626)),
  _AcEvent(2082, 10, 20,'Winter Vacation Begins',                const Color(0xFF0891B2)),
  _AcEvent(2082, 11, 15,'Semester II Result Published',          const Color(0xFF059669)),
  _AcEvent(2082, 12, 1, 'Semester III Admission Open',           const Color(0xFF1D4ED8)),
  _AcEvent(2082, 12, 20,'Convocation Ceremony 2082',             const Color(0xFFDC2626)),

  // 2083
  _AcEvent(2083, 1, 1,  'Nepali New Year 2083',                  const Color(0xFFDC2626)),
  _AcEvent(2083, 1, 10, 'Semester III Classes Begin',            const Color(0xFF059669)),
  _AcEvent(2083, 3, 15, 'Mid-Term Exam — Sem III',               const Color(0xFFD97706)),
  _AcEvent(2083, 5, 20, 'Semester III Final Exam',               const Color(0xFFDC2626)),
];

List<_AcEvent> _eventsForMonth(int year, int month) =>
    _events.where((e) => e.bsYear == year && e.bsMonth == month).toList();

// ─── Screen ───────────────────────────────────────────────────────────────────

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});
  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  static const Color _green = Color(0xFF0F6E56);

  // Start on current approximate month: Chaitra 2082
  int _year = 2082;
  int _month = 12; // 1-indexed → Chaitra

  int? _selectedDay;

  void _prevMonth() {
    setState(() {
      _selectedDay = null;
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDay = null;
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthDays = (_daysInMonth[_year] ?? _daysInMonth[2082]!)[_month - 1];
    final startWd = _startWeekday(_year, _month - 1); // 0-indexed month
    final events = _eventsForMonth(_year, _month);

    // Map day → event for quick lookup
    final Map<int, _AcEvent> eventMap = {for (var e in events) e.bsDay: e};

    // Selected day events
    final selectedEvents = _selectedDay != null
        ? events.where((e) => e.bsDay == _selectedDay).toList()
        : <_AcEvent>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Back + title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Academic Calendar',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              'Far Western University',
                              style: TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'BS $_year',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Month navigator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _navBtn(Icons.chevron_left_rounded, _prevMonth),
                      Column(
                        children: [
                          Text(
                            _nepMonths[_month - 1],
                            style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: Colors.white, height: 1,
                            ),
                          ),
                          Text(
                            _nepMonthsRoman[_month - 1],
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      _navBtn(Icons.chevron_right_rounded, _nextMonth),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    // ── Calendar card ────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Weekday headers
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                            child: Row(
                              children: _weekDays.map((d) => Expanded(
                                child: Text(
                                  d,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: d == 'Sat'
                                        ? Colors.blue.shade400
                                        : d == 'Sun'
                                            ? Colors.red.shade400
                                            : const Color(0xFF64748B),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          // Day grid
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1,
                              ),
                              itemCount: startWd + monthDays,
                              itemBuilder: (context, index) {
                                if (index < startWd) return const SizedBox();
                                final day = index - startWd + 1;
                                final weekday = (startWd + day - 1) % 7;
                                final hasEvent = eventMap.containsKey(day);
                                final event = eventMap[day];
                                final isSelected = _selectedDay == day;
                                final isToday = _year == 2082 && _month == 12 && day == 29;

                                return GestureDetector(
                                  onTap: hasEvent
                                      ? () => setState(() => _selectedDay = isSelected ? null : day)
                                      : null,
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? event!.color
                                          : isToday
                                              ? _green.withValues(alpha: 0.12)
                                              : hasEvent
                                                  ? event!.color.withValues(alpha: 0.12)
                                                  : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: isToday && !isSelected
                                          ? Border.all(color: _green, width: 1.5)
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$day',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: hasEvent || isToday ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : weekday == 0
                                                    ? Colors.red.shade400
                                                    : weekday == 6
                                                        ? Colors.blue.shade400
                                                        : hasEvent
                                                            ? event!.color
                                                            : const Color(0xFF374151),
                                          ),
                                        ),
                                        if (hasEvent && !isSelected)
                                          Container(
                                            width: 4, height: 4,
                                            margin: const EdgeInsets.only(top: 1),
                                            decoration: BoxDecoration(
                                              color: event!.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Selected event detail ────────────────────
                    if (selectedEvents.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...selectedEvents.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: e.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: e.color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: e.color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.event_rounded, color: e.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: e.color),
                                  ),
                                  Text(
                                    '${_nepMonthsRoman[e.bsMonth - 1]} ${e.bsDay}, ${e.bsYear} BS',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],

                    // ── All events this month ────────────────────
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(width: 3, height: 16, decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        const Text('Events This Month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                        const Spacer(),
                        Text('${events.length} event${events.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (events.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available_rounded, color: Colors.grey.shade300, size: 28),
                            const SizedBox(width: 10),
                            Text('No academic events this month',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      ...events.map((e) => _EventTile(event: e)),

                    // ── Legend ────────────────────────────────────
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Legend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12, runSpacing: 8,
                            children: const [
                              _LegendItem(color: Color(0xFFDC2626), label: 'Holiday / Important'),
                              _LegendItem(color: Color(0xFF059669), label: 'Academic Start'),
                              _LegendItem(color: Color(0xFFD97706), label: 'Exam'),
                              _LegendItem(color: Color(0xFF1D4ED8), label: 'Admission'),
                              _LegendItem(color: Color(0xFF7C3AED), label: 'Semester End'),
                              _LegendItem(color: Color(0xFF0891B2), label: 'Vacation'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final _AcEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${event.bsDay}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: event.color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: event.color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
