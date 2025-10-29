import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'accept_maps_controller.dart';

class AcceptMapsPage extends StatelessWidget {
  AcceptMapsPage({super.key});

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
                minHeight: 200,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
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
      ),
      child: Column(
        children: [
          // Panel header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Ride details
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      'Ride in Progress',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  SizedBox(height: 8),

                  // Request ID (for debugging/verification)
                  Text(
                    'Request ID: ${controller.requestData.value?['id'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),

                  SizedBox(height: 20),

                  // Patient info
                  Text(
                    'Patient Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 12),

                  _buildDetailRow(
                    icon: Icons.person,
                    title: 'Name',
                    value: controller.requestData.value?['patientName'] ?? 'Name not provided',
                  ),

                  _buildDetailRow(
                    icon: Icons.phone,
                    title: 'Phone',
                    value: controller.requestData.value?['phone'] ?? 'Phone not provided',
                  ),

                  _buildDetailRow(
                    icon: Icons.location_on,
                    title: 'Pickup Location',
                    value: controller.requestData.value?['pickupAddress'] ?? 'Address not provided',
                  ),

                  if (controller.requestData.value?['email'] != null &&
                      controller.requestData.value!['email'].toString().isNotEmpty) ...[
                    SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.email,
                      title: 'Email',
                      value: controller.requestData.value!['email'],
                    ),
                  ],

                  if (controller.requestData.value?['notes'] != null &&
                      controller.requestData.value!['notes'].toString().isNotEmpty) ...[
                    SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.note,
                      title: 'Notes',
                      value: controller.requestData.value!['notes'],
                    ),
                  ],

                  SizedBox(height: 24),

                  // Emergency contact section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emergency,
                          color: primaryGreen,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Contact',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryGreen,
                                ),
                              ),
                              Text(
                                'Call emergency services if needed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Call emergency number
                          },
                          icon: Icon(
                            Icons.call,
                            color: primaryGreen,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Complete ride button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.completeRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Complete Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Cancel ride button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Show cancel confirmation dialog
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
                                  controller.goBack();
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
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        foregroundColor: Colors.red.shade600,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
