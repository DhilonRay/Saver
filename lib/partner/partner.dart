import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'partner_controller.dart';
import '../loader/loader.dart';

class PartnerPage extends StatelessWidget {
  final String uid;
  const PartnerPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PartnerController>(
      init: PartnerController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text(
              "Ambulance Partner Details",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.blueGrey.shade800,
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: controller.clearForm,
                tooltip: 'Clear Form',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildTextField(controller.vehicleNumber, 'Vehicle Number *', Icons.airlines),
                const SizedBox(height: 12),
                _buildTextField(controller.licenseNumber, 'Driver License Number *', Icons.badge_outlined),
                const SizedBox(height: 12),
                _buildTextField(controller.ambulanceType, 'Ambulance Type (AC/Non-AC) *', Icons.local_hospital_outlined),
                const SizedBox(height: 12),
                _buildTextField(controller.coverageArea, 'Coverage Area *', Icons.map_outlined),
                const SizedBox(height: 12),
                _buildTextField(controller.contactNumberController, 'Contact Number *', Icons.phone_outlined),
                const SizedBox(height: 12),
                _buildTextField(controller.companyNameController, 'Company Name *', Icons.business_outlined),
                const SizedBox(height: 30),
                Obx(() {
                  return ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.savePartnerDetails(uid),
                    icon: controller.isLoading.value
                        ? HorizontalRotatingDots(size: 20, colors: [Colors.white, Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.6)])
                        : const Icon(Icons.save_outlined, color: Colors.white),
                    label: Text(
                      controller.isLoading.value ? "Saving..." : "Submit",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isLoading.value
                          ? Colors.grey
                          : Colors.teal.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.blueGrey.shade800),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey.shade600),
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.teal.shade600),
        ),
      ),
    );
  }
}