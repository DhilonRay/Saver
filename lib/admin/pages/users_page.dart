import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../admin_theme.dart';
import '../../services/supabase_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedPeriod = 'month';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
      child: Column(
        children: [
          // Total users banner + filter
          _buildUsersBanner(),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: AdminSearchBar(
              controller: _searchCtrl,
              hintText: 'Search by phone or name...',
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),

          // Users list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService.client.from('users').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: AdminTheme.body));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
                }

                final rawUsers = snapshot.data ?? [];
                var users = rawUsers.where((item) {
                  var data = SupabaseService.toCamelCase(item);
                  if (_searchQuery.isEmpty) return true;
                  String phone = (data['phone'] ?? '').toString();
                  String name = (data['name'] ?? '').toString().toLowerCase();
                  return phone.contains(_searchQuery) ||
                      name.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AdminTheme.bgSurface.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_off_rounded, size: 40, color: AdminTheme.textMuted),
                        ),
                        const SizedBox(height: 14),
                        const Text('No users found', style: AdminTheme.body),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var data = SupabaseService.toCamelCase(users[index]);
                    var uid = data['id'] ?? data['uid'] ?? '';
                    final nameStr = (data['name'] ?? '').toString().trim();
                    final initial = nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'U';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: () => _viewUserDetails(uid, data),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AdminTheme.accent.withOpacity(0.1),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AdminTheme.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'N/A',
                                    style: AdminTheme.heading3.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(data['phone'] ?? 'N/A', style: AdminTheme.bodySmall),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AdminTheme.textMuted,
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

  Widget _buildUsersBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registered Users', style: AdminTheme.heading2),
              const SizedBox(height: 4),
              Text(
                'Total user analytics dashboard',
                style: AdminTheme.bodySmall.copyWith(color: AdminTheme.textSecondary),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AdminTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up_rounded, color: AdminTheme.accent, size: 16),
                SizedBox(width: 4),
                Text('Active', style: TextStyle(color: AdminTheme.accent, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewUserDetails(String uid, Map<String, dynamic> data) {
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AdminTheme.bgCard,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                        child: const Icon(Icons.person_rounded, color: AdminTheme.accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text('User Details', style: AdminTheme.heading2),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.04)),
                  const SizedBox(height: 12),

                  AdminDetailRow(label: 'Name', value: data['name'] ?? 'N/A'),
                  AdminDetailRow(label: 'Phone', value: data['phone'] ?? 'N/A'),
                  AdminDetailRow(label: 'Address', value: data['address'] ?? 'N/A'),
                  AdminDetailRow(label: 'Email', value: data['email'] ?? 'N/A'),
                  if (data['createdAt'] != null)
                    AdminDetailRow(
                      label: 'Joined',
                      value: DateFormat('dd MMM yyyy').format(
                        DateTime.tryParse(data['createdAt'].toString())!,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Last trip info
                  const AdminSectionHeader(
                    title: 'Last Trip',
                    icon: Icons.route_rounded,
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: SupabaseService.client
                        .from('orders')
                        .stream(primaryKey: ['id'])
                        .eq('user_id', uid),
                    builder: (context, snap) {
                      final rawDocs = snap.data ?? [];
                      if (!snap.hasData || rawDocs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AdminTheme.bgSurface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('No trips found', style: AdminTheme.body),
                          ),
                        );
                      }
                      
                      // Sort locally to find most recent trip (avoids composite index)
                      var docs = rawDocs.map((item) => SupabaseService.toCamelCase(item)).toList();
                      docs.sort((a, b) {
                        try {
                          final aT = a['timestamp'] ?? a['createdAt'];
                          final bT = b['timestamp'] ?? b['createdAt'];
                          if (aT == null) return 1;
                          if (bT == null) return -1;
                          final dateA = DateTime.tryParse(aT.toString());
                          final dateB = DateTime.tryParse(bT.toString());
                          if (dateA == null) return 1;
                          if (dateB == null) return -1;
                          return dateB.compareTo(dateA);
                        } catch (_) { return 0; }
                      });
                      var trip = docs.first;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AdminTheme.bgSurface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdminDetailRow(label: 'From', value: trip['pickupAddress'] ?? 'N/A'),
                            AdminDetailRow(label: 'To', value: trip['destinationAddress'] ?? 'N/A'),
                            AdminDetailRow(label: 'Ambulance', value: trip['ambulanceName'] ?? trip['driverName'] ?? trip['companyName'] ?? 'N/A'),
                            AdminDetailRow(label: 'Fare', value: '৳${trip['fareAmount'] ?? trip['finalFare'] ?? trip['confirmedFare'] ?? trip['fare'] ?? 'N/A'}'),
                            if (trip['timestamp'] != null)
                              AdminDetailRow(
                                label: 'Date',
                                value: DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(DateTime.tryParse(trip['timestamp'].toString())!),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
