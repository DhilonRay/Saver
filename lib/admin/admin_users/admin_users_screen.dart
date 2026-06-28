import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin_theme.dart';
import '../../services/supabase_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: const AdminAppBar(title: 'User Management'),
      body: Container(
        decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AdminSearchBar(
                controller: _searchController,
                hintText: 'Search users by name or email...',
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                onClear: () { _searchController.clear(); setState(() => _searchQuery = ''); },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.client.from('users').stream(primaryKey: ['id']),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: AdminTheme.body));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
                  
                  final rawUsers = snapshot.data ?? [];
                  var users = rawUsers.where((item) {
                    var d = SupabaseService.toCamelCase(item);
                    return (d['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                        (d['email'] ?? '').toString().toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (users.isEmpty) return _emptyState(Icons.person_off_rounded, 'No users found');
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      var ud = SupabaseService.toCamelCase(users[i]);
                      var uid = ud['id'] ?? ud['uid'] ?? '';
                      bool isActive = ud['isActive'] ?? true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [AdminTheme.blue.withOpacity(0.15), AdminTheme.blue.withOpacity(0.05)]), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.person_rounded, color: AdminTheme.blue, size: 22)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(ud['name'] ?? 'No Name', style: AdminTheme.heading3.copyWith(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(ud['email'] ?? 'No Email', style: AdminTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text('Phone: ${ud['phone'] ?? 'N/A'}', style: AdminTheme.bodySmall),
                              const SizedBox(height: 6),
                              AdminStatusBadge(label: isActive ? 'Active' : 'Suspended', color: isActive ? AdminTheme.green : AdminTheme.red),
                            ])),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert_rounded, color: AdminTheme.textMuted, size: 20),
                              color: AdminTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              itemBuilder: (_) => [
                                _mi('view', Icons.visibility_rounded, 'View Details', AdminTheme.accent),
                                _mi('suspend', isActive ? Icons.block_rounded : Icons.check_circle_rounded, isActive ? 'Suspend' : 'Activate', AdminTheme.orange),
                                _mi('delete', Icons.delete_rounded, 'Delete', AdminTheme.red),
                              ],
                              onSelected: (v) { if (v == 'view') _viewUser(uid, ud); else if (v == 'suspend') _toggleStatus(uid, ud); else if (v == 'delete') _deleteUser(uid, ud); },
                            ),
                          ]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem _mi(String v, IconData ic, String t, Color c) => PopupMenuItem(value: v, child: Row(children: [Icon(ic, size: 18, color: c), const SizedBox(width: 10), Text(t, style: TextStyle(color: c, fontSize: 13))]));

  Widget _emptyState(IconData ic, String t) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AdminTheme.bgSurface.withOpacity(0.5), shape: BoxShape.circle), child: Icon(ic, size: 40, color: AdminTheme.textMuted)),
    const SizedBox(height: 14), Text(t, style: AdminTheme.body),
  ]));

  void _viewUser(String uid, Map<String, dynamic> ud) {
    Get.dialog(BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), backgroundColor: AdminTheme.bgCard,
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_rounded, color: AdminTheme.blue, size: 22)), const SizedBox(width: 12), const Text('User Details', style: AdminTheme.heading2)]),
        const SizedBox(height: 16), Divider(color: Colors.white.withOpacity(0.04)), const SizedBox(height: 12),
        AdminDetailRow(label: 'Name', value: ud['name'] ?? 'N/A'), AdminDetailRow(label: 'Email', value: ud['email'] ?? 'N/A'), AdminDetailRow(label: 'Phone', value: ud['phone'] ?? 'N/A'),
        AdminDetailRow(label: 'User ID', value: uid), AdminDetailRow(label: 'Status', value: (ud['isActive'] ?? true) ? 'Active' : 'Suspended'),
        AdminDetailRow(label: 'Joined', value: ud['createdAt'] != null ? DateTime.tryParse(ud['createdAt'].toString())?.toString().split('.')[0] ?? 'N/A' : 'N/A'),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: TextButton(onPressed: () => Get.back(), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withOpacity(0.08)))),
          child: const Text('Close', style: TextStyle(color: AdminTheme.textSecondary)))),
      ])))));
  }

  Future<void> _toggleStatus(String uid, Map<String, dynamic> ud) async {
    bool ns = !(ud['isActive'] ?? true);
    _confirmDialog(ns ? 'Activate User?' : 'Suspend User?', ns ? 'User will be able to use the app.' : 'User will not be able to access the app.', ns ? AdminTheme.green : AdminTheme.orange, ns ? 'Activate' : 'Suspend', () async {
      await SupabaseService.client.from('users').update({'is_active': ns}).eq('id', uid);
      Get.back(); Get.snackbar('Success', 'User ${ns ? 'activated' : 'suspended'}', backgroundColor: AdminTheme.green, colorText: Colors.white, snackStyle: SnackStyle.FLOATING, margin: const EdgeInsets.all(16), borderRadius: 12);
    });
  }

  Future<void> _deleteUser(String uid, Map<String, dynamic> ud) async {
    _confirmDialog('Delete User?', 'Permanently delete ${ud['name']}? This cannot be undone.', AdminTheme.red, 'Delete', () async {
      await SupabaseService.client.from('users').delete().eq('id', uid);
      Get.back(); Get.snackbar('Success', 'User deleted', backgroundColor: AdminTheme.green, colorText: Colors.white, snackStyle: SnackStyle.FLOATING, margin: const EdgeInsets.all(16), borderRadius: 12);
    });
  }

  void _confirmDialog(String title, String msg, Color color, String action, VoidCallback onConfirm) {
    Get.dialog(BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), backgroundColor: AdminTheme.bgCard,
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.warning_rounded, color: color, size: 28)),
        const SizedBox(height: 16), Text(title, style: AdminTheme.heading2), const SizedBox(height: 8),
        Text(msg, style: AdminTheme.body.copyWith(color: AdminTheme.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => Get.back(), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withOpacity(0.08)))), child: const Text('Cancel', style: TextStyle(color: AdminTheme.textSecondary)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: onConfirm, style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: Text(action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
        ]),
      ])))));
  }
}
