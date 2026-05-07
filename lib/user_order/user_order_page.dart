import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:saver/components/alert.dart';
import 'package:shimmer/shimmer.dart';
import 'user_order_controller.dart';
import '../loader/loader.dart';
import '../home_user/home_user_controller.dart';
import '../components/constants/images.dart';

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
        return Icons.trip_origin;
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
            title: const Text('Your Trips',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  fontSize: 22,
                  letterSpacing: -0.5,
                )),
            centerTitle: false,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: Colors.grey.withValues(alpha: 0.1),
                height: 1,
              ),
            ),
          ),
          backgroundColor: const Color(0xFFF8FAFC),
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
                  child: Text('Please log in to see your trips.',
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
                        Image.asset(
                          AppImages.tripPng,
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You haven\'t placed any trip yet',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemBuilder: (context, index, animation) {
                    final orderDoc = snapshot.data!.docs[index];
                    final orderData = orderDoc.data() as Map<String, dynamic>;
                    orderData['id'] = orderDoc.id;

                    final companyName =
                        orderData['companyName'] as String? ?? 'Trip Details';
                    final orderStatus = orderData['status'] as String?;
                    final createdAt =
                        (orderData['timestamp'] as Timestamp?)?.toDate();
                    final serviceType = orderData['serviceType'] as String? ??
                        orderData['type'] as String?;
                    final urgency = orderData['urgency'] as String?;
                    final statusColor = controller.getStatusColor(orderStatus);

                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(
                        opacity: animation,
                        child: GestureDetector(
                          onTap: () => Get.to(
                              () => OrderDetailScreen(orderData: orderData)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Status Indicator Strip
                                    Container(
                                      width: 6,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 12),
                                    // Main Content
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 12),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Left side: Name and Service Badges
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    companyName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17,
                                                      color: Color(0xFF1A1A1A),
                                                      letterSpacing: -0.5,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      _buildInfoBadge(
                                                        context,
                                                        (serviceType ?? 'TRIP')
                                                            .toUpperCase(),
                                                        Colors.blue.shade700,
                                                        Colors.blue.shade50,
                                                      ),
                                                      if (urgency != null &&
                                                          urgency != 'normal')
                                                        _buildInfoBadge(
                                                          context,
                                                          urgency.toUpperCase(),
                                                          urgency == 'emergency'
                                                              ? Colors.red
                                                              : Colors.orange
                                                                  .shade800,
                                                          urgency == 'emergency'
                                                              ? Colors
                                                                  .red.shade50
                                                              : Colors.orange
                                                                  .shade50,
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Right side: Fare, Status, and Date
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                if (orderData['fareAmount'] !=
                                                    null)
                                                  Text(
                                                    '৳${orderData['fareAmount']}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.green.shade700,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    (orderStatus ?? 'UNKNOWN')
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .calendar_today_outlined,
                                                        size: 12,
                                                        color: Colors
                                                            .grey.shade500),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      controller.formatDate(
                                                          Timestamp.fromDate(
                                                              createdAt ??
                                                                  DateTime
                                                                      .now())),
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade500,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                ),
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

  Widget _buildInfoBadge(
      BuildContext context, String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
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
        return Icons.trip_origin;
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
        title: Text(companyName ?? 'Trip Details',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 20,
            )),
        backgroundColor: const Color(0xFFDCF2F7), // Light blue app bar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (orderStatus?.toLowerCase() == 'pending')
            IconButton(
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: Text('Cancel Trip'),
                    content: Text('Are you sure you want to cancel this trip?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement order cancellation
                          Get.back();
                          Alert.info('Trip cancellation not implemented yet');
                        },
                        child: Text('Yes', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.cancel_outlined, color: Colors.black87),
            ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card - Modern Glassmorphism-like style
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    controller
                        .getStatusColor(orderStatus)
                        .withValues(alpha: 0.15),
                    controller
                        .getStatusColor(orderStatus)
                        .withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: controller
                      .getStatusColor(orderStatus)
                      .withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: controller
                              .getStatusColor(orderStatus)
                              .withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getOrderIcon(serviceType),
                      color: controller.getStatusColor(orderStatus),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    orderStatus?.toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: controller.getStatusColor(orderStatus),
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (urgency != null && urgency != 'normal') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            urgency == 'emergency' ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        urgency.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Trip Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailItem(context, 'Company Name',
                      companyName ?? 'N/A', Icons.store_outlined),
                  _buildDivider(),
                  if (serviceType != null) ...[
                    _buildDetailItem(context, 'Service Type', serviceType,
                        Icons.category_outlined),
                    _buildDivider(),
                  ],
                  if (createdAt != null) ...[
                    _buildDetailItem(
                        context,
                        'Placed On',
                        DateFormat('MMM d, yyyy • h:mm a').format(createdAt),
                        Icons.calendar_today_outlined),
                    _buildDivider(),
                  ],
                  if (patientName != null) ...[
                    _buildDetailItem(context, 'Patient Name', patientName,
                        Icons.person_outlined),
                    _buildDivider(),
                  ],
                  if (contactNumber != null)
                    _buildDetailItem(
                      context,
                      'Contact Number',
                      (orderStatus?.toLowerCase() == 'pending' ||
                              orderStatus?.toLowerCase() == 'cancelled')
                          ? 'Available after confirmation'
                          : contactNumber,
                      Icons.phone_outlined,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (orderData['fareAmount'] != null)
              _buildDetailItem(context, 'Ride Fare',
                  '৳${orderData['fareAmount']}', Icons.attach_money_outlined,
                  color: Colors.green.shade700),
            const SizedBox(height: 16),

            // Fare Breakdown Section
            if (orderData['fareAmount'] != null) ...[
              Text(
                'Fare Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _buildFareRow(
                        'Service Charge', '৳${orderData['fareAmount']}',
                        isTotal: true),
                    if (orderData['distance'] != null) ...[
                      const SizedBox(height: 12),
                      _buildFareRow(
                          'Estimated Distance', '${orderData['distance']} km'),
                    ],
                    if (orderData['urgency'] != null &&
                        orderData['urgency'] != 'normal') ...[
                      const SizedBox(height: 12),
                      _buildFareRow(
                          'Urgency Multiplier',
                          orderData['urgency'] == 'emergency'
                              ? '1.5x'
                              : '1.2x'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            if (pickupAddress != null && pickupAddress.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pickupAddress,
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            if (issueDetails != null && issueDetails.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_outlined,
                            color: Colors.blue.shade400, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            issueDetails,
                            style: TextStyle(
                              color: const Color(0xFF4A4A4A),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),

            // Action Buttons - Premium Style
            if (orderStatus?.toLowerCase() == 'accepted' ||
                orderStatus?.toLowerCase() == 'in_transit')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.map_outlined,
                        color: Colors.white, size: 32),
                    const SizedBox(height: 16),
                    const Text(
                      'Ambulance is on the way!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can track the live location of your ambulance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final homeController = Get.find<HomeController>();
                          final orderId = orderData['id'] as String?;
                          if (orderId != null) {
                            homeController.navigateToUserTracking(orderId);
                          }
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text(
                          'অ্যাম্বুলেন্স ট্র্যাক করুন',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
      BuildContext context, String title, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color ?? const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF15803D) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? const Color(0xFF15803D) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.withValues(alpha: 0.1),
      height: 1,
    );
  }

  Widget _buildTitleWithIcon(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
