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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryGreen),
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
                    target: controller.partnerPosition.value ??
                        AcceptMapsController.defaultPosition,
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
              Obx(() {
                debugPrint('AcceptMaps UI: showSlidePanel.value = ${controller.showSlidePanel.value}');
                if (controller.showSlidePanel.value) {
                  debugPrint('AcceptMaps UI: Showing slide panel');
                  return SlidingUpPanel(
                    minHeight: 120,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    panelBuilder: (scrollController) =>
                        _buildSlidePanel(scrollController, controller),
                    body: Container(), // Empty body since map is already full screen
                  );
                } else {
                  debugPrint('AcceptMaps UI: Slide panel hidden');
                  return Container();
                }
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlidePanel(
      ScrollController scrollController, AcceptMapsController controller) {
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: statusColor.withOpacity(0.3)),
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
                              controller.requestData.value?['patientName'] ??
                                  'Patient',
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
                              controller.requestData.value?['phone'] ??
                                  'No phone',
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
                              controller.formatAddress(controller
                                  .requestData.value?['pickupAddress']),
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

                      // Destination information
                      if (controller.requestData.value?['destinationAddress'] !=
                              null &&
                          (controller.requestData.value?['destinationAddress']
                                  as String)
                              .isNotEmpty) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.purple.shade200, width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.flag,
                                color: Colors.purple.shade600,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'গন্তব্য',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade800,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      controller.requestData
                                              .value?['destinationAddress'] ??
                                          '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.purple.shade700,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ETA information
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.shade200, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.blue.shade600,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'আনুমানিক সময়',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Obx(() => Text(
                                        controller.estimatedTime.value,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            if (controller.estimatedDistance.value > 0) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Obx(() => Text(
                                      '${controller.estimatedDistance.value.toStringAsFixed(1)} km',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Fare information
                      SizedBox(height: 8),
                      Obx(() {
                        if (controller.serviceRate.value > 0) {
                          return Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.shade200, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  color: Colors.green.shade600,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Service Charge',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '৳${controller.serviceRate.value}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'RATE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      }),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Live tracking indicator (compact)
                Obx(() {
                  if (controller.isLiveTracking.value) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        final status = controller.requestData.value?['status'];
                        final isTracking = controller.isLiveTracking.value;
                        
                        debugPrint('Button logic - Status: $status, IsTracking: $isTracking');
                        
                        String buttonText;
                        VoidCallback onPressed;

                        if (status == 'in_transit') {
                          buttonText = 'Picked Up';
                          onPressed = () => _showPickupOTPDialog(controller);
                          debugPrint('Button: Picked Up (status is in_transit)');
                        } else if (status == 'pickup') {
                          buttonText = 'Go to Destination';
                          onPressed = () => controller.goToDestination();
                          debugPrint('Button: Go to Destination (status is pickup)');
                        } else if (status == 'to_destination') {
                          buttonText = 'Complete Ride';
                          onPressed = () => _showFareInputDialog(controller);
                          debugPrint('Button: Complete Ride (status is to_destination)');
                        } else if (isTracking) {
                          buttonText = 'Picked Up';
                          onPressed = () => _showPickupOTPDialog(controller);
                          debugPrint('Button: Picked Up (is tracking)');
                        } else {
                          buttonText = 'Started to tracking';
                          onPressed = controller.startLiveTracking;
                          debugPrint('Button: Started to tracking (default)');
                        }

                        return ElevatedButton(
                          onPressed: onPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: status == 'in_transit'
                                ? Colors.red.shade500
                                : status == 'pickup'
                                    ? Colors.purple.shade500
                                    : status == 'to_destination'
                                        ? Colors.teal.shade500
                                        : controller.isLiveTracking.value
                                            ? Colors.red.shade500
                                            : primaryGreen,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            buttonText,
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
                              content: Text(
                                  'Are you sure you want to cancel this ride?'),
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

  void _showFareInputDialog(AcceptMapsController controller) {
    final fareController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.receipt, color: primaryGreen),
                  SizedBox(width: 8),
                  Text('Complete Ride & Enter Fare'),
                ],
              ),
              SizedBox(height: 16),
              // Order Summary
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                        'Patient: ${controller.requestData.value?['patientName'] ?? 'Patient'}'),
                    Text(
                        'From: ${controller.formatAddress(controller.requestData.value?['pickupAddress'])}'),
                    if (controller.requestData.value?['destinationAddress'] !=
                        null)
                      Text(
                          'To: ${controller.requestData.value?['destinationAddress']}'),
                    Text(
                        'Distance: ${controller.estimatedDistance.value > 0 ? '${controller.estimatedDistance.value.toStringAsFixed(1)} km' : 'N/A'}'),
                    Text('Time: ${controller.estimatedTime.value}'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Fare Input
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Total Fare Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: fareController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Fare Amount (৳)',
                        hintText: 'Enter the total ride cost',
                        border: OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.attach_money, color: primaryGreen),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the fare amount';
                        }
                        final fare = double.tryParse(value);
                        if (fare == null || fare <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (fare < 500) {
                          return 'Minimum fare is ৳500';
                        }
                        if (fare > 50000) {
                          return 'Maximum fare is ৳50,000';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              /*  SizedBox(height: 16),
              // Fare Guidelines
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.amber.shade700, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Fare Guidelines',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Base fare: ৳500-৳2,000\n• Per km: ৳50-৳150\n• Emergency surcharge: +20-50%\n• Final amount should reflect actual service cost',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16), */
              Text(
                'This fare will be recorded in the ride history and visible to the user. Please ensure accuracy.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        side: BorderSide(color: Colors.red.shade300),
                        foregroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          final fare = double.parse(fareController.text);
                          Get.back();
                          controller.completeRide(fareAmount: fare);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade500,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('Complete Ride'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isDismissible: true,
    );
  }

  void _showPickupOTPDialog(AcceptMapsController controller) {
    final otpController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.security, color: primaryGreen),
                  SizedBox(width: 8),
                  Text('Pickup Verification'),
                ],
              ),
              /* SizedBox(height: 16),
              // Show Generated OTP
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Generated OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Obx(() {
                      final otp = controller.requestData.value?['pickupOTP'];
                      if (otp == null) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Generating OTP...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        );
                      }
                      return Text(
                        otp.toString(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          letterSpacing: 4,
                        ),
                      );
                    }),
                    SizedBox(height: 8),
                    Text(
                      'Share this OTP with the patient to confirm pickup',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ), */
              SizedBox(height: 16),
              Text(
                'Enter the OTP provided by the patient to confirm pickup.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              SizedBox(height: 16),
              // OTP Input
              Form(
                key: formKey,
                child: TextFormField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Enter Patient\'s OTP',
                    hintText: '0000',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the OTP';
                    }
                    if (value.length != 4) {
                      return 'OTP must be 4 digits';
                    }
                    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                      return 'OTP must contain only numbers';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        side: BorderSide(color: Colors.red.shade300),
                        foregroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          final success = await controller.confirmPickupOTP(otpController.text);
                          if (success) {
                            Get.back(); // Close dialog
                            Get.snackbar(
                              'Success',
                              'Pickup confirmed successfully!',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } else {
                            Get.snackbar(
                              'Error',
                              'Invalid OTP. Please try again.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade500,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('Confirm Pickup'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isDismissible: true,
    );

    // Generate and send OTP
    controller.generateAndSendPickupOTP();
  }
}
