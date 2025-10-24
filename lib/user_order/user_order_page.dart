import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'user_order_controller.dart';

class UserOrdersPage extends StatelessWidget {
  const UserOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserOrderController>(
      init: UserOrderController(),
      builder: (controller) {
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Orders', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: colorScheme.primary,
            elevation: 2,
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            titleTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 18),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
                onPressed: controller.refreshOrders,
              ),
            ],
          ),
          backgroundColor: colorScheme.surface,
          body: Obx(() {
            if (controller.isLoading.value) {
              return Center(child: CircularProgressIndicator(color: colorScheme.primary));
            }

            if (controller.error.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.error.value,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.refreshOrders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (controller.userId.isEmpty) {
              return Center(
                child: Text(
                  'Please log in to see your orders.',
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
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'You haven\'t placed any orders yet.',
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
                    final companyName = orderData['companyName'] as String? ?? 'Order Details';
                    final orderStatus = orderData['orderStatus'] as String?;
                    final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate();
                    final partnerId = orderData['partnerId'] as String?;

                    return GestureDetector(
                      onTap: () {
                        Get.to(() => OrderDetailScreen(orderData: orderData));
                      },
                      child: Container(
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
                          child: Row(
                            children: [
                              Icon(Icons.notifications_outlined, color: colorScheme.primary, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      companyName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface
                                      )
                                    ),
                                    const SizedBox(height: 4),
                                    if (createdAt != null)
                                      Text(
                                        'Placed on: ${controller.formatDate(Timestamp.fromDate(createdAt))}',
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontSize: 12
                                        ),
                                      ),
                                    if (orderStatus != null)
                                      Text(
                                        'Status: $orderStatus',
                                        style: TextStyle(
                                          color: controller.getStatusColor(orderStatus),
                                          fontWeight: FontWeight.w400
                                        )
                                      ),
                                  ],
                                ),
                              ),
                              if (partnerId != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Icon(Icons.handshake_outlined, color: colorScheme.secondary, size: 20),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Partner: ${controller.getShortPartnerId(partnerId)}',
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontSize: 10
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                              Icon(Icons.chevron_right_outlined, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                            ],
                          ),
                        ),
                      ),
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

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserOrderController>();
    final companyName = orderData['companyName'] as String?;
    final orderStatus = orderData['orderStatus'] as String?;
    final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate().toLocal();
    final partnerId = orderData['partnerId'] as String?;
    final serviceType = orderData['serviceType'] as String?;
    final issueDetails = orderData['issueDetails'] as String?;
    final contactNumber = orderData['contactNumber'] as String?;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          companyName ?? 'Order Details',
          style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onPrimary)
        ),
        backgroundColor: colorScheme.primary,
        elevation: 2,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(context, 'Company Name', companyName ?? 'N/A', Icons.store_outlined),
            const SizedBox(height: 16),
            _buildDetailItem(
              context,
              'Status',
              orderStatus ?? 'Pending',
              Icons.assignment_turned_in_outlined,
              color: controller.getStatusColor(orderStatus)
            ),
            const SizedBox(height: 16),
            if (createdAt != null)
              _buildDetailItem(
                context,
                'Placed On',
                DateFormat('MMM d, h:mm a').format(createdAt),
                Icons.calendar_today_outlined
              ),
            const SizedBox(height: 16),
            if (partnerId != null)
              _buildDetailItem(context, 'Partner ID', partnerId, Icons.handshake_outlined),
            const SizedBox(height: 16),
            if (serviceType != null)
              _buildDetailItem(context, 'Service Type', serviceType, Icons.category_outlined),
            const SizedBox(height: 16),
            if (issueDetails != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleWithIcon(context, 'Issue Details', Icons.report_problem_outlined),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(issueDetails, style: TextStyle(color: colorScheme.onSurface)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (contactNumber != null)
              _buildDetailItem(context, 'Contact Number', contactNumber, Icons.phone_outlined),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String title, String? value, IconData icon, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)
              ),
              const SizedBox(height: 4),
              Text(
                value ?? 'N/A',
                style: TextStyle(color: color ?? colorScheme.onSurface.withValues(alpha: 0.7))
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleWithIcon(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface
          )
        ),
      ],
    );
  }
}