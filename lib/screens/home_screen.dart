import 'package:flutter/material.dart';
import '../components/floating_dock.dart';
import '../components/floating_ai_bubble.dart';
import 'dashboard_screen.dart';
import 'result_screen.dart';
import 'forms_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'setting_widgets/change_password_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool promptChangePassword;

  const HomeScreen({super.key, this.promptChangePassword = false});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.promptChangePassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showChangePasswordPrompt();
      });
    }
  }

  void _showChangePasswordPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFF1A5276)),
            SizedBox(width: 8),
            Text(
              'Update Password',
              style: TextStyle(
                color: Color(0xFF1A5276),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'You are currently using your Date of Birth as your password. For security reasons, please change your password immediately.',
          style: TextStyle(height: 1.5, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Later',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A5276),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _goToProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
  }

  List<Widget> get _screens => [
    DashboardScreen(onProfileTap: _goToProfile),
    ResultScreen(),
    FormsScreen(),
    const NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      extendBody: true, // Let content scroll behind dock
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingDock(
              currentIndex: _currentIndex,
              onTabSelected: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
          const FloatingAiBubble(),
        ],
      ),
    );
  }
}
