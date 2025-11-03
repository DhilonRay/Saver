import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'partner_profile_controller.dart';

class PartnerProfilePage extends StatelessWidget {
  const PartnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PartnerProfileController>(
      init: PartnerProfileController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Partner Profile'),
            centerTitle: true,
           
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingWidget('Loading Partner Profile...');
            }
            if (controller.errorMessage.value.isNotEmpty) {
              return Center(child: Text(controller.errorMessage.value));
            }
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildEditableField('Name', controller.nameController, Icons.person),
                        _buildEditableField('Email', controller.emailController, Icons.email),
                        _buildEditableField('Phone', controller.phoneController, Icons.phone),
                        _buildEditableField('Address', controller.addressController, Icons.location_on),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isUpdating.value ? null : controller.updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isUpdating.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextFormField(
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
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(String message) {
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
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF1976D2),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
