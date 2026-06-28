import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin_theme.dart';
import '../../services/supabase_service.dart';

class AdminPartnersScreen extends StatefulWidget {
  const AdminPartnersScreen({Key? key}) : super(key: key);
  @override
  State<AdminPartnersScreen> createState() => _AdminPartnersScreenState();
}

class _AdminPartnersScreenState extends State<AdminPartnersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _sq = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: const AdminAppBar(title: 'Partner Management'),
      body: Container(
        decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: AdminSearchBar(controller: _searchCtrl, hintText: 'Search partners by name or phone...', onChanged: (v) => setState(() => _sq = v.toLowerCase()), onClear: () { _searchCtrl.clear(); setState(() => _sq = ''); })),
          Expanded(child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.client.from('partners').stream(primaryKey: ['id']),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: AdminTheme.body));
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
              
              final rawPartners = snap.data ?? [];
              var partners = rawPartners.where((item) {
                var data = SupabaseService.toCamelCase(item);
                return (data['name'] ?? '').toString().toLowerCase().contains(_sq) || (data['phone'] ?? '').toString().contains(_sq);
              }).toList();

              if (partners.isEmpty) return _empty('No partners found');
              return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: partners.length, itemBuilder: (ctx, i) {
                var pd = SupabaseService.toCamelCase(partners[i]);
                var pid = pd['id'] ?? pd['uid'] ?? '';
                bool approved = pd['isApproved'] ?? false;
                bool active = pd['isActive'] ?? true;
                return Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(padding: const EdgeInsets.all(14), child: Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [AdminTheme.green.withOpacity(0.15), AdminTheme.green.withOpacity(0.05)]), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.delivery_dining_rounded, color: AdminTheme.green, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pd['name'] ?? 'No Name', style: AdminTheme.heading3.copyWith(fontSize: 14)),
                    const SizedBox(height: 4), Text('Phone: ${pd['phone'] ?? 'N/A'}', style: AdminTheme.bodySmall),
                    const SizedBox(height: 4), Text('Vehicle: ${pd['vehicleType'] ?? 'N/A'}', style: AdminTheme.bodySmall),
                    const SizedBox(height: 6),
                    Row(children: [
                      AdminStatusBadge(label: approved ? 'Approved' : 'Pending', color: approved ? AdminTheme.green : AdminTheme.orange),
                      const SizedBox(width: 6),
                      AdminStatusBadge(label: active ? 'Active' : 'Suspended', color: active ? AdminTheme.blue : AdminTheme.red),
                    ]),
                  ])),
                  PopupMenuButton(icon: const Icon(Icons.more_vert_rounded, color: AdminTheme.textMuted, size: 20), color: AdminTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    itemBuilder: (_) => [
                      _mi('view', Icons.visibility_rounded, 'View Details', AdminTheme.accent),
                      if (!approved) _mi('approve', Icons.check_circle_rounded, 'Approve', AdminTheme.green),
                      _mi('suspend', active ? Icons.block_rounded : Icons.check_circle_rounded, active ? 'Suspend' : 'Activate', AdminTheme.orange),
                      _mi('delete', Icons.delete_rounded, 'Delete', AdminTheme.red),
                    ],
                    onSelected: (v) { if (v == 'view') _viewPartner(pid, pd); else if (v == 'approve') _approve(pid, pd); else if (v == 'suspend') _toggle(pid, pd); else if (v == 'delete') _delete(pid, pd); },
                  ),
                ])));
              });
            },
          )),
        ]),
      ),
    );
  }

  PopupMenuItem _mi(String v, IconData ic, String t, Color c) => PopupMenuItem(value: v, child: Row(children: [Icon(ic, size: 18, color: c), const SizedBox(width: 10), Text(t, style: TextStyle(color: c, fontSize: 13))]));
  Widget _empty(String t) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AdminTheme.bgSurface.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.delivery_dining_rounded, size: 40, color: AdminTheme.textMuted)), const SizedBox(height: 14), Text(t, style: AdminTheme.body)]));

  void _viewPartner(String pid, Map<String, dynamic> pd) {
    Get.dialog(BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), backgroundColor: AdminTheme.bgCard,
      child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delivery_dining_rounded, color: AdminTheme.green, size: 22)), const SizedBox(width: 12), const Text('Partner Details', style: AdminTheme.heading2)]),
        const SizedBox(height: 16), Divider(color: Colors.white.withOpacity(0.04)), const SizedBox(height: 12),
        AdminDetailRow(label: 'Name', value: pd['name'] ?? 'N/A'), AdminDetailRow(label: 'Phone', value: pd['phone'] ?? 'N/A'), AdminDetailRow(label: 'Email', value: pd['email'] ?? 'N/A'),
        AdminDetailRow(label: 'Vehicle Type', value: pd['vehicleType'] ?? 'N/A'), AdminDetailRow(label: 'Vehicle No.', value: pd['vehicleNumber'] ?? 'N/A'),
        AdminDetailRow(label: 'Partner ID', value: pid), AdminDetailRow(label: 'Approval', value: (pd['isApproved'] ?? false) ? 'Approved' : 'Pending'),
        AdminDetailRow(label: 'Status', value: (pd['isActive'] ?? true) ? 'Active' : 'Suspended'),
        AdminDetailRow(label: 'Orders', value: '${pd['completedOrders'] ?? 0}'), AdminDetailRow(label: 'Earnings', value: '৳${pd['totalEarnings'] ?? 0}'),
        AdminDetailRow(label: 'Joined', value: pd['createdAt'] != null ? DateTime.tryParse(pd['createdAt'].toString())?.toString().split('.')[0] ?? 'N/A' : 'N/A'),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: TextButton(onPressed: () => Get.back(), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withOpacity(0.08)))), child: const Text('Close', style: TextStyle(color: AdminTheme.textSecondary)))),
      ]))))));
  }

  void _confirm(String title, String msg, Color c, String act, Future<void> Function() fn) {
    Get.dialog(BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), backgroundColor: AdminTheme.bgCard,
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.warning_rounded, color: c, size: 28)),
        const SizedBox(height: 16), Text(title, style: AdminTheme.heading2), const SizedBox(height: 8),
        Text(msg, style: AdminTheme.body.copyWith(color: AdminTheme.textSecondary), textAlign: TextAlign.center), const SizedBox(height: 24),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => Get.back(), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withOpacity(0.08)))), child: const Text('Cancel', style: TextStyle(color: AdminTheme.textSecondary)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async { try { await fn(); } catch (e) { Get.snackbar('Error', '$e', backgroundColor: AdminTheme.red, colorText: Colors.white); } }, style: ElevatedButton.styleFrom(backgroundColor: c, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0), child: Text(act, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
        ]),
      ])))));
  }

  void _approve(String pid, Map<String, dynamic> pd) => _confirm('Approve Partner?', 'Approve ${pd['name']} as a delivery partner?', AdminTheme.green, 'Approve', () async {
    await SupabaseService.client.from('partners').update({'is_approved': true}).eq('id', pid); Get.back(); Get.snackbar('Success', 'Partner approved', backgroundColor: AdminTheme.green, colorText: Colors.white, snackStyle: SnackStyle.FLOATING, margin: const EdgeInsets.all(16), borderRadius: 12);
  });

  void _toggle(String pid, Map<String, dynamic> pd) { bool ns = !(pd['isActive'] ?? true); _confirm(ns ? 'Activate?' : 'Suspend?', ns ? 'Partner can accept orders.' : 'Partner cannot accept orders.', ns ? AdminTheme.green : AdminTheme.orange, ns ? 'Activate' : 'Suspend', () async {
    await SupabaseService.client.from('partners').update({'is_active': ns}).eq('id', pid); Get.back(); Get.snackbar('Success', 'Partner ${ns ? 'activated' : 'suspended'}', backgroundColor: AdminTheme.green, colorText: Colors.white, snackStyle: SnackStyle.FLOATING, margin: const EdgeInsets.all(16), borderRadius: 12);
  }); }

  void _delete(String pid, Map<String, dynamic> pd) => _confirm('Delete Partner?', 'Permanently delete ${pd['name']}?', AdminTheme.red, 'Delete', () async {
    await SupabaseService.client.from('partners').delete().eq('id', pid); Get.back(); Get.snackbar('Success', 'Partner deleted', backgroundColor: AdminTheme.green, colorText: Colors.white, snackStyle: SnackStyle.FLOATING, margin: const EdgeInsets.all(16), borderRadius: 12);
  });
}
