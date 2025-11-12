import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'user_order_controller.dart';
import '../loader/loader.dart';
import '../home_user/home_user_controller.dart';

class OrderSkeletonLoader extends StatelessWidget {
  const OrderSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerLowest,
          ],
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        highlightColor:
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        period: const Duration(milliseconds: 1500),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: 6, // Show 6 skeleton items
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Ambulance Icon Container with Gradient
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade100,
                            Colors.blue.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company Name
                          Container(
                            height: 20,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Service Type Badge
                          Container(
                            height: 18,
                            width: 90,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Date and Time
                          Container(
                            height: 14,
                            width: 160,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Urgency Level
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Status Badge
                          Container(
                            height: 20,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.green.shade200
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Partner Info Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Partner Icon
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Partner ID
                        Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Chevron Icon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class UserOrdersPage extends StatelessWidget {
  const UserOrdersPage({super.key});

  IconData _getOrderIcon(String? serviceType) {
    switch (serviceType?.toLowerCase()) {
      case 'ambulance':
        return Icons.local_hospital_outlined;
      case 'repair':
        return Icons.build_outlined;
      case 'maintenance':
        return Icons.settings_outlined;
      case 'emergency':
        return Icons.warning_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserOrderController>(
      init: UserOrderController(),
      builder: (controller) {
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Orders',
                style: TextStyle(fontWeight: FontWeight.w600)),
            centerTitle: true,
            backgroundColor: colorScheme.primary,
            elevation: 2,
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            titleTextStyle:
                TextStyle(color: colorScheme.onPrimary, fontSize: 18),
          ),
          backgroundColor: colorScheme.surface,
          body: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                  child: HorizontalRotatingDots(size: 60, colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary
              ]));
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
                  child: Text('Please log in to see your orders.',
                      style: TextStyle(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.7))));
            }

            return StreamBuilder<QuerySnapshot>(
              stream: controller.getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Something went wrong: ${snapshot.error}',
                          style: TextStyle(color: colorScheme.error)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const OrderSkeletonLoader();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You haven\'t placed any orders yet.',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Get.back(),
                          icon: Icon(Icons.arrow_back),
                          label: Text('Go Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return AnimatedList(
                  initialItemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index, animation) {
                    final orderDoc = snapshot.data!.docs[index];
                    final orderData = orderDoc.data() as Map<String, dynamic>;
                    // Add document ID to orderData
                    orderData['id'] = orderDoc.id;
                    final companyName =
                        orderData['companyName'] as String? ?? 'Order Details';
                    final orderStatus = orderData['status'] as String?;
                    final createdAt =
                        (orderData['timestamp'] as Timestamp?)?.toDate();
                    final partnerId = orderData['partnerId'] as String?;
                    final serviceType = orderData['serviceType'] as String? ??
                        orderData['type'] as String?;
                    final urgency = orderData['urgency'] as String?;

                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: FadeTransition(
                        opacity: animation,
                        child: GestureDetector(
                          onTap: () {
                            Get.to(
                                () => OrderDetailScreen(orderData: orderData));
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.8),
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
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: controller
                                          .getStatusColor(orderStatus)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getOrderIcon(serviceType),
                                      color: controller
                                          .getStatusColor(orderStatus),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(companyName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                              fontSize: 16,
                                            )),
                                        const SizedBox(height: 4),
                                        if (serviceType != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .secondaryContainer
                                                  .withValues(alpha: 0.3),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              serviceType.toUpperCase(),
                                              style: TextStyle(
                                                color: colorScheme
                                                    .onSecondaryContainer,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        if (createdAt != null)
                                          Text(
                                            'Placed: ${controller.formatDate(Timestamp.fromDate(createdAt))}',
                                            style: TextStyle(
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                                fontSize: 12),
                                          ),
                                        if (urgency != null &&
                                            urgency != 'normal')
                                          Text(
                                            'Urgency: ${urgency.toUpperCase()}',
                                            style: TextStyle(
                                              color: urgency == 'emergency'
                                                  ? Colors.red
                                                  : Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        if (orderData['fareAmount'] != null)
                                          Text(
                                            'Fare: ৳${orderData['fareAmount']}',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        if (orderStatus != null)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: controller
                                                  .getStatusColor(orderStatus)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: controller
                                                    .getStatusColor(orderStatus)
                                                    .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                                orderStatus.toUpperCase(),
                                                style: TextStyle(
                                                  color:
                                                      controller.getStatusColor(
                                                          orderStatus),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                )),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (partnerId != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Icon(
                                            Icons.handshake_outlined,
                                            color: colorScheme.secondary,
                                            size: 20,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                              'ID: ${controller.getShortPartnerId(partnerId)}',
                                              style: TextStyle(
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.6),
                                                  fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  Icon(
                                    Icons.chevron_right_outlined,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                            ),
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

  IconData _getOrderIcon(String? serviceType) {
    switch (serviceType?.toLowerCase()) {
      case 'ambulance':
        return Icons.local_hospital_outlined;
      case 'repair':
        return Icons.build_outlined;
      case 'maintenance':
        return Icons.settings_outlined;
      case 'emergency':
        return Icons.warning_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserOrderController>();
    final companyName = orderData['companyName'] as String?;
    final orderStatus = orderData['status'] as String?;
    final createdAt =
        (orderData['timestamp'] as Timestamp?)?.toDate().toLocal();
    final partnerId = orderData['partnerId'] as String?;
    final serviceType =
        orderData['serviceType'] as String? ?? orderData['type'] as String?;
    final issueDetails =
        orderData['issueDetails'] as String? ?? orderData['notes'] as String?;
    final contactNumber =
        orderData['contactNumber'] as String? ?? orderData['phone'] as String?;
    final urgency = orderData['urgency'] as String?;
    final pickupAddress = orderData['pickupAddress'] as String?;
    final patientName = orderData['patientName'] as String?;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(companyName ?? 'Order Details',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        elevation: 2,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          if (orderStatus?.toLowerCase() == 'pending')
            IconButton(
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: Text('Cancel Order'),
                    content:
                        Text('Are you sure you want to cancel this order?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement order cancellation
                          Get.back();
                          Get.snackbar(
                              'Info', 'Order cancellation not implemented yet');
                        },
                        child: Text('Yes', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.cancel_outlined, color: colorScheme.onPrimary),
            ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: controller
                    .getStatusColor(orderStatus)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller
                      .getStatusColor(orderStatus)
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getOrderIcon(serviceType),
                    color: controller.getStatusColor(orderStatus),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderStatus?.toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: controller.getStatusColor(orderStatus),
                          ),
                        ),
                        if (urgency != null && urgency != 'normal')
                          Text(
                            'Urgency: ${urgency.toUpperCase()}',
                            style: TextStyle(
                              color: urgency == 'emergency'
                                  ? Colors.red
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildDetailItem(context, 'Company Name', companyName ?? 'N/A',
                Icons.store_outlined),
            const SizedBox(height: 16),
            if (serviceType != null)
              _buildDetailItem(context, 'Service Type', serviceType,
                  Icons.category_outlined),
            const SizedBox(height: 16),
            if (createdAt != null)
              _buildDetailItem(
                  context,
                  'Placed On',
                  DateFormat('MMM d, h:mm a').format(createdAt),
                  Icons.calendar_today_outlined),
            const SizedBox(height: 16),
            if (partnerId != null)
              _buildDetailItem(
                  context, 'Partner ID', partnerId, Icons.handshake_outlined),
            const SizedBox(height: 16),
            if (patientName != null)
              _buildDetailItem(
                  context, 'Patient Name', patientName, Icons.person_outlined),
            const SizedBox(height: 16),
            if (contactNumber != null)
              _buildDetailItem(context, 'Contact Number', contactNumber,
                  Icons.phone_outlined),
            const SizedBox(height: 16),
            if (orderData['fareAmount'] != null)
              _buildDetailItem(context, 'Ride Fare',
                  '৳${orderData['fareAmount']}', Icons.attach_money_outlined,
                  color: Colors.green.shade700),
            const SizedBox(height: 16),
            if (pickupAddress != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleWithIcon(
                      context, 'Pickup Address', Icons.location_on_outlined),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pickupAddress,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (issueDetails != null && issueDetails.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleWithIcon(
                      context, 'Additional Notes', Icons.note_outlined),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issueDetails,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Action Buttons
            if (orderStatus?.toLowerCase() == 'accepted' ||
                orderStatus?.toLowerCase() == 'in_transit')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to live tracking page
                          final homeController = Get.find<HomeController>();
                          final orderId = orderData['id'] as String?;
                          if (orderId != null) {
                            homeController.navigateToUserTracking(orderId);
                          }
                        },
                        icon: Icon(Icons.location_on),
                        label: Text('অ্যাম্বুলেন্স ট্র্যাক করুন'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      BuildContext context, String title, String? value, IconData icon,
      {Color? color}) {
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
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface)),
              const SizedBox(height: 4),
              Text(value ?? 'N/A',
                  style: TextStyle(
                      color: color ??
                          colorScheme.onSurface.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleWithIcon(
      BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface)),
      ],
    );
  }
}
