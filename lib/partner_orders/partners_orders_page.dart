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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Assigned Orders', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.teal.shade800,
            elevation: 2,
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            titleTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 18),
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

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders received yet.',
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))
                    )
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final orderDoc = snapshot.data!.docs[index];
                    final orderData = orderDoc.data() as Map<String, dynamic>;
                    final orderId = orderDoc.id;
                    final userId = orderData['userId'] as String?;
                    final orderStatus = orderData['orderStatus'] as String?;
                    final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate();
                    final companyName = orderData['companyName'];

                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data?.data();
                        final userName = userData?['name'] as String?;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.notifications_active_outlined, color: Colors.teal.shade700, size: 32),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName ?? 'New Order',
                                            style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)
                                          ),
                                          const SizedBox(height: 4),
                                          if (userId != null)
                                            Text(
                                              'User ID: ${userId.substring(0, 8)}...',
                                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)
                                            ),
                                          if (createdAt != null)
                                            Text(
                                              'Time: ${DateFormat('MMM d, h:mm a').format(createdAt.toLocal())}',
                                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                                            ),
                                          if (orderStatus != null)
                                            Text(
                                              'Status: $orderStatus',
                                              style: TextStyle(color: controller.getStatusColor(orderStatus, colorScheme), fontWeight: FontWeight.w400)
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (orderStatus == 'pending')
                                      ElevatedButton.icon(
                                        onPressed: () => controller.updateOrderStatus(orderId, 'accepted'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade500,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        icon: const Icon(Icons.check_circle_outline, size: 20),
                                        label: const Text('Accept'),
                                      ),
                                    const SizedBox(width: 8.0),
                                    if (orderStatus == 'pending')
                                      OutlinedButton.icon(
                                        onPressed: () => controller.updateOrderStatus(orderId, 'cancelled'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade500,
                                          side: BorderSide(color: Colors.red.shade500),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        icon: const Icon(Icons.cancel_outlined, size: 20),
                                        label: const Text('Cancel'),
                                      ),
                                    const SizedBox(width: 8.0),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      color: colorScheme.secondary,
                                      onPressed: () => controller.showOrderDetails(context, userId, userName, companyName, orderStatus),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          }),
        );
      },
    );
  }
}