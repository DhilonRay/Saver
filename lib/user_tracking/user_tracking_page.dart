import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'user_tracking_controller.dart';

class UserTrackingPage extends StatelessWidget {
  const UserTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserTrackingController>(
      init: UserTrackingController(),
      builder: (controller) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'অ্যাম্বুলেন্স ট্র্যাকিং',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: Colors.blue.shade800.withOpacity(0.9),
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.blue, size: 20),
                  onPressed: controller.goBack,
                ),
              ),
            ),
            actions: [
              // Zoom controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: controller.zoomIn,
                    tooltip: 'Zoom In',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed: controller.zoomOut,
                    tooltip: 'Zoom Out',
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Google Map
              Obx(() {
                if (controller.isLoadingLocation.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade700),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'লোকেশন লোড হচ্ছে...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: controller.userPosition.value ??
                        UserTrackingController.defaultPosition,
                    zoom: 14.0,
                  ),
                  markers: Set<Marker>.of(controller.markers),
                  polylines: Set<Polyline>.of(controller.polylines),
                  onMapCreated: controller.onMapCreated,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                );
              }),

              // Map Overlay Elements
              Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: _buildTopStatusCard(controller),
              ),

              // ETA and Status Information Panel
              BottomDraggablePanel(controller: controller),

              // Loading overlay for ETA calculation
              Obx(() {
                if (controller.isCalculatingETA.value) {
                  return Positioned(
                    top: 160,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'সময় গণনা করা হচ্ছে...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopStatusCard(UserTrackingController controller) {
    return Obx(() {
      final orderData = controller.orderData.value;
      final status =
          orderData?['orderStatus'] ?? orderData?['status'] ?? 'unknown';
      final isCompleted = status.toLowerCase() == 'completed';

      String statusTitle;
      Color statusColor;
      IconData statusIcon;

      if (isCompleted) {
        statusTitle = 'সার্ভিস সম্পন্ন হয়েছে';
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
      } else if (status.toLowerCase() == 'pickup' ||
          status.toLowerCase() == 'to_destination') {
        statusTitle = 'অ্যাম্বুলেন্স আপনার গন্তব্যে যাচ্ছে';
        statusColor = Colors.teal.shade600;
        statusIcon = Icons.flag;
      } else {
        statusTitle = 'অ্যাম্বুলেন্স আপনার দিকে আসছে';
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.local_shipping;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (!isCompleted)
                    Obx(() => Text(
                          'অনুমানিক দূরত্ব: ${controller.estimatedDistance.value > 0 ? '${controller.estimatedDistance.value.toStringAsFixed(1)} কিমি' : 'গণনা হচ্ছে...'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )),
                ],
              ),
            ),
            if (!isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'লাইভ',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class BottomDraggablePanel extends StatelessWidget {
  final UserTrackingController controller;
  const BottomDraggablePanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ETA and Arrival Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'পৌঁছাতে সময় লাগবে',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                            controller.estimatedTime.value,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          )),
                    ],
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),

              // Driver Information
              Obx(() {
                final name = controller.partnerName.value;
                final imageUrl = controller.partnerImage.value;

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                          imageUrl != null ? NetworkImage(imageUrl) : null,
                      child: imageUrl == null
                          ? Icon(Icons.person,
                              color: Colors.blue.shade700, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'আপনার অ্যাম্বুলেন্স চালক',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 14),

              // Trip details container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  children: [
                    _buildTripDetailRow(
                        Icons.location_on,
                        Colors.red.shade400,
                        'পিকআপ লোকেশন',
                        controller.orderData.value?['pickupAddress'] ??
                            'লোকেশন পাওয়া যায়নি'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _buildTripDetailRow(
                        Icons.flag,
                        Colors.green.shade600,
                        'গন্তব্য',
                        controller.orderData.value?['destinationAddress'] ??
                            'গন্তব্য সেট করা নেই'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Fare Info
              Obx(() {
                final orderData = controller.orderData.value;
                final rawFare = orderData?['fareAmount'];
                final fare = (rawFare != null && rawFare != 0)
                    ? rawFare
                    : (orderData?['confirmedFare'] ??
                        orderData?['counterFare'] ??
                        orderData?['negotiation']?['counterFare'] ??
                        '---');

                String toBengaliDigits(String input) {
                  const english = [
                    '0',
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9'
                  ];
                  const bengali = [
                    '০',
                    '১',
                    '২',
                    '৩',
                    '৪',
                    '৫',
                    '৬',
                    '৭',
                    '৮',
                    '৯'
                  ];
                  for (int i = 0; i < english.length; i++) {
                    input = input.replaceAll(english[i], bengali[i]);
                  }
                  return input;
                }

                // Dynamic Status Mapping
                String getStatusText(String? status) {
                  switch (status?.toLowerCase()) {
                    case 'accepted':
                    case 'in_transit':
                      return 'অ্যাম্বুলেন্স আসছে';
                    case 'pickup':
                      return 'পিকআপ সম্পন্ন';
                    case 'to_destination':
                      return 'গন্তব্যের দিকে';
                    case 'completed':
                      return 'সম্পন্ন';
                    case 'cancelled':
                      return 'বাতিল';
                    default:
                      return 'নিশ্চিত';
                  }
                }

                Color getStatusColor(String? status) {
                  switch (status?.toLowerCase()) {
                    case 'accepted':
                    case 'in_transit':
                      return Colors.blue.shade100;
                    case 'pickup':
                      return Colors.orange.shade100;
                    case 'to_destination':
                      return Colors.green.shade100;
                    case 'completed':
                      return Colors.teal.shade100;
                    case 'cancelled':
                      return Colors.red.shade100;
                    default:
                      return Colors.green.shade100;
                  }
                }

                Color getStatusTextColor(String? status) {
                  switch (status?.toLowerCase()) {
                    case 'accepted':
                    case 'in_transit':
                      return Colors.blue.shade800;
                    case 'pickup':
                      return Colors.orange.shade800;
                    case 'to_destination':
                      return Colors.green.shade800;
                    case 'completed':
                      return Colors.teal.shade800;
                    case 'cancelled':
                      return Colors.red.shade800;
                    default:
                      return Colors.green.shade800;
                  }
                }

                final currentStatus =
                    orderData?['status'] ?? orderData?['orderStatus'];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'সার্ভিস চার্জ',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            fare != '---'
                                ? '৳${toBengaliDigits(fare.toString())}'
                                : '৳০',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: getStatusColor(currentStatus),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          getStatusText(currentStatus),
                          style: TextStyle(
                            color: getStatusTextColor(currentStatus),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripDetailRow(
      IconData icon, Color iconColor, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
