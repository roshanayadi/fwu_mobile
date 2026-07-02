import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/auth_provider.dart';
import '../providers/form_provider.dart';
import '../models/form_model.dart';
import 'form_fill_screen.dart';

const _kPrimary = Color(0xFF0F6E56);
const _kBg = Color(0xFFF1F5F9);
const _kTextDark = Color(0xFF1E293B);
const _kTextMuted = Color(0xFF94A3B8);

class FormsScreen extends StatefulWidget {
  @override
  _FormsScreenState createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> {
  int _tabIndex = 0; // 0 = Open, 1 = Closed
  int? _downloadingId; // examScheduleId currently downloading

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchedules());
  }

  void _loadSchedules() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final formProv = Provider.of<FormProvider>(context, listen: false);
    formProv.fetchExamSchedules(auth.sessionCookie);
  }

  void _onFillForm(ExamSchedule schedule) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormFillScreen(
          schedule: schedule,
          sessionCookie: auth.sessionCookie!,
        ),
      ),
    ).then((_) {
      if (mounted) _loadSchedules();
    });
  }

  Future<void> _onDownloadAdmitCard(ExamSchedule schedule) async {
    setState(() => _downloadingId = schedule.examScheduleId);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final formProv = Provider.of<FormProvider>(context, listen: false);
    final filePath = await formProv.downloadAdmitCard(
      schedule.examScheduleId,
      auth.sessionCookie!,
    );

    setState(() => _downloadingId = null);

    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Admit card downloaded!'),
          backgroundColor: _kPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(filePath),
          ),
        ),
      );
      await OpenFilex.open(filePath);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formProv.error ?? 'Download failed'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  List<ExamSchedule> _getOpenSchedules(List<ExamSchedule> all) {
    return all.where((s) => s.isExamActive && !s.isExamRegistered).toList();
  }

  List<ExamSchedule> _getClosedSchedules(List<ExamSchedule> all) {
    return all.where((s) => !s.isExamActive || s.isExamRegistered).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formProv = Provider.of<FormProvider>(context);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ─────────────────────────────────────────
            Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 20, 0),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop()) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: _kTextDark),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ] else ...[
                      const SizedBox(width: 10),
                    ],
                    const Expanded(
                      child: Text(
                        'Exam Schedules',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _kTextDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    )
                ],
              ),
            ),

            // ─── TABS ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    _buildTab('Open', 0),
                    _buildTab('Closed', 1),
                  ],
                ),
              ),
            ),

            // ─── CONTENT ────────────────────────────────────────
            Expanded(
              child: formProv.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
                    )
                  : formProv.error != null
                      ? _buildErrorState(formProv.error!)
                      : _buildFilteredList(formProv.examSchedules),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: Colors.red.shade300, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _loadSchedules,
              child: const Text(
                'Try Again',
                style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _kTextMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredList(List<ExamSchedule> all) {
    final filtered = _tabIndex == 0 ? _getOpenSchedules(all) : _getClosedSchedules(all);
    if (filtered.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      onRefresh: () async {
        _loadSchedules();
        // Wait briefly for the loading state to take over or finish
        await Future.delayed(const Duration(milliseconds: 800));
      },
      color: _kPrimary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: filtered.length,
        itemBuilder: (_, i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildScheduleCard(filtered[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _tabIndex == 0 ? Icons.edit_note_rounded : Icons.history_rounded,
                color: _kPrimary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _tabIndex == 0 ? 'No Open Exams' : 'No Closed Exams',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kTextDark),
            ),
            const SizedBox(height: 8),
            Text(
              _tabIndex == 0
                  ? 'No exams are currently open\nfor form fill-up.'
                  : 'No closed or registered exams\nfound for your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadSchedules,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: _kPrimary,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(ExamSchedule schedule) {
    final statusColor = switch (schedule.status) {
      'Open' => const Color(0xFF856404),
      'Registered' => const Color(0xFF155724),
      'Verified' => _kPrimary,
      _ => Colors.grey,
    };
    final statusBg = switch (schedule.status) {
      'Open' => const Color(0xFFFFF3CD),
      'Registered' => const Color(0xFFD4EDDA),
      'Verified' => const Color(0xFFE1F5EE),
      _ => const Color(0xFFF1F5F9),
    };

    final bool isOpen = schedule.canFillForm;
    final bool isRegistered = schedule.isExamRegistered;
    final bool canDownloadAdmitCard = isRegistered && schedule.admitCardDownloadEnabled && schedule.examRegistrationId != null;
    final bool isDownloading = _downloadingId == schedule.examScheduleId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOpen ? _kPrimary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? _kPrimary : Colors.black).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? _kPrimary.withValues(alpha: 0.08)
                        : isRegistered
                            ? const Color(0xFFD4EDDA)
                            : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOpen
                        ? Icons.edit_document
                        : isRegistered
                            ? Icons.check_circle_outline
                            : Icons.calendar_today_outlined,
                    color: isOpen ? _kPrimary : isRegistered ? const Color(0xFF155724) : _kTextMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.examScheduleName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: (isOpen || isRegistered) ? _kTextDark : _kTextMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (schedule.programName != null)
                        Text(
                          schedule.programName!,
                          style: const TextStyle(fontSize: 11, color: _kTextMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12)), child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    schedule.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (schedule.year != null || schedule.part != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${schedule.year ?? ''}/${schedule.part ?? ''}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kTextMuted),
                    ),
                  ),
                const Spacer(),
                if (schedule.amount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        schedule.isPaymentComplete ? 'PAID' : 'DUE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: schedule.isPaymentComplete ? _kPrimary : Colors.red.shade600,
                        ),
                      ),
                      Text(
                        'Rs ${schedule.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: schedule.isPaymentComplete ? _kPrimary : _kTextDark,
                        ),
                      ),
                    ],
                  )
              ],
            )),
            if (schedule.examRollNo != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.pin_outlined, size: 14, color: _kTextMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Roll Number: ${schedule.examRollNo}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextDark),
                  ),
                ],
              ),
            ],

            // ─── ACTION BUTTONS ────────────────────────────────
            if (isOpen)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _onFillForm(schedule),
                    icon: Icon(schedule.isPaymentComplete ? Icons.send_rounded : Icons.edit_document, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    label: Text(
                      schedule.isPaymentComplete ? 'Submit Form' : 'Fill Application Form', 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ),
            if (canDownloadAdmitCard)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isDownloading ? null : () => _onDownloadAdmitCard(schedule),
                    icon: isDownloading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      isDownloading ? 'Downloading...' : 'Download Admit Card',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
