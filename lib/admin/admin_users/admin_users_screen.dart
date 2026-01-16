import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var name = (data['name'] ?? '').toString().toLowerCase();
                  var email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var userData = users[index].data() as Map<String, dynamic>;
                    var userId = users[index].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            Icons.person,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        title: Text(
                          userData['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(userData['email'] ?? 'No Email'),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${userData['phone'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (userData['isActive'] ?? true)
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (userData['isActive'] ?? true)
                                    ? 'Active'
                                    : 'Suspended',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (userData['isActive'] ?? true)
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, size: 20),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'suspend',
                              child: Row(
                                children: [
                                  Icon(
                                    (userData['isActive'] ?? true)
                                        ? Icons.block
                                        : Icons.check_circle,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text((userData['isActive'] ?? true)
                                      ? 'Suspend User'
                                      : 'Activate User'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete User',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'view':
                                _viewUserDetails(userId, userData);
                                break;
                              case 'suspend':
                                _toggleUserStatus(userId, userData);
                                break;
                              case 'delete':
                                _deleteUser(userId, userData);
                                break;
                            }
                          },
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

  void _viewUserDetails(String userId, Map<String, dynamic> userData) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.blue.shade900, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'User Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Name', userData['name'] ?? 'N/A'),
              _buildDetailRow('Email', userData['email'] ?? 'N/A'),
              _buildDetailRow('Phone', userData['phone'] ?? 'N/A'),
              _buildDetailRow('User ID', userId),
              _buildDetailRow(
                'Status',
                (userData['isActive'] ?? true) ? 'Active' : 'Suspended',
              ),
              _buildDetailRow(
                'Joined',
                userData['createdAt'] != null
                    ? (userData['createdAt'] as Timestamp)
                        .toDate()
                        .toString()
                        .split('.')[0]
                    : 'N/A',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                  ),
                  child: const Text('Close',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(
      String userId, Map<String, dynamic> userData) async {
    bool currentStatus = userData['isActive'] ?? true;
    bool newStatus = !currentStatus;

    Get.dialog(
      AlertDialog(
        title: Text(newStatus ? 'Activate User?' : 'Suspend User?'),
        content: Text(
          newStatus
              ? 'This user will be able to use the app.'
              : 'This user will not be able to access the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('users').doc(userId).update({
                  'isActive': newStatus,
                });
                Get.back();
                Get.snackbar(
                  'Success',
                  'User ${newStatus ? 'activated' : 'suspended'} successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to update user status',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
            child: Text(newStatus ? 'Activate' : 'Suspend',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId, Map<String, dynamic> userData) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete User?'),
        content: Text(
          'Are you sure you want to permanently delete ${userData['name']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('users').doc(userId).delete();
                Get.back();
                Get.snackbar(
                  'Success',
                  'User deleted successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to delete user',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
