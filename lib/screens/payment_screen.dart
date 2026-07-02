import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/form_provider.dart';
import '../models/form_model.dart';
import 'payment_webview_screen.dart';
import 'form_fill_screen.dart';

const _kPrimary = Color(0xFF0F6E56);
const _kBg = Color(0xFFF7F8FA);
const _kTextDark = Color(0xFF1E293B);
const _kTextMuted = Color(0xFF94A3B8);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE8ECF0);

class _GatewayInfo {
  final String label;
  final String key;
  final Color color;
  final Color bgColor;
  final String logoUrl;
  const _GatewayInfo(this.label, this.key, this.color, this.bgColor, this.logoUrl);
}

const _gateways = [
  _GatewayInfo(
    'eSewa',
    'esewa',
    Color(0xFF60BB46),
    Color(0xFFEDF7EA),
    'https://www.collegenp.com/uploads/2020/01/eSewa.png',
  ),
  _GatewayInfo(
    'Khalti',
    'khalti',
    Color(0xFF5C2D91),
    Color(0xFFF3EDF9),
    'https://blog.khalti.com/wp-content/uploads/2021/02/Naya_Khalti_Logo_icon_2018.png',
  ),
  _GatewayInfo(
    'ConnectIPS',
    'connectips',
    Color(0xFF004B87),
    Color(0xFFE8F0F8),
    'https://play-lh.googleusercontent.com/l2NwpHebHN7ZwsyqxMhe3Ke75VC-vN8o5Xyz9cVkE3ES-o_lviOiFStNrCeo_BUtsLo_',
  ),
  _GatewayInfo(
    'HBL',
    'hbl',
    Color(0xFF00529B),
    Color(0xFFE6EFF8),
    'https://www.himalayanbank.com/uploads/fetured_images/hbl-logo.png',
  ),
];

class PaymentScreen extends StatefulWidget {
  final ExamFormData formData;
  final ExamSchedule schedule;
  final String sessionCookie;

  const PaymentScreen({super.key, 
    required this.formData,
    required this.schedule,
    required this.sessionCookie,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late ExamFormData _data;
  bool _processing = false;
  String? _activeGateway;
  final TextEditingController _practicalController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _data = widget.formData;
    _practicalController.text = _data.practicalSubjectsCount.toString();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _practicalController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    children: [
                      _buildAmountCard(),
                      const SizedBox(height: 20),
                      if (!_data.isPaid) _buildGatewaySection(),
                      if (_data.isPaid) _buildPaidSuccess(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
      decoration: BoxDecoration(
        color: _kCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _kTextDark, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 2),
              const Text(
                'Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextDark),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _data.isPaid ? const Color(0xFFD5F5E3) : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _data.isPaid ? 'PAID' : 'UNPAID',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: _data.isPaid ? const Color(0xFF1E8449) : const Color(0xFF856404),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, size: 13, color: _kTextMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.schedule.examScheduleName,
                    style: const TextStyle(fontSize: 11, color: _kTextMuted, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Column(
      children: [
        // Info banner
        if (!_data.isPaid)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFF9A825)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You need to make the payment first to fill up the application. After the successful payment you will be automatically redirected to the application form.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF5D4037).withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!_data.isPaid) const SizedBox(height: 14),
        // Main card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPrimary, _kPrimary.withValues(alpha: 0.4)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  children: [
                    Text(
                      'Rs. ${_data.totalAmount.toInt()}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: _kTextDark,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTextMuted.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Exam info row
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_note_rounded, size: 16, color: _kPrimary.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.schedule.examScheduleName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary.withValues(alpha: 0.85),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Fee breakdown
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _buildFeeRow(
                            _data.isSeparatePaymentForPractical
                                ? 'Exam Fee (Excl. Practical)'
                                : 'Exam Fee',
                            _data.paymentAmount.toInt(),
                          ),
                          if (_data.isSeparatePaymentForPractical) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, color: _kBorder),
                            ),
                            _buildPracticalSection(),
                          ],
                        ],
                      ),
                    ),
                    if (_data.studentName != null || _data.programName != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_data.studentName != null)
                              _buildDetailRow(Icons.person_outline_rounded, _data.studentName!),
                            if (_data.programName != null) ...[
                              if (_data.studentName != null) const SizedBox(height: 6),
                              _buildDetailRow(Icons.menu_book_rounded, _data.programName!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _kTextMuted, fontWeight: FontWeight.w500)),
        Text(
          'Rs. $amount',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextDark),
        ),
      ],
    );
  }

  Widget _buildPracticalSection() {
    final practicalTotal = (_data.practicalSubjectsCount * _data.ratePerSubject).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Practical Subjects',
              style: TextStyle(fontSize: 13, color: _kTextMuted, fontWeight: FontWeight.w500),
            ),
            Text(
              'Rs. $practicalTotal',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextDark),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Stepper row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepperButton(
                      icon: Icons.remove_rounded,
                      onTap: _data.practicalSubjectsCount > 0
                          ? () {
                              setState(() {
                                _data.practicalSubjectsCount--;
                                _practicalController.text = _data.practicalSubjectsCount.toString();
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 48,
                      height: 36,
                      child: TextField(
                        controller: _practicalController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextDark),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          final count = int.tryParse(val) ?? 0;
                          setState(() => _data.practicalSubjectsCount = count < 0 ? 0 : count);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildStepperButton(
                      icon: Icons.add_rounded,
                      onTap: () {
                        setState(() {
                          _data.practicalSubjectsCount++;
                          _practicalController.text = _data.practicalSubjectsCount.toString();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '\u00d7 Rs. ${_data.ratePerSubject.toInt()} / subject',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Note
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 14, color: Colors.orange.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'An additional charge of Rs ${_data.ratePerSubject.toStringAsFixed(2)} per subject will apply for each practical subject. Please confirm your practical subjects and proceed with the payment.',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade900, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepperButton({required IconData icon, VoidCallback? onTap}) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFF1F5F9) : _kPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDisabled ? _kTextMuted.withValues(alpha: 0.4) : _kPrimary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kPrimary.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: _kTextDark.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildGatewaySection() {
    final ms = _data.moduleSettings;
    final enabled = {
      'esewa': ms['Enable_Esewa_Payment'] == 'true' || ms['Enable_Esewa_Payment'] == true,
      'khalti': ms['Enable_Khalti_Payment'] == 'true' || ms['Enable_Khalti_Payment'] == true,
      'connectips': ms['Enable_ConnectIPS_Payment'] == 'true' || ms['Enable_ConnectIPS_Payment'] == true,
      'hbl': ms['Enable_HBL_Payment'] == 'true' || ms['Enable_HBL_Payment'] == true,
    };

    final available = _gateways.where((g) => enabled[g.key] == true).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            'Choose Payment Method',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kTextDark.withValues(alpha: 0.8),
            ),
          ),
        ),
        ...available.map((g) => _buildGatewayTile(g)),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                'Secure payment powered by FWU',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGatewayTile(_GatewayInfo gw) {
    final isActive = _activeGateway == gw.key;
    final isDisabled = _processing && !isActive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? gw.bgColor : _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? gw.color.withValues(alpha: 0.4) : _kBorder,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: gw.color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: (isDisabled || _processing) ? null : () => _handlePayment(gw.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: gw.bgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        gw.logoUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            gw.label[0],
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: gw.color),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gw.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDisabled ? _kTextMuted : _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pay Rs. ${_data.totalAmount.toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDisabled ? _kTextMuted.withValues(alpha: 0.5) : _kTextMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive && _processing)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: gw.color, strokeWidth: 2.5),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDisabled ? const Color(0xFFF1F5F9) : gw.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: isDisabled ? _kTextMuted.withValues(alpha: 0.3) : gw.color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaidSuccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD5F5E3)),
      ),
      child: Column(
        children: [
          const  DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFD5F5E3),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.check_rounded, color: Color(0xFF1E8449), size: 30),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Complete',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E8449)),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can now proceed to select your subjects\nand submit your application.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _kTextMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormFillScreen(
                      schedule: widget.schedule,
                      sessionCookie: widget.sessionCookie,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Continue to Form', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment(String gateway) async {
    setState(() {
      _processing = true;
      _activeGateway = gateway;
    });

    final formProv = Provider.of<FormProvider>(context, listen: false);
    final gdata = await formProv.payWithGateway(gateway, widget.sessionCookie);

    if (gdata == null) {
      setState(() {
        _processing = false;
        _activeGateway = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formProv.error ?? 'Payment initiation failed.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    try {
      String? html;
      String gatewayLabel = _gateways
          .firstWhere((g) => g.key == gateway, orElse: () => _gateways.first)
          .label;

      if (gateway == 'khalti') {
        // Khalti returns a direct URL — load it in WebView
        final url = gdata['payment_url']?.toString();
        if (url != null && url.isNotEmpty) {
          html = '''<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head><body>
<p style="text-align:center;padding:40px;font-family:sans-serif;">Redirecting to Khalti...</p>
<script>window.location.href="${_htmlEscapeJs(url)}";</script>
</body></html>''';
        } else {
          throw Exception('Khalti payment URL not received.');
        }
      } else {
        // eSewa, ConnectIPS, HBL — form POST
        html = formProv.buildGatewayFormHtml(gateway, gdata);
        if (html == null) {
          // Log what we got for debugging
          throw Exception('Could not build gateway form. Missing PostUrl/GatewayUrl.');
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              gatewayHtml: html!,
              title: '$gatewayLabel Payment',
              onPaymentSuccess: () {
                // Payment confirmed — update UI
                if (mounted) {
                  setState(() => _data.isPaid = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text('Payment verified! You can now fill the form.'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF1E8449),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              onPaymentFailure: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text('Payment failed. Please try again.'),
                        ],
                      ),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _activeGateway = null;
        });
      }
    }
  }

  static String _htmlEscapeJs(String s) {
    return s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n');
  }
}
