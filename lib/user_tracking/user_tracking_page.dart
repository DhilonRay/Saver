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
          appBar: AppBar(
            title: Text(
              'Ambulance Tracking',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.blue.shade700,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: controller.goBack,
            ),
            actions: [
              // Zoom controls
              IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: controller.zoomIn,
                tooltip: 'Zoom In',
              ),
              IconButton(
                icon: Icon(Icons.remove, color: Colors.white),
                onPressed: controller.zoomOut,
                tooltip: 'Zoom Out',
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading location...',
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
                    target: controller.userPosition.value ?? UserTrackingController.defaultPosition,
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

              // ETA and Status Information Panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildInfoPanel(controller),
              ),

              // Loading overlay for ETA calculation
              Obx(() {
                if (controller.isCalculatingETA.value) {
                  return Positioned(
                    top: 100,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Calculating time...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoPanel(UserTrackingController controller) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final orderData = controller.orderData.value;
                        final status = orderData?['orderStatus'] ?? orderData?['status'] ?? 'unknown';
                        final isCompleted = status.toLowerCase() == 'completed';

                        return Text(
                          isCompleted ? 'Service Completed' : 'Ambulance is Coming',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }),
                      Obx(() {
                        final orderData = controller.orderData.value;
                        final status = orderData?['orderStatus'] ?? orderData?['status'] ?? 'unknown';
                        final isCompleted = status.toLowerCase() == 'completed';

                        if (isCompleted) {
                          return Text(
                            'Thank you for using our service',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          );
                        } else {
                          return Text(
                            'Hold your location',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
                Obx(() {
                  final orderData = controller.orderData.value;
                  final status = orderData?['orderStatus'] ?? orderData?['status'] ?? 'unknown';
                  final isCompleted = status.toLowerCase() == 'completed';

                  if (isCompleted) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'DONE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 8,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }),
              ],
            ),
          ),

          // ETA Information (only show if not completed)
          Obx(() {
            final orderData = controller.orderData.value;
            final status = orderData?['orderStatus'] ?? orderData?['status'] ?? 'unknown';
            final isCompleted = status.toLowerCase() == 'completed';

            if (isCompleted) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your ambulance service has been completed successfully. Thank you for choosing our service!',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Time Information
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimated Time',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Obx(() => Text(
                                    controller.estimatedTime.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

                    // Distance Information
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Distance',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Obx(() => Text(
                                    controller.estimatedDistance.value > 0
                                      ? '${controller.estimatedDistance.value.toStringAsFixed(1)} km'
                                      : '-- km',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )),
                                ],
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
          }),

          // Status Information
          Obx(() {
            final orderData = controller.orderData.value;
            if (orderData != null) {
              final status = orderData['orderStatus'] ?? orderData['status'] ?? 'unknown';
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Order ID: ${controller.orderId.value?.substring(0, 8) ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'in_transit':
        return Icons.local_shipping;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue.shade600;
      case 'in_transit':
        return Colors.orange.shade600;
      case 'completed':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Ambulance Accepted';
      case 'in_transit':
        return 'Delivering On the Way';
      case 'completed':
        return 'Service Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Status: $status';
    }
  }
}