import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'partner_details_controller.dart';

class PartnerDetailsPage extends StatelessWidget {
  const PartnerDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PartnerDetailsController>(
      init: PartnerDetailsController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ambulance Details'),
            centerTitle: true,
            backgroundColor: const Color(0xFF1976D2),
            elevation: 0,
         
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ambulance-themed loader
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated ambulance icon
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(seconds: 2),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(20 * (value - 0.5) * 2, 0),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: const Color(0xFF1976D2),
                                  size: 50,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // Pulsing dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.3, end: 1.0),
                                duration: Duration(milliseconds: 600 + (index * 200)),
                                builder: (context, value, child) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Color.lerp(
                                        Colors.blue.shade200,
                                        const Color(0xFF1976D2),
                                        value,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Loading Ambulance Details...',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (controller.errorMessage.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.loadPartnerDetails,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            if (controller.partnerDetails.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.grey,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No ambulance details found',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please complete your partner registration',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final data = controller.partnerDetails;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                 

                  const SizedBox(height: 30),

                  // Details Cards
                  _buildDetailCard(
                    'Vehicle Information',
                    [
                      _buildDetailRow('Vehicle Number', data['vehicleNumber'] ?? 'Not provided'),
                      _buildDetailRow('Ambulance Type', data['ambulanceType'] ?? 'Not provided'),
                    ],
                    Icons.directions_car,
                    controller,
                    onEdit: () => _showVehicleEditDialog(context, controller, data),
                  ),

                  const SizedBox(height: 20),

                  _buildDetailCard(
                    'License & Contact',
                    [
                      _buildDetailRow('Driver License', data['licenseNumber'] ?? 'Not provided'),
                      _buildDetailRow('Contact Number', data['contact'] ?? 'Not provided'),
                    ],
                    Icons.badge,
                    controller,
                    onEdit: () => _showLicenseEditDialog(context, controller, data),
                  ),

                  const SizedBox(height: 20),

                  _buildDetailCard(
                    'Service Area',
                    [
                      _buildDetailRow('Coverage Area', data['coverageArea'] ?? 'Not provided'),
                    ],
                    Icons.location_on,
                    controller,
                    onEdit: () => _showServiceAreaEditDialog(context, controller, data),
                  ),

                  const SizedBox(height: 20),

                  _buildDetailCard(
                    'Business Information',
                    [
                      _buildDetailRow('Company Name', data['companyName'] ?? 'Not provided'),
                    ],
                    Icons.business,
                    controller,
                    onEdit: () => _showBusinessEditDialog(context, controller, data),
                  ),

                  const SizedBox(height: 20),

                  _buildDetailCard(
                    'Registration Info',
                    [
                      _buildDetailRow(
                        'Registration Date',
                        controller.formatTimestamp(data['createdAt']),
                      ),
                    ],
                    Icons.calendar_today,
                    controller,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDetailCard(String title, List<Widget> details, IconData icon, PartnerDetailsController controller, {VoidCallback? onEdit}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF1976D2),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: Icon(
                      controller.isUpdating.value ? Icons.hourglass_empty : Icons.edit,
                      color: controller.isUpdating.value ? Colors.grey : const Color(0xFF1976D2),
                      size: 24,
                    ),
                    onPressed: controller.isUpdating.value ? null : onEdit,
                    tooltip: controller.isUpdating.value ? 'Updating...' : 'Edit $title',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceLoader({double size = 20}) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          return CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.lerp(Colors.blue.shade300, const Color(0xFF1976D2), value)!,
            ),
          );
        },
      ),
    );
  }

  void _showVehicleEditDialog(BuildContext context, PartnerDetailsController controller, Map<String, dynamic> data) {
    final vehicleNumberController = TextEditingController(text: data['vehicleNumber'] ?? '');
    final ambulanceTypeController = TextEditingController(text: data['ambulanceType'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vehicle Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: vehicleNumberController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Number',
                hintText: 'Enter vehicle number',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ambulanceTypeController,
              decoration: const InputDecoration(
                labelText: 'Ambulance Type',
                hintText: 'AC/Non-AC',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: controller.isUpdating.value
                ? null
                : () async {
                    if (vehicleNumberController.text.trim().isEmpty ||
                        ambulanceTypeController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please fill in all fields',
                        backgroundColor: Colors.red[600],
                        colorText: Colors.white,
                      );
                      return;
                    }

                    // Close dialog immediately for optimistic update
                    if (context.mounted) Navigator.of(context).pop();

                    // Show immediate success feedback
                    Get.snackbar(
                      'Success',
                      'Vehicle information updated successfully',
                      backgroundColor: Colors.green[600],
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );

                    // Perform background sync
                    final success = await controller.updateVehicleInfo(
                      vehicleNumberController.text,
                      ambulanceTypeController.text,
                    );

                    // Show error only if background sync failed
                    if (!success) {
                      Get.snackbar(
                        'Sync Error',
                        'Changes saved locally but failed to sync. Please check connection.',
                        backgroundColor: Colors.orange[600],
                        colorText: Colors.white,
                        duration: const Duration(seconds: 4),
                      );
                    }
                  },
            child: controller.isUpdating.value
                ? _buildAmbulanceLoader()
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLicenseEditDialog(BuildContext context, PartnerDetailsController controller, Map<String, dynamic> data) {
    final licenseController = TextEditingController(text: data['licenseNumber'] ?? '');
    final contactController = TextEditingController(text: data['contact'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit License & Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: licenseController,
              decoration: const InputDecoration(
                labelText: 'Driver License Number',
                hintText: 'Enter license number',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                hintText: 'Enter contact number',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: controller.isUpdating.value
                ? null
                : () async {
                    if (licenseController.text.trim().isEmpty ||
                        contactController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please fill in all fields',
                        backgroundColor: Colors.red[600],
                        colorText: Colors.white,
                      );
                      return;
                    }

                    // Close dialog immediately for optimistic update
                    if (context.mounted) Navigator.of(context).pop();

                    // Show immediate success feedback
                    Get.snackbar(
                      'Success',
                      'License & contact information updated successfully',
                      backgroundColor: Colors.green[600],
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );

                    // Perform background sync
                    final success = await controller.updateLicenseInfo(
                      licenseController.text,
                      contactController.text,
                    );

                    // Show error only if background sync failed
                    if (!success) {
                      Get.snackbar(
                        'Sync Error',
                        'Changes saved locally but failed to sync. Please check connection.',
                        backgroundColor: Colors.orange[600],
                        colorText: Colors.white,
                        duration: const Duration(seconds: 4),
                      );
                    }
                  },
            child: controller.isUpdating.value
                ? _buildAmbulanceLoader()
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showServiceAreaEditDialog(BuildContext context, PartnerDetailsController controller, Map<String, dynamic> data) {
    final coverageAreaController = TextEditingController(text: data['coverageArea'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Service Area'),
        content: TextField(
          controller: coverageAreaController,
          decoration: const InputDecoration(
            labelText: 'Coverage Area',
            hintText: 'Enter service area',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: controller.isUpdating.value
                ? null
                : () async {
                    if (coverageAreaController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please enter coverage area',
                        backgroundColor: Colors.red[600],
                        colorText: Colors.white,
                      );
                      return;
                    }

                    // Close dialog immediately for optimistic update
                    if (context.mounted) Navigator.of(context).pop();

                    // Show immediate success feedback
                    Get.snackbar(
                      'Success',
                      'Service area updated successfully',
                      backgroundColor: Colors.green[600],
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );

                    // Perform background sync
                    final success = await controller.updateServiceArea(
                      coverageAreaController.text,
                    );

                    // Show error only if background sync failed
                    if (!success) {
                      Get.snackbar(
                        'Sync Error',
                        'Changes saved locally but failed to sync. Please check connection.',
                        backgroundColor: Colors.orange[600],
                        colorText: Colors.white,
                        duration: const Duration(seconds: 4),
                      );
                    }
                  },
            child: controller.isUpdating.value
                ? _buildAmbulanceLoader()
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBusinessEditDialog(BuildContext context, PartnerDetailsController controller, Map<String, dynamic> data) {
    final companyNameController = TextEditingController(text: data['companyName'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Business Information'),
        content: TextField(
          controller: companyNameController,
          decoration: const InputDecoration(
            labelText: 'Company Name',
            hintText: 'Enter company name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: controller.isUpdating.value
                ? null
                : () async {
                    if (companyNameController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Please enter company name',
                        backgroundColor: Colors.red[600],
                        colorText: Colors.white,
                      );
                      return;
                    }

                    // Close dialog immediately for optimistic update
                    if (context.mounted) Navigator.of(context).pop();

                    // Show immediate success feedback
                    Get.snackbar(
                      'Success',
                      'Business information updated successfully',
                      backgroundColor: Colors.green[600],
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );

                    // Perform background sync
                    final success = await controller.updateBusinessInfo(
                      companyNameController.text,
                    );

                    // Show error only if background sync failed
                    if (!success) {
                      Get.snackbar(
                        'Sync Error',
                        'Changes saved locally but failed to sync. Please check connection.',
                        backgroundColor: Colors.orange[600],
                        colorText: Colors.white,
                        duration: const Duration(seconds: 4),
                      );
                    }
                  },
            child: controller.isUpdating.value
                ? _buildAmbulanceLoader()
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}