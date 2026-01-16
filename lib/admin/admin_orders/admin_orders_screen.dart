import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('Accepted', 'accepted'),
                _buildFilterChip('Picked Up', 'picked_up'),
                _buildFilterChip('Completed', 'completed'),
                _buildFilterChip('Cancelled', 'cancelled'),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedFilter == 'all'
                  ? _firestore
                      .collection('orders')
                      .orderBy('createdAt', descending: true)
                      .snapshots()
                  : _firestore
                      .collection('orders')
                      .where('status', isEqualTo: _selectedFilter)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return const Center(child: Text('No orders found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var orderData =
                        orders[index].data() as Map<String, dynamic>;
                    var orderId = orders[index].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _viewOrderDetails(orderId, orderData),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${orderId.substring(0, 8)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  _buildStatusChip(
                                      orderData['status'] ?? 'pending'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Customer: ${orderData['userName'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Amount: ৳${orderData['totalAmount'] ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                orderData['createdAt'] != null
                                    ? DateFormat('dd MMM yyyy, hh:mm a').format(
                                        (orderData['createdAt'] as Timestamp)
                                            .toDate())
                                    : 'N/A',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (orderData['partnerName'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.delivery_dining,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      orderData['partnerName'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
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

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.blue.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'picked_up':
        color = Colors.purple;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _viewOrderDetails(String orderId, Map<String, dynamic> orderData) {
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
                    Icon(Icons.assignment,
                        color: Colors.blue.shade900, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Order #${orderId.substring(0, 8)}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildStatusChip(orderData['status'] ?? 'pending'),
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow('Customer', orderData['userName'] ?? 'N/A'),
                _buildDetailRow('Phone', orderData['userPhone'] ?? 'N/A'),
                _buildDetailRow('Amount', '৳${orderData['totalAmount'] ?? 0}'),
                _buildDetailRow('Pickup', orderData['pickupAddress'] ?? 'N/A'),
                _buildDetailRow(
                    'Delivery', orderData['deliveryAddress'] ?? 'N/A'),
                if (orderData['partnerName'] != null)
                  _buildDetailRow('Partner', orderData['partnerName']),
                _buildDetailRow(
                  'Order Date',
                  orderData['createdAt'] != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(
                          (orderData['createdAt'] as Timestamp).toDate())
                      : 'N/A',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Update Status:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusButton('Pending', 'pending', orderId),
                    _buildStatusButton('Accepted', 'accepted', orderId),
                    _buildStatusButton('Picked Up', 'picked_up', orderId),
                    _buildStatusButton('Completed', 'completed', orderId),
                    _buildStatusButton('Cancelled', 'cancelled', orderId),
                  ],
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

  Widget _buildStatusButton(String label, String status, String orderId) {
    return ElevatedButton(
      onPressed: () => _updateOrderStatus(orderId, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getStatusColor(status),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.back();
      Get.snackbar(
        'Success',
        'Order status updated to $newStatus',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order status',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
