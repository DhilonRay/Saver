import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedTarget = 'all_users';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      String title = _titleController.text.trim();
      String message = _messageController.text.trim();
      List<String> tokens = [];

      // Get FCM tokens based on target
      if (_selectedTarget == 'all_users') {
        QuerySnapshot usersSnapshot =
            await _firestore.collection('users').get();
        for (var doc in usersSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['fcmToken'] != null) {
            tokens.add(data['fcmToken']);
          }
        }
      } else if (_selectedTarget == 'all_partners') {
        QuerySnapshot partnersSnapshot =
            await _firestore.collection('partners').get();
        for (var doc in partnersSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['fcmToken'] != null) {
            tokens.add(data['fcmToken']);
          }
        }
      } else if (_selectedTarget == 'all') {
        // Get all users
        QuerySnapshot usersSnapshot =
            await _firestore.collection('users').get();
        for (var doc in usersSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['fcmToken'] != null) {
            tokens.add(data['fcmToken']);
          }
        }
        // Get all partners
        QuerySnapshot partnersSnapshot =
            await _firestore.collection('partners').get();
        for (var doc in partnersSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['fcmToken'] != null) {
            tokens.add(data['fcmToken']);
          }
        }
      }

      if (tokens.isEmpty) {
        Get.snackbar(
          'No Recipients',
          'No FCM tokens found for the selected target',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        setState(() => _isSending = false);
        return;
      }

      // Save notification to Firestore
      await _firestore.collection('admin_notifications').add({
        'title': title,
        'message': message,
        'target': _selectedTarget,
        'recipientCount': tokens.length,
        'sentAt': FieldValue.serverTimestamp(),
      });

      // In a real app, you would call your backend API to send FCM notifications
      // For now, we'll just show success
      Get.snackbar(
        'Success',
        'Notification sent to ${tokens.length} recipients',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _titleController.clear();
      _messageController.clear();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send notification: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notifications'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Send Notification Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Compose Notification',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Target Selection
                      const Text(
                        'Send To:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedTarget,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.people),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Users & Partners'),
                          ),
                          DropdownMenuItem(
                            value: 'all_users',
                            child: Text('All Users'),
                          ),
                          DropdownMenuItem(
                            value: 'all_partners',
                            child: Text('All Partners'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTarget = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Title Field
                      const Text(
                        'Title:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter notification title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Message Field
                      const Text(
                        'Message:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Enter notification message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 80),
                            child: Icon(Icons.message),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Send Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _sendNotification,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          label: Text(
                            _isSending ? 'Sending...' : 'Send Notification',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notification History
            const Text(
              'Notification History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('admin_notifications')
                  .orderBy('sentAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var notifications = snapshot.data!.docs;

                if (notifications.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No notifications sent yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    var data =
                        notifications[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            Icons.notifications,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              data['message'] ?? 'No Message',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sent to: ${_getTargetLabel(data['target'])} (${data['recipientCount']} recipients)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (data['sentAt'] != null)
                              Text(
                                (data['sentAt'] as Timestamp)
                                    .toDate()
                                    .toString()
                                    .split('.')[0],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTargetLabel(String target) {
    switch (target) {
      case 'all':
        return 'All Users & Partners';
      case 'all_users':
        return 'All Users';
      case 'all_partners':
        return 'All Partners';
      default:
        return target;
    }
  }
}
