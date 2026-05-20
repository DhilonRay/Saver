import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:saver/admin/admin_theme.dart';
import 'package:saver/auth/log_in/login_screen.dart';
import 'package:saver/home_user/home_user.dart';

class GLMDashboard extends StatefulWidget {
  final String glmId;
  const GLMDashboard({super.key, required this.glmId});

  @override
  State<GLMDashboard> createState() => _GLMDashboardState();
}

class _GLMDashboardState extends State<GLMDashboard> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  Map<String, dynamic>? _glmData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGLMProfile();
  }

  Future<void> _loadGLMProfile() async {
    try {
      DocumentSnapshot doc = await _fs.collection('glm_accounts').doc(widget.glmId).get();
      if (doc.exists) {
        setState(() {
          _glmData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading GLM profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGLMLoggedIn', false);
    await prefs.remove('currentGLMId');
    Get.offAll(() => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AdminTheme.bgDeep,
        body: Center(child: CircularProgressIndicator(color: AdminTheme.purple)),
      );
    }

    if (_glmData == null) {
      return Scaffold(
        backgroundColor: AdminTheme.bgDeep,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('GLM profile not found', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _logout, child: const Text('Back to Login')),
            ],
          ),
        ),
      );
    }

    final String name = _glmData!['name'] ?? 'GLM Partner';
    final String hospital = _glmData!['hospital'] ?? 'N/A';
    final String phone = _glmData!['phone'] ?? 'N/A';
    final int score = _glmData!['score'] ?? 0;
    final int trips = _glmData!['totalTripsOrdered'] ?? 0;
    final double income = (_glmData!['totalIncome'] ?? 0.0).toDouble();

    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: AppBar(
        title: Text(hospital, style: AdminTheme.heading2),
        backgroundColor: AdminTheme.bgDeep,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AdminTheme.red),
            onPressed: () {
              Get.defaultDialog(
                title: 'Log Out',
                titleStyle: const TextStyle(color: Colors.white),
                middleText: 'Are you sure you want to log out?',
                middleTextStyle: const TextStyle(color: Colors.white70),
                backgroundColor: AdminTheme.bgCard,
                textConfirm: 'Log Out',
                confirmTextColor: Colors.white,
                buttonColor: AdminTheme.red,
                textCancel: 'Cancel',
                cancelTextColor: AdminTheme.accent,
                onConfirm: _logout,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Partner Welcome Banner ──
              GlassCard(
                accentColor: AdminTheme.purple,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminTheme.purple.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: AdminTheme.purple, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome Back,', style: AdminTheme.bodySmall.copyWith(color: AdminTheme.textMuted)),
                          const SizedBox(height: 2),
                          Text(name, style: AdminTheme.heading2),
                          const SizedBox(height: 4),
                          Text('GLM ID: ${widget.glmId} • $phone', style: AdminTheme.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Key Metrics Grid ──
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  AdminStatCard(
                    title: 'Score',
                    value: '$score',
                    icon: Icons.emoji_events_rounded,
                    color: AdminTheme.amber,
                    subtitle: 'Medal Tier',
                  ),
                  AdminStatCard(
                    title: 'Trips Ordered',
                    value: '$trips',
                    icon: Icons.route_rounded,
                    color: AdminTheme.blue,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFullWidthRevenueCard(income),
              const SizedBox(height: 24),

              // ── Primary Action Button: Book Ambulance ──
              ElevatedButton(
                onPressed: () {
                  // Navigate to booking page like a normal user!
                  Get.to(() => HomePage());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.accent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AdminTheme.accent.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_location_alt_rounded, color: AdminTheme.bgDeep, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Book New Ambulance 🚑',
                      style: AdminTheme.heading3.copyWith(color: AdminTheme.bgDeep, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Recent Trips ordered by this GLM ──
              AdminSectionHeader(
                title: 'Your Trip History',
                icon: Icons.history_rounded,
                color: AdminTheme.purple,
              ),
              _buildTripHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs
          .collection('trips')
          .where('glmId', isEqualTo: widget.glmId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AdminTheme.purple));
        }
        var trips = snapshot.data!.docs;
        if (trips.isEmpty) {
          return GlassCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.assignment_rounded, color: AdminTheme.textMuted.withOpacity(0.5), size: 36),
                    const SizedBox(height: 10),
                    const Text('No trips ordered yet', style: AdminTheme.body),
                  ],
                ),
              ),
            ),
          );
        }

        // Sort locally
        var sortedTrips = trips.toList()
          ..sort((a, b) {
            var aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            var bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedTrips.length,
          itemBuilder: (context, index) {
            var data = sortedTrips[index].data() as Map<String, dynamic>;
            var from = data['pickupAddress'] ?? data['pickupName'] ?? 'Pickup';
            var to = data['destinationAddress'] ?? data['destinationName'] ?? 'Destination';
            var status = (data['status'] ?? 'unknown').toString().toUpperCase();
            var fare = data['fare'] ?? 0;
            var dateStr = '';
            if (data['createdAt'] != null) {
              DateTime dt = (data['createdAt'] as Timestamp).toDate();
              dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
            }

            Color statusColor = AdminTheme.amber;
            if (status == 'COMPLETED') statusColor = AdminTheme.green;
            if (status == 'CANCELLED' || status == 'FAILED') statusColor = AdminTheme.red;
            if (status == 'ONGOING' || status == 'ACCEPTED') statusColor = AdminTheme.blue;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr, style: AdminTheme.caption),
                        AdminStatusBadge(label: status, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 10, color: AdminTheme.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            from,
                            style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: AdminTheme.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            to,
                            style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AdminTheme.divider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ambulance: ${data['ambulanceName'] ?? 'Pending'}', style: AdminTheme.bodySmall),
                        Text('৳$fare', style: AdminTheme.heading3.copyWith(color: AdminTheme.green)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFullWidthRevenueCard(double income) {
    return GlassCard(
      accentColor: AdminTheme.green,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTheme.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monetization_on_rounded, color: AdminTheme.green, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Revenue Contribution', style: AdminTheme.bodySmall),
                const SizedBox(height: 4),
                Text('৳${income.toStringAsFixed(0)}', style: AdminTheme.stat.copyWith(color: AdminTheme.green, fontSize: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
