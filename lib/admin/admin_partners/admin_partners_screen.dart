import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminPartnersScreen extends StatefulWidget {
  const AdminPartnersScreen({Key? key}) : super(key: key);

  @override
  State<AdminPartnersScreen> createState() => _AdminPartnersScreenState();
}

class _AdminPartnersScreenState extends State<AdminPartnersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Management'),
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
                hintText: 'Search partners by name or phone...',
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

          // Partners List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('partners').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var partners = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var name = (data['name'] ?? '').toString().toLowerCase();
                  var phone = (data['phone'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      phone.contains(_searchQuery);
                }).toList();

                if (partners.isEmpty) {
                  return const Center(child: Text('No partners found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    var partnerData =
                        partners[index].data() as Map<String, dynamic>;
                    var partnerId = partners[index].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            Icons.delivery_dining,
                            color: Colors.green.shade900,
                          ),
                        ),
                        title: Text(
                          partnerData['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Phone: ${partnerData['phone'] ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Text(
                              'Vehicle: ${partnerData['vehicleType'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (partnerData['isApproved'] ?? false)
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (partnerData['isApproved'] ?? false)
                                        ? 'Approved'
                                        : 'Pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (partnerData['isApproved'] ?? false)
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (partnerData['isActive'] ?? true)
                                        ? Colors.blue.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (partnerData['isActive'] ?? true)
                                        ? 'Active'
                                        : 'Suspended',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (partnerData['isActive'] ?? true)
                                          ? Colors.blue.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
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
                            if (!(partnerData['isApproved'] ?? false))
                              const PopupMenuItem(
                                value: 'approve',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 20, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Approve Partner'),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'suspend',
                              child: Row(
                                children: [
                                  Icon(
                                    (partnerData['isActive'] ?? true)
                                        ? Icons.block
                                        : Icons.check_circle,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text((partnerData['isActive'] ?? true)
                                      ? 'Suspend Partner'
                                      : 'Activate Partner'),
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
                                  Text('Delete Partner',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            switch (value) {
                              case 'view':
                                _viewPartnerDetails(partnerId, partnerData);
                                break;
                              case 'approve':
                                _approvePartner(partnerId, partnerData);
                                break;
                              case 'suspend':
                                _togglePartnerStatus(partnerId, partnerData);
                                break;
                              case 'delete':
                                _deletePartner(partnerId, partnerData);
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

  void _viewPartnerDetails(String partnerId, Map<String, dynamic> partnerData) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.delivery_dining,
                        color: Colors.green.shade900, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Partner Details',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow('Name', partnerData['name'] ?? 'N/A'),
                _buildDetailRow('Phone', partnerData['phone'] ?? 'N/A'),
                _buildDetailRow('Email', partnerData['email'] ?? 'N/A'),
                _buildDetailRow(
                    'Vehicle Type', partnerData['vehicleType'] ?? 'N/A'),
                _buildDetailRow(
                    'Vehicle Number', partnerData['vehicleNumber'] ?? 'N/A'),
                _buildDetailRow('Partner ID', partnerId),
                _buildDetailRow(
                  'Status',
                  (partnerData['isApproved'] ?? false)
                      ? 'Approved'
                      : 'Pending Approval',
                ),
                _buildDetailRow(
                  'Active Status',
                  (partnerData['isActive'] ?? true) ? 'Active' : 'Suspended',
                ),
                _buildDetailRow(
                  'Completed Orders',
                  (partnerData['completedOrders'] ?? 0).toString(),
                ),
                _buildDetailRow(
                  'Total Earnings',
                  '৳${partnerData['totalEarnings'] ?? 0}',
                ),
                _buildDetailRow(
                  'Joined',
                  partnerData['createdAt'] != null
                      ? (partnerData['createdAt'] as Timestamp)
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
            width: 120,
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

  Future<void> _approvePartner(
      String partnerId, Map<String, dynamic> partnerData) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Approve Partner?'),
        content: Text('Approve ${partnerData['name']} as a delivery partner?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('partners').doc(partnerId).update({
                  'isApproved': true,
                });
                Get.back();
                Get.snackbar(
                  'Success',
                  'Partner approved successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to approve partner',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePartnerStatus(
      String partnerId, Map<String, dynamic> partnerData) async {
    bool currentStatus = partnerData['isActive'] ?? true;
    bool newStatus = !currentStatus;

    Get.dialog(
      AlertDialog(
        title: Text(newStatus ? 'Activate Partner?' : 'Suspend Partner?'),
        content: Text(
          newStatus
              ? 'This partner will be able to accept orders.'
              : 'This partner will not be able to accept orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('partners').doc(partnerId).update({
                  'isActive': newStatus,
                });
                Get.back();
                Get.snackbar(
                  'Success',
                  'Partner ${newStatus ? 'activated' : 'suspended'} successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to update partner status',
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

  Future<void> _deletePartner(
      String partnerId, Map<String, dynamic> partnerData) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Partner?'),
        content: Text(
          'Are you sure you want to permanently delete ${partnerData['name']}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('partners').doc(partnerId).delete();
                Get.back();
                Get.snackbar(
                  'Success',
                  'Partner deleted successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to delete partner',
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
