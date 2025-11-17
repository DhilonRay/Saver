import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_partner_controller.dart';
import '../partner_notification/partner_notification.dart';
import '../partner_notification/partner_notification_controller.dart';
import '../../loader/loader.dart';

class HomePartnerPage extends StatelessWidget {
  final bool isNewSignup;

  HomePartnerPage({super.key, this.isNewSignup = false});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Enhanced medical-themed color palette
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    // Initialize PartnerNotificationController if not already initialized
    if (!Get.isRegistered<PartnerNotificationController>()) {
      Get.put(PartnerNotificationController());
    }

    return GetBuilder<HomePartnerController>(
      init: HomePartnerController(isNewSignup: isNewSignup),
      builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [lightBlue, Colors.white],
            ),
          ),
          child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Obx(() => Text(
                    controller.partnerName.value,
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: primaryBlue,
                  size: 28,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
               
                IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: primaryBlue,
                    size: 28,
                  ),
                  onPressed: () {
                    Get.to(() => const PartnerNotificationPage());
                  },
                ),
              ],
            ),
            drawer: Drawer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [lightBlue, Colors.white],
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 20, bottom: 30),
                      child: Column(
                        children: [
                          // Profile Image with Upload Functionality
                          GestureDetector(
                            onTap: controller.showProfileImageOptions,
                            child: Obx(() {
                              final imageUrl = controller.profileImageUrl.value;
                              final isUploading =
                                  controller.isUploadingImage.value;
                              final progress = controller.uploadProgress.value;

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color:
                                            primaryBlue.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                      image: imageUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(imageUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: imageUrl == null
                                        ? Icon(
                                            Icons.local_shipping,
                                            color: primaryBlue,
                                            size: 40,
                                          )
                                        : null,
                                  ),
                                  if (isUploading)
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Colors.black.withValues(alpha: 0.7),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: CircularProgressIndicator(
                                              value: progress > 0
                                                  ? progress
                                                  : null, // Show progress if available
                                              color: Colors.white,
                                              strokeWidth: 2,
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          if (progress > 0)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                '${(progress * 100).toInt()}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: primaryBlue,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                          SizedBox(height: 16),
                          Obx(() => Text(
                                controller.partnerName.value,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                          Text(
                            'Emergency Response',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryBlue.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: 8),
                          Obx(() => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: controller.isOnline.value 
                                  ? Colors.green.shade50 
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: controller.isOnline.value 
                                    ? Colors.green.shade300 
                                    : Colors.orange.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: controller.isOnline.value 
                                        ? Colors.green.shade600 
                                        : Colors.orange.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  controller.isOnline.value ? 'অনলাইন' : 'অফলাইন',
                                  style: TextStyle(
                                    color: controller.isOnline.value 
                                        ? Colors.green.shade700 
                                        : Colors.orange.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(height: 20),
                          _buildDrawerItem(
                            icon: Icons.assignment_ind_outlined,
                            title: 'My Orders',
                            onTap: controller.navigateToPartnersOrders,
                          ),
                          Obx(() => _buildDrawerItem(
                            icon: controller.isOnline.value 
                                ? Icons.toggle_on_rounded 
                                : Icons.toggle_off_rounded,
                            title: controller.isOnline.value ? 'Go Offline' : 'Go Online',
                            onTap: controller.toggleOnlineStatus,
                            iconColor: controller.isOnline.value 
                                ? Colors.green.shade600 
                                : Colors.orange.shade600,
                          )),
                          _buildDrawerItem(
                            icon: Icons.person,
                            title: 'Profile',
                            onTap: () {
                              /* // Close the drawer and navigate to Profile page
                              try {
                                Get.back();
                              } catch (_) {} */
                              Get.toNamed('/partner-profile');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.attach_money,
                            title: 'Change Rates',
                            onTap: () {
                              /*   // Close the drawer and show rate change dialog
                              try {
                                Get.back();
                              } catch (_) {} */
                              controller.showRateChangeDialog();
                            },
                          ),
                          Divider(height: 40, thickness: 1),
                          _buildDrawerItem(
                            icon: Icons.info_outline,
                            title: 'About Us',
                            onTap: controller.navigateToAboutUs,
                          ),
                          _buildDrawerItem(
                            icon: Icons.privacy_tip,
                            title: 'Privacy Policy',
                            onTap: () {
                              /*   // Close the drawer and navigate to Privacy Policy page
                              try {
                                Get.back();
                              } catch (_) {} */
                              Get.toNamed('/privacy-policy');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.description,
                            title: 'Terms & Conditions',
                            onTap: () {
                              /*  // Close the drawer and navigate to Terms & Conditions page
                              try {
                                Get.back();
                              } catch (_) {} */
                              Get.toNamed('/terms-conditions');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.feedback_outlined,
                            title: 'Feedback',
                            onTap: () {
                              /* // Close the drawer and navigate to Feedback page
                              try {
                                Get.back();
                              } catch (_) {} */
                              Get.toNamed('/feedback');
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.signOut,
                          icon:
                              Icon(Icons.logout, color: primaryBlue, size: 24),
                          label: Text(
                            'Sign Out',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            shadowColor: Colors.blue.shade100,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: Stack(
              children: [
                // Full screen map as background
                Obx(() {
                  if (controller.currentPosition.value == null) {
                    return Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HorizontalRotatingDots(
                              size: 56,
                              colors: [primaryBlue, secondaryBlue, accentBlue],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: controller.currentPosition.value!,
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

                // Overlay controls on top of map
                SafeArea(
                  child: Stack(
                    children: [
                      // Online/Offline Toggle Button
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Obx(() => GestureDetector(
                            onTap: controller.toggleOnlineStatus,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                 
                                 
                                  Text(
                                    controller.isOnline.value ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color: controller.isOnline.value 
                                          ? Colors.green.shade700 
                                          : Colors.orange.shade700,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    controller.isOnline.value 
                                        ? Icons.toggle_on_rounded 
                                        : Icons.toggle_off_rounded,
                                    color: controller.isOnline.value 
                                        ? Colors.green.shade600 
                                        : Colors.grey.shade500,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ),
                      ),

                      // Status Information Card (Bottom Left)
                      Positioned(
                        left: 16,
                        bottom: 20,
                        child: Obx(() => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    controller.isOnline.value 
                                        ? Icons.radio_button_checked 
                                        : Icons.radio_button_unchecked,
                                    color: controller.isOnline.value 
                                        ? Colors.green.shade600 
                                        : Colors.grey.shade500,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'স্থিতি',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                controller.isOnline.value 
                                    ? 'রোগীরা আপনার অ্যাম্বুলেন্স দেখতে পারছে'
                                    : 'রোগীরা আপনার অ্যাম্বুলেন্স দেখতে পারছে না',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: controller.isOnline.value 
                                      ? Colors.green.shade700 
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ),

                      // Zoom controls positioned on the right side
                      Positioned(
                        right: 16,
                        bottom: 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Zoom In Button
                            Container(
                              width: 48,
                              height: 48,
                              margin: EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: controller.zoomIn,
                                icon: Icon(
                                  Icons.add,
                                  color: primaryBlue,
                                  size: 24,
                                ),
                                tooltip: 'Zoom In',
                              ),
                            ),

                            // Zoom Out Button
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: controller.zoomOut,
                                icon: Icon(
                                  Icons.remove,
                                  color: primaryBlue,
                                  size: 24,
                                ),
                                tooltip: 'Zoom Out',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? primaryBlue,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.blueGrey.shade800,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
