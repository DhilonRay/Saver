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
         
       
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blueGrey),
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
                // Online toggle container
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildOnlineToggle(controller),
                ),
              ],
            );
          }),
          floatingActionButton: Obx(() {
            if (controller.isServiceActive.value && !controller.isDrivingStarted.value) {
              return FloatingActionButton.extended(
                onPressed: controller.startDriving,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Driving'),
              );
            } else if (controller.isDrivingStarted.value) {
              return FloatingActionButton.extended(
                onPressed: controller.completeActiveService,
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.check_circle),
                label: const Text('Complete Service'),
              );
            }
            return const SizedBox.shrink();
          }),
        );
      },
    );
  }

  
 

  

  Widget _buildMapSection(HomePartnerController controller) {
    return Obx(() {
      if (controller.currentPosition.value == null) {
        return Container(
          color: Colors.grey.shade200,
          
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
        polylines: controller.polylines.toSet(),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      );
    });
  }

  Widget _buildOnlineToggle(HomePartnerController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Switch(
            value: controller.isOnline.value,
            onChanged: (value) => controller.toggleOnlineStatus(),
            activeThumbColor: primaryGreen,
            activeTrackColor: secondaryGreen.withValues(alpha: 0.5),
          )),
          const SizedBox(width: 8),
          Obx(() => Text(
            controller.isOnline.value ? 'Online' : 'Offline',
            style: TextStyle(
              color: controller.isOnline.value ? primaryGreen : Colors.grey,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          )),
        ],
      ),
    );
  }
}
