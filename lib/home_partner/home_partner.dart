import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_partner_controller.dart';

class HomePartnerPage extends StatelessWidget {
  const HomePartnerPage({super.key});

  // Ambulance-themed color palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color backgroundColor = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomePartnerController>(
      init: HomePartnerController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
         
            backgroundColor: primaryGreen,
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: controller.refreshData,
                tooltip: 'Refresh Data',
              ),
           
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                ),
              );
            }

            if (controller.partnerData.value == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Partner profile not found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please complete your registration',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: controller.navigateToProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text('Complete Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                // Full-screen map as the bottom layer
                Positioned.fill(
                  child: _buildMapSection(controller),
                ),

                // Overlay the online toggle at the top (SafeArea)
                SafeArea(
                  child: _buildOnlineStatusSection(controller),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  
  Widget _buildOnlineStatusSection(HomePartnerController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Make the card background transparent so the map is visible underneath
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                controller.isOnline.value ? Icons.online_prediction : Icons.offline_bolt,
                color: controller.isOnline.value ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isOnline.value ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: controller.isOnline.value ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    controller.isOnline.value
                        ? 'Available for emergency calls'
                        : 'Not accepting new orders',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: controller.isOnline.value,
            onChanged: (value) => controller.toggleOnlineStatus(),
            activeColor: primaryGreen,
            activeTrackColor: accentGreen,
          ),
        ],
      ),
    );
  }

  

  Widget _buildMapSection(HomePartnerController controller) {
    return Obx(() {
      if (controller.currentPosition.value == null) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'Location not available',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            controller.currentPosition.value!.latitude,
            controller.currentPosition.value!.longitude,
          ),
          zoom: 15,
        ),
        onMapCreated: controller.onMapCreated,
        markers: controller.markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      );
    });
  }




}
