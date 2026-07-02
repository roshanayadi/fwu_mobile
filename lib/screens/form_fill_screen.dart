import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/form_provider.dart';
import '../models/form_model.dart';
import 'payment_screen.dart';

const _kPrimary = Color(0xFF0F6E56);
const _kBg = Color(0xFFF1F5F9);
const _kTextDark = Color(0xFF1E293B);
const _kTextMuted = Color(0xFF94A3B8);

class FormFillScreen extends StatefulWidget {
  final ExamSchedule schedule;
  final String sessionCookie;
  const FormFillScreen({required this.schedule, required this.sessionCookie});

  @override
  _FormFillScreenState createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<FormFillScreen> {
  ExamFormData? _formData;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForm();
    });
  }

  Future<void> _loadForm() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final formProv = Provider.of<FormProvider>(context, listen: false);
    final result = await formProv.fetchExamForm(
      widget.schedule.studentAdmissionId,
      widget.schedule.examScheduleId,
      widget.sessionCookie,
    );

    setState(() {
      _formData = result;
      _loading = false;
      if (result == null) {
        _error = formProv.error ?? 'Failed to load form.';
      } else if (result.pageType == 'expired') {
        _error = result.message ?? 'Form fill date has expired.';
      } else if (result.pageType == 'payment') {
        // Navigate to payment screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                formData: result,
                schedule: widget.schedule,
                sessionCookie: widget.sessionCookie,
              ),
            ),
          );
          return;
        }
      } else if (result.pageType != 'examForm') {
        _error = result.message ?? 'Unexpected page type.';
      }
    });
  }

  int get _selectedCount {
    if (_formData == null) return 0;
    int count = 0;
    for (final g in _formData!.subjectGroups) {
      for (final t in g.subjectTypes) {
        for (final s in t.subjects) {
          if (s.isTheorySelected || s.isPracticalSelected) count++;
        }
      }
    }
    return count;
  }

  int get _totalSubjects {
    if (_formData == null) return 0;
    int count = 0;
    for (final g in _formData!.subjectGroups) {
      for (final t in g.subjectTypes) {
        count += t.subjects.length;
      }
    }
    return count;
  }

  bool get _isViewOnly => widget.schedule.isExamRegistered && !widget.schedule.canFillForm;

  Future<void> _submit() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select at least one subject'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Submission',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'You are about to submit $_selectedCount subject(s) for:\n\n${widget.schedule.examScheduleName}\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 14, height: 1.5, color: _kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);

    final formProv = Provider.of<FormProvider>(context, listen: false);
    final success = await formProv.submitExamForm(widget.sessionCookie);

    setState(() => _submitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formProv.submitMessage ?? 'Form submitted successfully!'),
          backgroundColor: _kPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(formProv.error ?? 'Submission failed'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── HEADER ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: _kTextDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _isViewOnly ? 'View Registration' : 'Exam Form Fill',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── FORM INFO ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kPrimary.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.schedule.examScheduleName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                    ),
                    if (_formData != null) ...[
                      const SizedBox(height: 8),
                      if (_formData!.studentName != null)
                        _buildInfoRow(Icons.person_outlined, _formData!.studentName!),
                      if (_formData!.programName != null)
                        _buildInfoRow(Icons.school_outlined, _formData!.programName!),
                      _buildInfoRow(
                        Icons.category_outlined,
                        _formData!.isRegular ? 'Regular' : 'Supplementary / Back',
                      ),
                    ] else if (widget.schedule.programName != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.school_outlined, widget.schedule.programName!),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── SUBJECT LIST ───────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
                    )
                  : _error != null
                      ? _buildErrorState()
                      : _formData != null && _formData!.subjectGroups.isNotEmpty
                              ? _buildSubjectList()
                              : _buildEmptyState(),
            ),

            // ─── BOTTOM BAR ─────────────────────────────────────
            if (!_loading && _formData != null && _formData!.pageType == 'examForm' && !_isViewOnly)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_selectedCount of $_totalSubjects selected',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kTextMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitting || _selectedCount == 0 ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _kPrimary.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'SUBMIT FORM',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    fontSize: 13,
                                  ),
                                ),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _kTextMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: _kTextMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _loadForm,
              child: const Text('Retry', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No subjects found for this exam.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTextMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _formData!.subjectGroups.length,
      itemBuilder: (context, gi) {
        final group = _formData!.subjectGroups[gi];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            if (group.subjectGroupName != null && group.subjectGroupName!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8, top: gi > 0 ? 16 : 0),
                child: Text(
                  group.subjectGroupName!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kTextMuted,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            // Subject types
            ...group.subjectTypes.map((type) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (type.subjectTypeName != null &&
                      type.subjectTypeName!.isNotEmpty &&
                      group.subjectTypes.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, top: 4),
                      child: Text(
                        type.subjectTypeName!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                  ...type.subjects.map((sub) => _buildSubjectTile(sub)),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildSubjectTile(FormSubject subject) {
    final bool anySelected = subject.isTheorySelected || subject.isPracticalSelected;
    final bool disabled = _isViewOnly;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: anySelected
              ? _kPrimary.withValues(alpha: 0.2)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject.subjectName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: anySelected ? _kTextDark : _kTextMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (subject.hasTheory)
                  _buildCheckOption(
                    label: 'Theory',
                    selected: subject.isTheorySelected,
                    disabled: disabled,
                    onTap: () {
                      setState(() {
                        subject.isTheorySelected = !subject.isTheorySelected;
                      });
                    },
                  ),
                if (subject.hasTheory && subject.hasPractical)
                  const SizedBox(width: 16),
                if (subject.hasPractical)
                  _buildCheckOption(
                    label: 'Practical',
                    selected: subject.isPracticalSelected,
                    disabled: disabled,
                    onTap: () {
                      setState(() {
                        subject.isPracticalSelected = !subject.isPracticalSelected;
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckOption({
    required String label,
    required bool selected,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: selected ? _kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: selected ? _kPrimary : const Color(0xFFCBD5E1),
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? _kTextDark : _kTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
