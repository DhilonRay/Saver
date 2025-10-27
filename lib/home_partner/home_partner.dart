import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'home_partner_controller.dart';
import '../ambulance_request/ambulance_request_page.dart';

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
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    return GetBuilder<HomePartnerController>(
      init: HomePartnerController(),
      builder: (controller) {
        return Scaffold(
          key: scaffoldKey,
          backgroundColor: backgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
            ),
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
                // Debug controls (only in debug mode)
                if (kDebugMode) Positioned(
                  bottom: 120,
                  left: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        onPressed: () {
                          if (controller.isAnimating.value) {
                            controller.isAnimating.value = false;
                          } else {
                            controller.startRouteAnimation();
                          }
                        },
                        backgroundColor: Colors.deepOrange,
                        child: Obx(() => Icon(controller.isAnimating.value ? Icons.pause : Icons.directions_car)),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        onPressed: () {
                          // Force a few emulator geo fixes guide in logs
                          Get.snackbar('Debug', 'Use adb emu geo fix to simulate movement', duration: const Duration(seconds: 2));
                        },
                        backgroundColor: Colors.blueGrey,
                        child: const Icon(Icons.info_outline),
                      ),
                    ],
                  ),
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
          drawer: Drawer(
            child: Builder(
              builder: (context) => ListView(
                padding: EdgeInsets.zero,
                children: [
                DrawerHeader(
                 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.partnerData.value?['name'] ?? 'Name',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.partnerData.value?['email'] ?? 'Email',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.partnerData.value?['address'] ?? 'Address',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Order Dashboard'),
                    onTap: () {
                      // TODO: Navigate to Order Dashboard
                      Navigator.of(context).pop(); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_shipping),
                    title: const Text('Ambulance Requests'),
                    onTap: () {
                      Navigator.of(context).pop(); // Close the drawer
                      Get.to(() => const AmbulanceRequestPage());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_circle),
                    title: const Text('Profile'),
                    onTap: () {
                      // TODO: Navigate to Profile
                      Navigator.of(context).pop(); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Earnings'),
                    onTap: () {
                      // TODO: Navigate to Earnings
                      Navigator.of(context).pop(); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      // TODO: Navigate to Settings
                      Navigator.of(context).pop(); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    onTap: () {
                      
                      Navigator.of(context).pop(); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      controller.logout();
                    },
                  ),
                  // Add more menu items here as needed
                ],
              ),
            ),
          ),
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
        markers: controller.markers.value,
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
