import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../admin_theme.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
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
              stream: Supabase.instance.client.from('users').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: AdminTheme.body));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
                }

                var users = snapshot.data!.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  var data = doc;
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
                    var data = users[index];
                    var uid = users[index]['id'] as String? ?? '';
                    final nameStr = (data['name'] ?? '').toString().trim();
                    final initial = nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'U';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: () => _showUserDetails(uid, data),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AdminTheme.accent.withOpacity(0.15),
                                    AdminTheme.accent.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: AdminTheme.heading2.copyWith(color: AdminTheme.accent),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Unknown User',
                                    style: AdminTheme.heading3.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_rounded, size: 13, color: AdminTheme.textMuted.withOpacity(0.6)),
                                      const SizedBox(width: 5),
                                      Text(data['phone'] ?? 'N/A', style: AdminTheme.bodySmall),
                                    ],
                                  ),
                                  if (data['address'] != null) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, size: 13, color: AdminTheme.textMuted.withOpacity(0.6)),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            data['address'] ?? '',
                                            style: AdminTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildUsersBanner() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('users').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        int totalUsers = snapshot.hasData ? snapshot.data!.length : 0;

        int periodUsers = totalUsers;
        if (snapshot.hasData) {
          DateTime now = DateTime.now();
          DateTime start;
          switch (_selectedPeriod) {
            case 'day':
              start = DateTime(now.year, now.month, now.day);
              break;
            case 'week':
              start = now.subtract(const Duration(days: 7));
              break;
            case 'month':
              start = DateTime(now.year, now.month, 1);
              break;
            case 'year':
              start = DateTime(now.year, 1, 1);
              break;
            default:
              start = DateTime(now.year, now.month, 1);
          }

          periodUsers = snapshot.data!.where((doc) {
            var data = doc;
            if (data['createdAt'] == null) return false;
            DateTime created = DateTime.parse(data['createdAt'].toString());
            return created.isAfter(start);
          }).length;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: GlassCard(
            accentColor: AdminTheme.blue,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminTheme.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AdminTheme.blue.withOpacity(0.1),
                            blurRadius: 12,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.people_rounded, color: AdminTheme.blue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Users', style: AdminTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text(
                          '$totalUsers',
                          style: AdminTheme.stat.copyWith(color: AdminTheme.textPrimary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'New (${_selectedPeriod.capitalize})',
                          style: AdminTheme.caption,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+$periodUsers',
                          style: AdminTheme.heading2.copyWith(color: AdminTheme.green),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    AdminFilterChip(label: 'Day', selected: _selectedPeriod == 'day', onTap: () => setState(() => _selectedPeriod = 'day')),
                    const SizedBox(width: 8),
                    AdminFilterChip(label: 'Week', selected: _selectedPeriod == 'week', onTap: () => setState(() => _selectedPeriod = 'week')),
                    const SizedBox(width: 8),
                    AdminFilterChip(label: 'Month', selected: _selectedPeriod == 'month', onTap: () => setState(() => _selectedPeriod = 'month')),
                    const SizedBox(width: 8),
                    AdminFilterChip(label: 'Year', selected: _selectedPeriod == 'year', onTap: () => setState(() => _selectedPeriod = 'year')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUserDetails(String uid, Map<String, dynamic> data) {
    final nameStr = (data['name'] ?? '').toString().trim();
    final initial = nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'U';

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: AdminTheme.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // User info
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AdminTheme.accent.withOpacity(0.2), AdminTheme.accent.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: AdminTheme.heading1.copyWith(color: AdminTheme.accent, fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? 'Unknown', style: AdminTheme.heading2),
                          const SizedBox(height: 4),
                          Text(data['phone'] ?? 'N/A', style: AdminTheme.body),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                      DateTime.parse(data['createdAt'].toString()),
                    ),
                  ),
                const SizedBox(height: 20),

                // Last trip info
                const AdminSectionHeader(
                  title: 'Last Trip',
                  icon: Icons.route_rounded,
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('orders')
                      .stream(primaryKey: ['id'])
                      .eq('userId', uid),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.isEmpty) {
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
                    var docs = List<Map<String, dynamic>>.from(snap.data!);
                    docs.sort((a, b) {
                      try {
                        final aT = (a)['timestamp'] as String?;
                        final bT = (b)['timestamp'] as String?;
                        if (aT == null) return 1;
                        if (bT == null) return -1;
                        return bT.compareTo(aT);
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
                                  .format(DateTime.parse(trip['timestamp'].toString())),
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
    );
  }
}
