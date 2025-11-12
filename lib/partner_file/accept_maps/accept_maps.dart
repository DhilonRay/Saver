import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'accept_maps_controller.dart';

class AcceptMapsPage extends StatelessWidget {
  const AcceptMapsPage({super.key});

  // Medical-themed color palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFFE8F5E8);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AcceptMapsController>(
      init: AcceptMapsController(),
      builder: (controller) {
        return Scaffold(
          body: Stack(
            children: [
              // Full screen map
              Obx(() {
                if (controller.isLoadingLocation.value) {
                  return Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Loading map...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: controller.partnerPosition.value ?? AcceptMapsController.defaultPosition,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: controller.markers.toSet(),
                  polylines: controller.polylines.toSet(),
                  onMapCreated: controller.onMapCreated,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                );
              }),

              // Back button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: controller.goBack,
                      icon: Icon(
                        Icons.arrow_back,
                        color: primaryGreen,
                        size: 24,
                      ),
                      tooltip: 'Back',
                    ),
                  ),
                ),
              ),

              // Zoom controls
              Positioned(
                right: 16,
                bottom: 120, // Above the slide panel
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: controller.zoomIn,
                        icon: Icon(
                          Icons.add,
                          color: primaryGreen,
                          size: 24,
                        ),
                        tooltip: 'Zoom In',
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: controller.zoomOut,
                        icon: Icon(
                          Icons.remove,
                          color: primaryGreen,
                          size: 24,
                        ),
                        tooltip: 'Zoom Out',
                      ),
                    ),
                  ],
                ),
              ),

              // Sliding panel with ride details
              SlidingUpPanel(
                minHeight: 100, // Reduced from 130
                maxHeight: MediaQuery.of(context).size.height * 0.49, // Reduced from 0.9
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                panelBuilder: (scrollController) => _buildSlidePanel(scrollController, controller),
                body: Container(), // Empty body since map is already full screen
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlidePanel(ScrollController scrollController, AcceptMapsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panel handle
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Compact content
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status and patient info in a compact card
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Status badge and patient name in one row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  color: primaryGreen,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'In Progress',
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Obx(() {
                            String statusText;
                            Color statusColor;
                            
                            if (controller.isLiveTracking.value) {
                              statusText = 'TRACKING';
                              statusColor = Colors.blue.shade600;
                            } else {
                              statusText = 'READY';
                              statusColor = primaryGreen;
                            }
                            
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),

                      SizedBox(height: 12),

                      // Patient name (prominent)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: primaryGreen,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.requestData.value?['patientName'] ?? 'Patient',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      // Phone and location in compact rows
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: Colors.grey.shade600,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.requestData.value?['phone'] ?? 'No phone',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 6),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              controller.formatAddress(controller.requestData.value?['pickupAddress']),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Live tracking indicator (compact)
                Obx(() {
                  if (controller.isLiveTracking.value) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.gps_fixed,
                            color: Colors.blue.shade600,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Live tracking active',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }),

                // Action buttons (compact)
                Row(
                  children: [
                    // Primary action button
                    Expanded(
                      child: Obx(() {
                        return ElevatedButton(
                          onPressed: controller.isLiveTracking.value
                              ? controller.completeRide
                              : controller.startLiveTracking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.isLiveTracking.value
                                ? Colors.orange.shade500
                                : primaryGreen,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            controller.isLiveTracking.value
                                ? 'Complete'
                                : 'Start Tracking',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    ),

                    SizedBox(width: 12),

                    // Cancel button (compact)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Get.dialog(
                            AlertDialog(
                              title: Text('Cancel Ride'),
                              content: Text('Are you sure you want to cancel this ride?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    controller.cancelRide();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: Text('Yes, Cancel'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        tooltip: 'Cancel Ride',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
