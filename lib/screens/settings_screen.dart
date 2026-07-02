import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'setting_widgets/change_password_screen.dart';
import 'setting_widgets/terms_conditions_screen.dart';
import 'setting_widgets/privacy_policy_screen.dart';
import 'setting_widgets/help_faq_screen.dart';
import 'setting_widgets/contact_about_screen.dart';

const _kPrimary = Color(0xFF0F6E56);
const _kBg = Color(0xFFF1F5F9);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1E293B);
const _kTextMuted = Color(0xFF94A3B8);
const _kBorder = Color(0xFFE8ECF0);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.studentInfo;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, user),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [

                  _buildSection('Account', [
                    _SettingItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile Information',
                      subtitle: 'View your student details',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen()),
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your login password',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Notifications', [
                    _SettingItem(
                      icon: Icons.notifications_outlined,
                      title: 'Exam Notifications',
                      subtitle: 'Get alerts for exam schedules & results',
                      trailing: _buildSwitch(true),
                    ),
                    _SettingItem(
                      icon: Icons.campaign_outlined,
                      title: 'University Notices',
                      subtitle: 'Announcements from FWU',
                      trailing: _buildSwitch(true),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('General', [
                    _SettingItem(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {},
                    ),
                    if (auth.isAuthenticated)
                      _SettingItem(
                        icon: Icons.fingerprint_rounded,
                        title: 'Biometric Login',
                        subtitle: 'Enable fingerprint for quicker access',
                        trailing: SizedBox(
                          height: 24,
                          child: Switch(
                            value: auth.isBiometricEnabled,
                            onChanged: (val) async {
                              final success = await auth.setBiometricEnabled(val);
                              if (!success && val) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(auth.error ?? 'Failed to enable biometrics')),
                                  );
                                }
                              }
                            },
                            activeColor: _kPrimary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    _SettingItem(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Support', [
                    _SettingItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & FAQ',
                      subtitle: 'Common queries about exams & forms',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpFaqScreen()),
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.mail_outline_rounded,
                      title: 'Contact FWU',
                      subtitle: 'info@fwu.edu.np',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContactAboutScreen()),
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      subtitle: 'Far Western University EMIS',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContactAboutScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  if (auth.isAuthenticated) _buildLogoutButton(context, auth),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'FWU EMIS v1.0.2 (Build 45)',
                      style: TextStyle(fontSize: 11, color: _kTextMuted.withValues(alpha: 0.6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    ImageProvider? img;
    if (user != null) {
      final photo = user.photo as String?;
      if (photo != null && photo.isNotEmpty) {
        if (photo.startsWith('data:image')) {
          try {
            img = MemoryImage(base64Decode(photo.split(',').last));
          } catch (_) {}
        } else if (photo.startsWith('http')) {
          img = NetworkImage(photo);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kPrimary.withValues(alpha: 0.3), width: 1.5),
                  image: img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
                ),
                child: img == null
                    ? const Icon(Icons.person_rounded, color: _kTextMuted, size: 30)
                    : null,
              ),
            ),
          ),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _kTextDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_SettingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kTextMuted.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: isLast && i == 0
                        ? BorderRadius.circular(16)
                        : i == 0
                            ? const BorderRadius.vertical(top: Radius.circular(16))
                            : isLast
                                ? const BorderRadius.vertical(bottom: Radius.circular(16))
                                : BorderRadius.zero,
                    child: InkWell(
                      borderRadius: isLast && i == 0
                          ? BorderRadius.circular(16)
                          : i == 0
                              ? const BorderRadius.vertical(top: Radius.circular(16))
                              : isLast
                                  ? const BorderRadius.vertical(bottom: Radius.circular(16))
                                  : BorderRadius.zero,
                      onTap: item.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _kPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.icon, size: 18, color: _kPrimary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _kTextDark,
                                    ),
                                  ),
                                  if (item.subtitle != null) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      item.subtitle!,
                                      style: const TextStyle(fontSize: 11, color: _kTextMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            item.trailing ??
                                Icon(Icons.chevron_right_rounded, size: 20, color: _kTextMuted.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 66),
                      child: Divider(height: 1, color: _kBorder.withValues(alpha: 0.6)),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(bool value) {
    return SizedBox(
      height: 24,
      child: Switch(
        value: value,
        onChanged: (v) {},
        activeColor: _kPrimary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Logout?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                content: const Text('Are you sure you want to logout from this device?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 18, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}
