import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

const _kPrimary = Color(0xFF0F6E56);
const _kPrimaryDark = Color(0xFF0B4E3C);
const _kAccent = Color(0xFFEF9F27);
const _kTextDark = Color(0xFF1E293B);

class DigitalIdScreen extends StatelessWidget {
  const DigitalIdScreen({super.key});

  ImageProvider _getUserPhoto(dynamic photoData) {
    if (photoData == null || photoData.isEmpty) {
      return const AssetImage('assets/images/lokesh.jpg');
    }
    if (photoData.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(photoData.split(',').last));
      } catch (_) {}
    } else if (photoData.startsWith('http')) {
      return NetworkImage(photoData);
    }
    return const AssetImage('assets/images/lokesh.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.studentInfo;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0), // A slightly darker smooth background so the card pops
      appBar: AppBar(
        title: const Text('Digital ID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextDark, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kTextDark),
      ),
      body: user == null
          ? const Center(child: Text("No student data available"))
          : Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Card Container
                    Container(
                      width: 300, // Made smaller and structured
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: -2,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Background Watermark Logo
                          Positioned(
                            right: -40,
                            top: 150,
                            child: Opacity(
                              opacity: 0.04,
                              child: Image.asset('assets/images/fwu_logo.png', width: 250, height: 250),
                            ),
                          ),
                          
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Colored Header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(top: 20, bottom: 36, left: 16, right: 16),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_kPrimary, _kPrimaryDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.asset('assets/images/fwu_logo.png', width: 50, height: 50),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'FAR WESTERN UNIVERSITY',
                                            style: TextStyle(
                                              color: Colors.white, 
                                              fontSize: 13, 
                                              fontWeight: FontWeight.w900, 
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Mahendranagar, Kanchanpur',
                                            style: TextStyle(
                                              color: Colors.white70, 
                                              fontSize: 10, 
                                              fontWeight: FontWeight.w500
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'STUDENT IDENTITY CARD',
                                            style: TextStyle(
                                              color: _kAccent, 
                                              fontSize: 10, 
                                              fontWeight: FontWeight.bold, 
                                              letterSpacing: 1.2
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Overlapping Profile Photo
                              Transform.translate(
                                offset: const Offset(0, -35),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 105,
                                      height: 105,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.12), 
                                            blurRadius: 15, 
                                            offset: const Offset(0, 5)
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: _getUserPhoto(user.photo),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Student Name
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        user.fullName.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 20, 
                                          fontWeight: FontWeight.w900, 
                                          color: _kTextDark, 
                                          letterSpacing: 0.5,
                                          height: 1.1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Faculty Box
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _kPrimary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _kPrimary.withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        user.faculty.isNotEmpty ? user.faculty : 'Faculty of Education',
                                        style: const TextStyle(color: _kPrimaryDark, fontSize: 13, fontWeight: FontWeight.w800),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Info Grid
                              Transform.translate(
                                offset: const Offset(0, -10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    children: [
                                      _buildInfoRow('Reg. No', user.registrationNo.isNotEmpty ? user.registrationNo : 'N/A'),
                                      _buildDivider(),
                                      _buildInfoRow('Campus', user.college.isNotEmpty ? user.college : 'Central Campus'),
                                      _buildDivider(),
                                      _buildInfoRow('DOB', user.dob.isNotEmpty ? user.dob : 'N/A'),
                                      _buildDivider(),
                                      _buildInfoRow('Gender', user.gender.isNotEmpty ? user.gender : 'N/A'),
                                      _buildDivider(),
                                      _buildInfoRow('Contact', user.contact.isNotEmpty ? user.contact : 'N/A'),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),

                              // Bottom Authenticity Bar
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: Column(
                                  children: [
                                    Image.asset('assets/images/signature.png', height: 30, errorBuilder: (_, __, ___) => const SizedBox(height: 30)),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'AUTHORIZED SIGNATURE',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1.0),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    // Trust verification tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, size: 16, color: _kPrimary),
                          SizedBox(width: 8),
                          Text(
                            'Official Digital Identity',
                            style: TextStyle(fontSize: 13, color: _kPrimaryDark, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Text(':', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _kTextDark, fontSize: 12, fontWeight: FontWeight.w800, height: 1.3),
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1.5),
    );
  }
}
