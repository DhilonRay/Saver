
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../admin_theme.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);
  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final SupabaseClient _fs = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _selectedTarget = 'all_users';
  bool _isSending = false;

  @override
  void dispose() { _titleCtrl.dispose(); _msgCtrl.dispose(); super.dispose(); }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      String title = _titleCtrl.text.trim();
      String message = _msgCtrl.text.trim();
      List<String> tokens = [];
      if (_selectedTarget == 'all_users' || _selectedTarget == 'all') {
        var snap = await Supabase.instance.client.from('users').select();
        for (var doc in snap) { var d = doc; if (d['fcmToken'] != null) tokens.add(d['fcmToken']); }
      }
      if (_selectedTarget == 'all_partners' || _selectedTarget == 'all') {
        var snap = await Supabase.instance.client.from('partners').select();
        for (var doc in snap) { var d = doc; if (d['fcmToken'] != null) tokens.add(d['fcmToken']); }
      }
      if (tokens.isEmpty) {
        Get.snackbar('No Recipients', 'No FCM tokens found for the selected target', backgroundColor: AdminTheme.orange, colorText: Colors.white, snackStyle: SnackStyle.FLOATING, margin: const EdgeInsets.all(16), borderRadius: 12);
        setState(() => _isSending = false); return;
      }
      await _fs.from('admin_notifications').insert({'title': title, 'message': message, 'target': _selectedTarget, 'recipientCount': tokens.length, 'sentAt': DateTime.now().toIso8601String()});
      Get.snackbar('Success', 'Notification sent to ${tokens.length} recipients', backgroundColor: AdminTheme.green, colorText: Colors.white, snackStyle: SnackStyle.FLOATING, margin: const EdgeInsets.all(16), borderRadius: 12);
      _titleCtrl.clear(); _msgCtrl.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to send notification: $e', backgroundColor: AdminTheme.red, colorText: Colors.white, snackStyle: SnackStyle.FLOATING, margin: const EdgeInsets.all(16), borderRadius: 12);
    } finally { setState(() => _isSending = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: const AdminAppBar(title: 'Send Notifications'),
      body: Container(
        decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Compose Card
            GlassCard(
              accentColor: AdminTheme.accent,
              child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit_notifications_rounded, color: AdminTheme.accent, size: 22)),
                  const SizedBox(width: 12), const Text('Compose Notification', style: AdminTheme.heading2),
                ]),
                const SizedBox(height: 20),
                Text('SEND TO', style: AdminTheme.caption.copyWith(letterSpacing: 1.2, color: AdminTheme.textSecondary)), const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTarget, dropdownColor: AdminTheme.bgCard,
                  style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary),
                  decoration: _inputDecor('Select target', Icons.people_rounded),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users & Partners')),
                    DropdownMenuItem(value: 'all_users', child: Text('All Users')),
                    DropdownMenuItem(value: 'all_partners', child: Text('All Partners')),
                  ],
                  onChanged: (v) => setState(() => _selectedTarget = v!),
                ),
                const SizedBox(height: 16),
                Text('TITLE', style: AdminTheme.caption.copyWith(letterSpacing: 1.2, color: AdminTheme.textSecondary)), const SizedBox(height: 8),
                TextFormField(controller: _titleCtrl, style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary), decoration: _inputDecor('Enter notification title', Icons.title_rounded),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter a title' : null),
                const SizedBox(height: 16),
                Text('MESSAGE', style: AdminTheme.caption.copyWith(letterSpacing: 1.2, color: AdminTheme.textSecondary)), const SizedBox(height: 8),
                TextFormField(controller: _msgCtrl, maxLines: 5, style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary),
                  decoration: _inputDecor('Enter notification message', Icons.message_rounded).copyWith(
                    prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 80), child: Icon(Icons.message_rounded, color: AdminTheme.accent.withOpacity(0.5), size: 18)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter a message' : null),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, height: 52, child: DecoratedBox(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [AdminTheme.accent, AdminTheme.accentGlow]), boxShadow: [BoxShadow(color: AdminTheme.accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendNotification,
                    icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AdminTheme.bgDeep, strokeWidth: 2)) : Icon(Icons.send_rounded, color: AdminTheme.bgDeep, size: 20),
                    label: Text(_isSending ? 'Sending...' : 'Send Notification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AdminTheme.bgDeep)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                )),
              ])),
            ),
            const SizedBox(height: 24),

            // History
            const AdminSectionHeader(title: 'Notification History', icon: Icons.history_rounded),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fs.from('admin_notifications').stream(primaryKey: ['id']).order('sentAt', ascending: false).limit(20),
              builder: (ctx, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: AdminTheme.body));
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
                var notifs = snap.data!;
                if (notifs.isEmpty) return GlassCard(child: Center(child: Text('No notifications sent yet', style: AdminTheme.body.copyWith(color: AdminTheme.textMuted))));
                return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: notifs.length, itemBuilder: (ctx, i) {
                  var d = notifs[i];
                  return Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AdminTheme.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.notifications_rounded, color: AdminTheme.blue, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d['title'] ?? 'No Title', style: AdminTheme.heading3.copyWith(fontSize: 13)),
                        const SizedBox(height: 3), Text(d['message'] ?? 'No Message', maxLines: 2, overflow: TextOverflow.ellipsis, style: AdminTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('To: ${_getTargetLabel(d['target'])} (${d['recipientCount']} recipients)', style: AdminTheme.caption),
                        if (d['sentAt'] != null) Text(DateTime.parse(d['sentAt'].toString()).toString().split('.')[0], style: AdminTheme.caption),
                      ])),
                    ]),
                  ));
                });
              },
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) => InputDecoration(
    hintText: hint, hintStyle: AdminTheme.body.copyWith(color: AdminTheme.textMuted.withOpacity(0.5)),
    prefixIcon: Icon(icon, color: AdminTheme.accent.withOpacity(0.5), size: 18),
    filled: true, fillColor: AdminTheme.bgDeep.withOpacity(0.5),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AdminTheme.accent, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AdminTheme.red, width: 1)),
    errorStyle: const TextStyle(color: AdminTheme.red, fontSize: 11),
    contentPadding: const EdgeInsets.symmetric(vertical: 14),
  );

  String _getTargetLabel(String target) {
    switch (target) { case 'all': return 'All Users & Partners'; case 'all_users': return 'All Users'; case 'all_partners': return 'All Partners'; default: return target; }
  }
}
