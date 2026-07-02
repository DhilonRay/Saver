import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../admin_controller.dart';
import '../admin_theme.dart';
import '../../services/supabase_service.dart';
import 'package:saver/components/alert.dart';

class GLMPage extends StatefulWidget {
  const GLMPage({super.key});
  @override
  State<GLMPage> createState() => _GLMPageState();
}

class _GLMPageState extends State<GLMPage> {
  final AdminController _ctrl = Get.find<AdminController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
      child: Column(
        children: [
          // Add GLM button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: GlassCard(
              onTap: _showAddGLMDialog,
              accentColor: AdminTheme.accentGlow,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AdminTheme.accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add New GLM',
                    style: AdminTheme.heading3.copyWith(color: AdminTheme.accent),
                  ),
                ],
              ),
            ),
          ),

          // Scoreboard banner
          _buildScoreboard(),

          // GLM List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService.client.from('glm_accounts').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: AdminTheme.body));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
                
                final rawGlms = snapshot.data ?? [];
                var glms = rawGlms.map((item) => SupabaseService.toCamelCase(item)).toList();
                glms.sort((a, b) {
                  final aScore = (a['score'] as num?)?.toDouble() ?? 0.0;
                  final bScore = (b['score'] as num?)?.toDouble() ?? 0.0;
                  return bScore.compareTo(aScore);
                });

                if (glms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AdminTheme.bgSurface.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.business_center_rounded, size: 40, color: AdminTheme.textMuted),
                        ),
                        const SizedBox(height: 14),
                        const Text('No GLM accounts yet', style: AdminTheme.body),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: glms.length,
                  itemBuilder: (context, index) {
                    var data = glms[index];
                    var id = data['id'] ?? data['uid'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: () => _showGLMDetails(id, data),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AdminTheme.purple.withOpacity(0.2), AdminTheme.purple.withOpacity(0.05)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: AdminTheme.purple, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['hospital'] ?? 'N/A', style: AdminTheme.heading3.copyWith(fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('ID: ${data['glmId'] ?? 'N/A'}', style: AdminTheme.bodySmall),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, color: AdminTheme.amber, size: 14),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${data['score'] ?? 0}',
                                      style: const TextStyle(
                                        color: AdminTheme.amber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '৳${data['totalIncome'] ?? 0}',
                                  style: AdminTheme.heading3.copyWith(color: AdminTheme.green, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AdminTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GLM Partner Scoreboard', style: AdminTheme.heading2),
              SizedBox(height: 4),
              Text(
                'Top performing hospital referrals',
                style: TextStyle(color: AdminTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
          Icon(Icons.emoji_events_rounded, color: AdminTheme.amber, size: 28),
        ],
      ),
    );
  }

  void _showAddGLMDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final hospCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final fKey = GlobalKey<FormState>();

    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AdminTheme.bgCard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: fKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: AdminTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Add GLM Account', style: AdminTheme.heading2),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _glmField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _glmField(phoneCtrl, 'Phone Number', Icons.phone_android_rounded),
                  const SizedBox(height: 12),
                  _glmField(hospCtrl, 'Hospital/Clinic Name', Icons.local_hospital_outlined),
                  const SizedBox(height: 12),
                  _glmField(idCtrl, 'GLM Username / ID', Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _glmField(passCtrl, 'Password', Icons.lock_outline_rounded),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: AdminTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (fKey.currentState!.validate()) {
                              try {
                                await _ctrl.createGLMAccount(
                                  name: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  hospital: hospCtrl.text.trim(),
                                  glmId: idCtrl.text.trim(),
                                  password: passCtrl.text.trim(),
                                );
                                Get.back();
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  Alert.success('GLM Account created successfully');
                                });
                              } catch (e) {
                                Get.back();
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  Alert.error('$e');
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Create',
                            style: TextStyle(color: AdminTheme.bgDeep, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glmField(TextEditingController ctrl, String hint, IconData icon) {
    return TextFormField(
      controller: ctrl,
      style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AdminTheme.body.copyWith(color: AdminTheme.textMuted.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AdminTheme.accent.withOpacity(0.5), size: 18),
        filled: true,
        fillColor: AdminTheme.bgDeep.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminTheme.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminTheme.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  void _showGLMDetails(String id, Map<String, dynamic> data) {
    Get.to(() => _GLMDetailPage(glmId: id, data: data));
  }
}

class _GLMDetailPage extends StatefulWidget {
  final String glmId;
  final Map<String, dynamic> data;
  const _GLMDetailPage({required this.glmId, required this.data});
  @override
  State<_GLMDetailPage> createState() => _GLMDetailPageState();
}

class _GLMDetailPageState extends State<_GLMDetailPage> {
  String _filter = 'month';

  @override
  Widget build(BuildContext context) {
    final nameStr = (widget.data['name'] ?? '').toString().trim();
    final initial = nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'G';

    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: AdminAppBar(title: widget.data['name'] ?? 'GLM'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GLM info card
            GlassCard(
              accentColor: AdminTheme.purple,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AdminTheme.purple.withOpacity(0.15),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AdminTheme.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.data['hospital'] ?? 'N/A', style: AdminTheme.heading2),
                            const SizedBox(height: 4),
                            Text('ID: ${widget.data['glmId'] ?? 'N/A'}', style: AdminTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withOpacity(0.04)),
                  const SizedBox(height: 12),
                  AdminDetailRow(label: 'Referrer Name', value: widget.data['name'] ?? 'N/A'),
                  AdminDetailRow(label: 'Phone Number', value: widget.data['phone'] ?? 'N/A'),
                  AdminDetailRow(label: 'Referral Score', value: '${widget.data['score'] ?? 0} points'),
                  AdminDetailRow(label: 'Total Trips', value: '${widget.data['totalTripsOrdered'] ?? 0} refer'),
                  AdminDetailRow(label: 'Total Income', value: '৳${widget.data['totalIncome'] ?? 0}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filter + trip history
            Row(
              children: [
                const AdminSectionHeader(title: 'Trip History', icon: Icons.history_rounded),
                const Spacer(),
                AdminFilterChip(label: 'Day', selected: _filter == 'day', onTap: () => setState(() => _filter = 'day')),
                const SizedBox(width: 6),
                AdminFilterChip(label: 'Week', selected: _filter == 'week', onTap: () => setState(() => _filter = 'week')),
                const SizedBox(width: 6),
                AdminFilterChip(label: 'Month', selected: _filter == 'month', onTap: () => setState(() => _filter = 'month')),
              ],
            ),
            const SizedBox(height: 14),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _buildTripQuery(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: AdminTheme.body));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
                
                // Filter by date and sort locally to avoid composite index
                DateTime now = DateTime.now();
                DateTime start;
                switch (_filter) {
                  case 'day': start = DateTime(now.year, now.month, now.day); break;
                  case 'week': start = now.subtract(const Duration(days: 7)); break;
                  default: start = DateTime(now.year, now.month, 1);
                }
                
                final rawTrips = snapshot.data ?? [];
                var trips = rawTrips.where((item) {
                  var d = SupabaseService.toCamelCase(item);
                  if (d['timestamp'] == null) return false;
                  final date = DateTime.tryParse(d['timestamp'].toString());
                  return date != null && date.isAfter(start);
                }).map((item) => SupabaseService.toCamelCase(item)).toList();

                trips.sort((a, b) {
                  try {
                    final aTStr = a['timestamp'] ?? a['createdAt'];
                    final bTStr = b['timestamp'] ?? b['createdAt'];
                    if (aTStr == null) return 1;
                    if (bTStr == null) return -1;
                    final aT = DateTime.tryParse(aTStr.toString());
                    final bT = DateTime.tryParse(bTStr.toString());
                    if (aT == null) return 1;
                    if (bT == null) return -1;
                    return bT.compareTo(aT);
                  } catch (_) { return 0; }
                });

                if (trips.isEmpty) {
                  return GlassCard(
                    child: const Center(
                      child: Text('No trips in this period', style: AdminTheme.body),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    var t = trips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(t['ambulanceName'] ?? t['driverName'] ?? t['companyName'] ?? 'Ambulance', style: AdminTheme.heading3.copyWith(fontSize: 13)),
                                ),
                                Text(
                                  '৳${t['fareAmount'] ?? t['finalFare'] ?? t['confirmedFare'] ?? t['fare'] ?? 0}',
                                  style: AdminTheme.heading3.copyWith(color: AdminTheme.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AdminDetailRow(label: 'Driver Phone', value: t['driverPhone'] ?? 'N/A'),
                            AdminDetailRow(label: 'From', value: t['pickupAddress'] ?? 'N/A'),
                            AdminDetailRow(label: 'To', value: t['destinationAddress'] ?? 'N/A'),
                            if (t['timestamp'] != null)
                              AdminDetailRow(
                                label: 'Date',
                                value: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(t['timestamp'].toString())!),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _buildTripQuery() {
    return SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('glm_id', widget.glmId);
  }
}
