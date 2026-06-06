import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../admin_controller.dart';
import '../admin_theme.dart';

class GLMPage extends StatefulWidget {
  const GLMPage({super.key});
  @override
  State<GLMPage> createState() => _GLMPageState();
}

class _GLMPageState extends State<GLMPage> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
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
            child: StreamBuilder<QuerySnapshot>(
              stream: _fs.collection('glm_accounts').orderBy('score', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
                var glms = snapshot.data!.docs;
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
                    var data = glms[index].data() as Map<String, dynamic>;
                    var id = glms[index].id;
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
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: AdminTheme.heading3.copyWith(color: AdminTheme.purple),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['name'] ?? 'GLM', style: AdminTheme.heading3.copyWith(fontSize: 14)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_rounded, size: 12, color: AdminTheme.textMuted.withOpacity(0.6)),
                                      const SizedBox(width: 5),
                                      Text(data['phone'] ?? 'N/A', style: AdminTheme.bodySmall),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.local_hospital_rounded, size: 12, color: AdminTheme.textMuted.withOpacity(0.6)),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(data['hospital'] ?? 'N/A', style: AdminTheme.bodySmall, overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      AdminMiniTag(text: '৳${data['totalIncome'] ?? 0}', color: AdminTheme.green),
                                      const SizedBox(width: 6),
                                      AdminMiniTag(text: 'Trips: ${data['totalTripsOrdered'] ?? 0}', color: AdminTheme.blue),
                                      const SizedBox(width: 6),
                                      AdminMiniTag(text: 'Score: ${data['score'] ?? 0}', color: AdminTheme.amber),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AdminTheme.textMuted.withOpacity(0.4), size: 22),
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
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.collection('glm_accounts').orderBy('score', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        var top = snapshot.data!.docs;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: GlassCard(
            accentColor: AdminTheme.amber,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminTheme.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: AdminTheme.amber, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('GLM Scoreboard', style: AdminTheme.heading3.copyWith(color: AdminTheme.amber)),
                  ],
                ),
                const SizedBox(height: 14),
                ...top.asMap().entries.map((entry) {
                  var d = entry.value.data() as Map<String, dynamic>;
                  List<Color> medals = [AdminTheme.amber, const Color(0xFFB0BEC5), const Color(0xFF8D6E63)];
                  List<String> emojis = ['🥇', '🥈', '🥉'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Text(emojis[entry.key], style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(d['name'] ?? 'GLM', style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary, fontWeight: FontWeight.w500)),
                        ),
                        AdminMiniTag(
                          text: 'Score: ${d['score'] ?? 0}',
                          color: medals[entry.key],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddGLMDialog() {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final hospitalC = TextEditingController();
    final idC = TextEditingController();
    final passC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AdminTheme.bgCard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminTheme.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AdminTheme.accent, size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text('Add New GLM', style: AdminTheme.heading2),
                  const SizedBox(height: 20),
                  _glmField(nameC, 'Full Name', Icons.person_rounded),
                  const SizedBox(height: 12),
                  _glmField(phoneC, 'Phone Number', Icons.phone_rounded),
                  const SizedBox(height: 12),
                  _glmField(hospitalC, 'Hospital Name', Icons.local_hospital_rounded),
                  const SizedBox(height: 12),
                  _glmField(idC, 'GLM Login ID', Icons.badge_rounded),
                  const SizedBox(height: 12),
                  _glmField(passC, 'GLM Password', Icons.lock_outline_rounded),
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
                            if (formKey.currentState!.validate()) {
                              try {
                                await _ctrl.createGLMAccount(
                                  name: nameC.text.trim(),
                                  phone: phoneC.text.trim(),
                                  hospital: hospitalC.text.trim(),
                                  glmId: idC.text.trim(),
                                  password: passC.text.trim(),
                                );
                                Get.back();
                                // Delay snackbar to let overlay rebuild after dialog close
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  Get.snackbar(
                                    'Success',
                                    'GLM account created!',
                                    backgroundColor: AdminTheme.green,
                                    colorText: Colors.white,
                                    snackStyle: SnackStyle.FLOATING,
                                    margin: const EdgeInsets.all(16),
                                    borderRadius: 12,
                                  );
                                });
                              } catch (e) {
                                Get.back();
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  Get.snackbar(
                                    'Error',
                                    '$e',
                                    backgroundColor: AdminTheme.red,
                                  colorText: Colors.white,
                                  snackStyle: SnackStyle.FLOATING,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 12,
                                );
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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AdminTheme.purple.withOpacity(0.2), AdminTheme.purple.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(initial, style: AdminTheme.heading2.copyWith(color: AdminTheme.purple)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.data['name'] ?? 'GLM', style: AdminTheme.heading2),
                            const SizedBox(height: 3),
                            Text(widget.data['hospital'] ?? 'N/A', style: AdminTheme.bodySmall),
                          ],
                        ),
                      ),
                      AdminMiniTag(text: 'Score: ${widget.data['score'] ?? 0}', color: AdminTheme.amber),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AdminDetailRow(label: 'Phone', value: widget.data['phone'] ?? 'N/A'),
                  AdminDetailRow(label: 'GLM ID', value: widget.data['glmId'] ?? widget.glmId),
                  AdminDetailRow(label: 'Total Income', value: '৳${widget.data['totalIncome'] ?? 0}'),
                  AdminDetailRow(label: 'Trips Ordered', value: '${widget.data['totalTripsOrdered'] ?? 0}'),
                ],
              ),
            ),
            const SizedBox(height: 22),

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

            StreamBuilder<QuerySnapshot>(
              stream: _buildTripQuery(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
                // Filter by date and sort locally to avoid composite index
                DateTime now = DateTime.now();
                DateTime start;
                switch (_filter) {
                  case 'day': start = DateTime(now.year, now.month, now.day); break;
                  case 'week': start = now.subtract(const Duration(days: 7)); break;
                  default: start = DateTime(now.year, now.month, 1);
                }
                var trips = snapshot.data!.docs.where((doc) {
                  var d = doc.data() as Map<String, dynamic>;
                  if (d['timestamp'] == null) return false;
                  return (d['timestamp'] as Timestamp).toDate().isAfter(start);
                }).toList();
                trips.sort((a, b) {
                  try {
                    final aT = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    final bT = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
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
                    var t = trips[index].data() as Map<String, dynamic>;
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
                                value: DateFormat('dd MMM yyyy, hh:mm a').format((t['timestamp'] as Timestamp).toDate()),
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

  Stream<QuerySnapshot> _buildTripQuery() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('glmId', isEqualTo: widget.glmId)
        .snapshots();
  }
}
