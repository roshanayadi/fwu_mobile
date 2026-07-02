import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';

const _kPrimaryGreen = Color(0xFF0F6E56);
const _kAccentGold = Color(0xFFEF9F27);
const _kBgColor = Color(0xFFF1F5F9);

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _updateImage(BuildContext context, bool isPhoto) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.updateProfileAttachment(
        imageFile: File(image.path),
        isPhoto: isPhoto,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: _kPrimaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update image'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.studentInfo;

    if (user == null) {
      return Scaffold(
        backgroundColor: _kBgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No student data available.",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── PERMANENT HEADER ───────────────────────────────────
            _ProfileHeader(
              user: user,
              onEditPhoto: () => _updateImage(context, true),
              isUploading: _isUploading,
            ),
            // ─── SCROLLABLE BODY ────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _buildQuickStats(user),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Personal Information'),
                      _buildInfoCard([
                        _InfoItem(Icons.cake_outlined, 'Date of Birth', user.dob),
                        _InfoItem(Icons.person_3_outlined, 'Gender', user.gender),
                        _InfoItem(Icons.bloodtype_outlined, 'Blood Group', user.bloodGroup),
                        _InfoItem(Icons.public_outlined, 'Nationality', user.nationality),
                        _InfoItem(Icons.groups_outlined, 'Ethnicity', user.ethnicity),
                        _InfoItem(Icons.temple_buddhist_outlined, 'Religion', user.religion),
                        _InfoItem(Icons.category_outlined, 'Category', user.category),
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Contact Details'),
                      _buildInfoCard([
                        _InfoItem(Icons.phone_outlined, 'Mobile', user.contact),
                        _InfoItem(Icons.email_outlined, 'Email', user.email),
                        _InfoItem(Icons.location_on_outlined, 'Address', user.address),
                      ]),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Academic Information'),
                      _buildInfoCard([
                        _InfoItem(Icons.school_outlined, 'College', user.college),
                        _InfoItem(Icons.history_edu_outlined, 'Faculty', user.faculty),
                        _InfoItem(Icons.calendar_today_outlined, 'Year', user.academicYear),
                        _InfoItem(Icons.badge_outlined, 'Registration No', user.registrationNo),
                      ]),
                      const SizedBox(height: 20),
                      // ─── SIGNATURE CARD (at the end) ────────────────────────
                      _buildSignatureCard(user, onEdit: () => _updateImage(context, false)),
                      const SizedBox(height: 32),
                    ],
                  ),
                  if (_isUploading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: _kPrimaryGreen),
                                SizedBox(height: 16),
                                Text('Uploading to FWU Portal...', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSignatureCard(dynamic user, {required VoidCallback onEdit}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'SIGNATURE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: _kPrimaryGreen, size: 10),
                        SizedBox(width: 3),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: _kPrimaryGreen,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Update', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: _kPrimaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kPrimaryGreen.withOpacity(0.15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildImageWidget(user.signature, fallbackIcon: Icons.draw_outlined, iconSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Officially verified for academic purposes',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String? src, {required IconData fallbackIcon, double iconSize = 40}) {
    if (src == null || src.isEmpty) {
      return Center(
        child: Icon(fallbackIcon, size: iconSize, color: Colors.grey.shade300),
      );
    }
    if (src.startsWith('data:image')) {
      try {
        final base64String = src.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(fallbackIcon, size: iconSize, color: Colors.grey.shade300),
          ),
        );
      } catch (_) {
        return Center(child: Icon(fallbackIcon, size: iconSize, color: Colors.grey.shade300));
      }
    }
    final url = src.startsWith('/') ? 'https://exam.fwu.edu.np$src' : src;
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kPrimaryGreen,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Center(
        child: Icon(fallbackIcon, size: iconSize, color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildQuickStats(dynamic user) {
    return Row(
      children: [
        _StatChip(icon: Icons.school_outlined, label: user.academicYear ?? '—', color: _kPrimaryGreen),
        const SizedBox(width: 10),
        _StatChip(icon: Icons.bloodtype_outlined, label: user.bloodGroup ?? '—', color: const Color(0xFFDC2626)),
        const SizedBox(width: 10),
        _StatChip(icon: Icons.verified_outlined, label: 'Verified', color: _kAccentGold),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _kPrimaryGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: _kPrimaryGreen, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 66),
                  child: Divider(height: 1, color: Colors.grey.shade100),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── PERMANENT PROFILE HEADER ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final VoidCallback onEditPhoto;
  final bool isUploading;
  const _ProfileHeader({required this.user, required this.onEditPhoto, required this.isUploading});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
      decoration: const BoxDecoration(
        color: _kBgColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (canPop) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: Ink(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 24),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Stack(
            children: [
              _buildAvatar(user.photo),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: _kPrimaryGreen,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    onTap: isUploading ? null : onEditPhoto,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kPrimaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kPrimaryGreen.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kAccentGold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'REG: ${user.registrationNo}',
                        style: const TextStyle(
                          color: _kPrimaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.faculty ?? '',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ]
      ),
    );
  }

  Widget _buildAvatar(String? photoData) {
    ImageProvider? imageProvider;
    if (photoData != null && photoData.isNotEmpty) {
      if (photoData.startsWith('data:image')) {
        try {
          final base64String = photoData.split(',').last;
          imageProvider = MemoryImage(base64Decode(base64String));
        } catch (e) {
        }
      } else if (photoData.startsWith('http')) {
        imageProvider = NetworkImage(photoData);
      } else if (photoData.startsWith('/')) {
        imageProvider = NetworkImage('https://exam.fwu.edu.np$photoData');
      }
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kPrimaryGreen, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(Icons.person, size: 32, color: Colors.grey.shade400)
            : null,
      ),
    );
  }
}

// ─── STAT CHIP ────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── INFO ITEM DATA ───────────────────────────────────────────────────────
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}
