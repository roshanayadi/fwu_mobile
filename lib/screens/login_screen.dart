import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'forgot_password/forgot_password_screen.dart';

const _kNavy = Color(0xFF0F172A); // Deeper, modern navy slate
const _kBlue = Color(0xFF3B82F6); // Crisp bright blue
const _kBg = Color(0xFFF8FAFC);   // Very light slate background
const _kTextDark = Color(0xFF1E293B);
const _kTextMuted = Color(0xFF64748B);
const _kWarnBg = Color(0xFFFFFBEB);
const _kWarnBorder = Color(0xFFFDE68A);
const _kWarnText = Color(0xFF92400E);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Register controllers
  final _regUsernameController = TextEditingController();
  final _regDobController = TextEditingController();
  bool _obscureRegPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
      Provider.of<AuthProvider>(context, listen: false).clearError();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regDobController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final password = _loginPasswordController.text.trim();
      bool success = await auth.login(
        _loginUsernameController.text.trim(),
        password,
      );

      if (success && mounted) {
        // If login succeeded but there's a non-blocking warning (e.g. profile
        // fetch failed), show it as a SnackBar before navigating away.
        if (auth.error != null && auth.error!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.error!),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        final isDobFormat = RegExp(r'^\d{4}[/-]\d{2}[/-]\d{2}$').hasMatch(password) || RegExp(r'^\d{2}[/-]\d{2}[/-]\d{4}$').hasMatch(password);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => HomeScreen(promptChangePassword: isDobFormat)),
        );
      }
    }
  }

  void _handleRegister() async {
    if (_regFormKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final dobPassword = _regDobController.text.trim();
      
      bool success = await auth.login(
        _regUsernameController.text.trim(),
        dobPassword,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const HomeScreen(promptChangePassword: true)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Elegant Background Glows
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kBlue.withValues(alpha: 0.15), Colors.transparent],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFF10B981).withValues(alpha: 0.1), Colors.transparent],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          
          Column(
            children: [
              // Dynamic Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: _kBlue.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5)),
                            const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Image.asset('assets/images/fwu_logo.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FWU Portal', 
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kNavy, letterSpacing: -0.2)
                            ),
                            Text(
                              'Exam Management System', 
                              style: TextStyle(fontSize: 13, color: _kTextMuted.withValues(alpha: 0.9), fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Styled Pill TabBar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _kBlue.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  labelColor: Colors.white,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelColor: _kTextMuted,
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
                ),
              ),

              // Interactive Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildLoginTab(auth),
                    _buildRegisterTab(auth),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('© Far Western University', style: TextStyle(fontSize: 12, color: _kTextMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTab(AuthProvider auth) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome Back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kNavy)),
            const SizedBox(height: 6),
            const Text('Login to access your dashboard and exams.', style: TextStyle(fontSize: 14, color: _kTextMuted)),
            const SizedBox(height: 32),
            
            if (auth.error != null) ...[
              _buildErrorBox(auth.error!),
              const SizedBox(height: 20),
            ],

            TextFormField(
              controller: _loginUsernameController,
              style: const TextStyle(fontSize: 15, color: _kTextDark, fontWeight: FontWeight.w500),
              decoration: _inputDecoration(label: 'Registration Number', hint: 'AG-2021-X-XX-XXXX', icon: Icons.badge_rounded),
              validator: (val) => val!.isEmpty ? 'Please enter your registration number' : null,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              style: const TextStyle(fontSize: 15, color: _kTextDark, fontWeight: FontWeight.w500),
              decoration: _inputDecoration(
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_rounded,
                suffix: IconButton(
                  icon: Icon(_obscureLoginPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: _kTextMuted),
                  onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                ),
              ),
              validator: (val) => val!.isEmpty ? 'Please enter your password' : null,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                  ),
                  child: const Text('Forgot Password?', style: TextStyle(color: _kTextMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                  child: const Text('New? Register', style: TextStyle(color: _kBlue, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildGradientButton(
              text: 'Sign In',
              isLoading: auth.isLoading,
              onPressed: _handleLogin,
            ),
            if (auth.isBiometricEnabled) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const Text('OR', style: TextStyle(color: _kTextMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        bool success = await auth.loginWithBiometrics();
                        if (success && mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (c) => const HomeScreen(promptChangePassword: false)),
                          );
                        } else if (auth.error != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(auth.error!)),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: _kBlue.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                          border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, size: 36, color: _kBlue),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Login with Biometrics', style: TextStyle(color: _kTextMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab(AuthProvider auth) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Form(
        key: _regFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activate Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kNavy)),
            const SizedBox(height: 6),
            const Text('Link your DOB to generate your first password.', style: TextStyle(fontSize: 14, color: _kTextMuted)),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kWarnBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kWarnBorder.withValues(alpha: 0.5))),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, size: 20, color: _kWarnText),
                  SizedBox(width: 12),
                  Expanded(child: Text('Enter your Registration No & Date of Birth (YYYY/MM/DD). You will be prompted to change it safely upon entry.', style: TextStyle(fontSize: 13, color: _kWarnText, height: 1.5, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (auth.error != null) ...[
              _buildErrorBox(auth.error!),
              const SizedBox(height: 20),
            ],

            TextFormField(
              controller: _regUsernameController,
              style: const TextStyle(fontSize: 15, color: _kTextDark, fontWeight: FontWeight.w500),
              decoration: _inputDecoration(label: 'Registration Number', hint: 'AG-2021-...', icon: Icons.person_pin_rounded),
              validator: (val) => val!.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _regDobController,
              obscureText: _obscureRegPassword,
              style: const TextStyle(fontSize: 15, color: _kTextDark, fontWeight: FontWeight.w500),
              decoration: _inputDecoration(
                label: 'Date of Birth',
                hint: 'YYYY/MM/DD',
                icon: Icons.calendar_month_rounded,
                suffix: IconButton(
                  icon: Icon(_obscureRegPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: _kTextMuted),
                  onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                ),
              ),
              validator: (val) => val!.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 36),

            _buildGradientButton(
              text: 'Complete Registration',
              isLoading: auth.isLoading,
              onPressed: _handleRegister,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({required String text, required bool isLoading, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [_kBlue, const Color(0xFF2563EB)]),
        boxShadow: [
          BoxShadow(color: _kBlue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildErrorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, size: 20, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextMuted, fontWeight: FontWeight.w500, fontSize: 15),
      hintText: hint, 
      hintStyle: TextStyle(fontSize: 14, color: _kTextMuted.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, size: 22, color: _kTextMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: const Color(0xFFE2E8F0), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kBlue, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
    );
  }
}
