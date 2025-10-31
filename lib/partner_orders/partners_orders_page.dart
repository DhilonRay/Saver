import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'partner_orders_controller.dart';

class PartnersOrdersPage extends StatelessWidget {
  const PartnersOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PartnerOrdersController>(
      init: PartnerOrdersController(),
      builder: (controller) {
        final colorScheme = Theme.of(context).colorScheme;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Your Orders', style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.teal.shade800,
              elevation: 2,
              iconTheme: IconThemeData(color: colorScheme.onPrimary),
              titleTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 18),
              bottom: TabBar(
                // Make tabs expand evenly to fill the available width
                isScrollable: false,
                indicatorColor: Colors.white,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3.0,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                // ensure equal spacing inside each tab
                labelPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                tabs: const [
                  Tab(text: 'Activity', icon: Icon(Icons.work)),
                  Tab(text: 'Completed', icon: Icon(Icons.done_all)),
                  Tab(text: 'Cancelled', icon: Icon(Icons.cancel)),
                ],
              ),
            ),
            backgroundColor: colorScheme.surface,
            body: Obx(() {
              if (controller.partnerId.value.isEmpty) {
                return Center(
                  child: Text(
                    'Please log in as a partner to see your orders.',
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))
                  )
                );
              }

              return TabBarView(
                children: [
                  _buildActivityTab(controller, colorScheme),
                  _buildOrdersTab(controller, 'completed', colorScheme),
                  _buildOrdersTab(controller, 'cancelled', colorScheme),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab(PartnerOrdersController controller, String status, ColorScheme colorScheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong: ${snapshot.error}',
              style: TextStyle(color: colorScheme.error)
            )
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.teal.shade800));
        }

        // Filter orders by status
        final filteredDocs = snapshot.data?.docs.where((doc) {
          final orderData = doc.data() as Map<String, dynamic>;
          return orderData['status'] == status;
        }).toList() ?? [];

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 64,
                  color: colorScheme.onSurface.withValues(alpha: 0.3)
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.replaceAll('_', ' ')} orders.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 16
                  )
                ),
              ],
            )
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final orderDoc = filteredDocs[index];
            final orderData = orderDoc.data() as Map<String, dynamic>;
            final orderId = orderDoc.id;
            final userId = orderData['userId'] as String?;
            final orderStatus = orderData['status'] as String?;
            final createdAt = (orderData['timestamp'] as Timestamp?)?.toDate();
            final serviceType = orderData['type'] as String?;
            final emergencyLevel = orderData['urgency'] as String?;
            final patientName = orderData['patientName'] as String?;
            final pickupAddress = orderData['pickupAddress'] as String?;

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data?.data();
                final userName = userData?['name'] as String?;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(orderStatus ?? 'pending').withValues(alpha: 0.1),
                          colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with patient name and status
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patientName ?? userName ?? 'New Order',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: colorScheme.onSurface
                                      )
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (serviceType != null) ...[
                                          Text(
                                            serviceType,
                                            style: TextStyle(
                                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (emergencyLevel != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: emergencyLevel == 'high' ? Colors.red.withValues(alpha: 0.1) :
                                                     emergencyLevel == 'medium' ? Colors.orange.withValues(alpha: 0.1) :
                                                     Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              emergencyLevel.toUpperCase(),
                                              style: TextStyle(
                                                color: emergencyLevel == 'high' ? Colors.red :
                                                       emergencyLevel == 'medium' ? Colors.orange :
                                                       Colors.green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(orderStatus ?? 'pending').withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getStatusColor(orderStatus ?? 'pending').withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  (orderStatus ?? 'pending').replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(orderStatus ?? 'pending'),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Address
                          if (pickupAddress != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    pickupAddress.length > 50 ? '${pickupAddress.substring(0, 50)}...' : pickupAddress,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          // Timestamp
                          if (createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(createdAt.toLocal()),
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: _buildActionButtons(orderStatus, orderId, orderData, controller, colorScheme),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActivityTab(PartnerOrdersController controller, ColorScheme colorScheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong: ${snapshot.error}',
              style: TextStyle(color: colorScheme.error)
            )
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.teal.shade800));
        }

        // Filter orders by activity statuses: pending, accepted, in_transit
        final filteredDocs = snapshot.data?.docs.where((doc) {
          final orderData = doc.data() as Map<String, dynamic>;
          final status = orderData['status'] as String?;
          return status == 'pending' || status == 'accepted' || status == 'in_transit';
        }).toList() ?? [];

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 64,
                  color: colorScheme.onSurface.withValues(alpha: 0.3)
                ),
                const SizedBox(height: 16),
                Text(
                  'No active orders.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 16
                  )
                ),
              ],
            )
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final orderDoc = filteredDocs[index];
            final orderData = orderDoc.data() as Map<String, dynamic>;
            final orderId = orderDoc.id;
            final userId = orderData['userId'] as String?;
            final orderStatus = orderData['status'] as String?;
            final createdAt = (orderData['timestamp'] as Timestamp?)?.toDate();
            final serviceType = orderData['type'] as String?;
            final emergencyLevel = orderData['urgency'] as String?;
            final patientName = orderData['patientName'] as String?;
            final pickupAddress = orderData['pickupAddress'] as String?;

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data?.data();
                final userName = userData?['name'] as String?;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(orderStatus ?? 'pending').withValues(alpha: 0.1),
                          colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with patient name and status
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patientName ?? userName ?? 'New Order',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: colorScheme.onSurface
                                      )
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (serviceType != null) ...[
                                          Text(
                                            serviceType,
                                            style: TextStyle(
                                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (emergencyLevel != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: emergencyLevel == 'high' ? Colors.red.withValues(alpha: 0.1) :
                                                     emergencyLevel == 'medium' ? Colors.orange.withValues(alpha: 0.1) :
                                                     Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              emergencyLevel.toUpperCase(),
                                              style: TextStyle(
                                                color: emergencyLevel == 'high' ? Colors.red :
                                                       emergencyLevel == 'medium' ? Colors.orange :
                                                       Colors.green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(orderStatus ?? 'pending').withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getStatusColor(orderStatus ?? 'pending').withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  (orderStatus ?? 'pending').replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(orderStatus ?? 'pending'),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Address
                          if (pickupAddress != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    pickupAddress.length > 50 ? '${pickupAddress.substring(0, 50)}...' : pickupAddress,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          // Timestamp
                          if (createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d, h:mm a').format(createdAt.toLocal()),
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: _buildActionButtons(orderStatus, orderId, orderData, controller, colorScheme),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }



  List<Widget> _buildActionButtons(String? orderStatus, String orderId, Map<String, dynamic> orderData, PartnerOrdersController controller, ColorScheme colorScheme) {
    switch (orderStatus) {
      case 'pending':
        return [
          ElevatedButton.icon(
            onPressed: () => controller.updateOrderStatus(orderId, 'accepted'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 2,
            ),
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text('Accept Order'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => controller.updateOrderStatus(orderId, 'cancelled'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.cancel, size: 20),
            label: const Text('Cancel'),
          ),
        ];
      case 'accepted':
        return [
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to AcceptMapsPage with order data
              Get.toNamed('/accept-maps', arguments: {
                'id': orderId,
                'patientName': orderData['patientName'] ?? 'Patient',
                'phone': orderData['phone'] ?? '',
                'pickupAddress': orderData['pickupAddress'] ?? '',
                'emergencyType': orderData['urgency'] ?? '',
                'notes': orderData['notes'] ?? '',
                'pickupLat': orderData['pickupLat'] ?? 0.0,
                'pickupLng': orderData['pickupLng'] ?? 0.0,
                'userId': orderData['userId'] ?? '',
                'type': orderData['type'] ?? '',
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 2,
            ),
            icon: const Icon(Icons.local_shipping, size: 20),
            label: const Text('Start Journey'),
          ),
        ];
      case 'in_transit':
        return [
          ElevatedButton.icon(
            onPressed: () => controller.updateOrderStatus(orderId, 'completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 2,
            ),
            icon: const Icon(Icons.done_all, size: 20),
            label: const Text('Mark Complete'),
          ),
        ];
      default:
        return []; // No action buttons for completed/cancelled orders
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle;
      case 'in_transit':
        return Icons.local_shipping;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'accepted':
        return Colors.green.shade700;
      case 'in_transit':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.teal.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}