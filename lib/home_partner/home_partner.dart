import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_partner_controller.dart';

class HomePartnerPage extends StatelessWidget {
  HomePartnerPage({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Enhanced medical-themed color palette
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomePartnerController>(
      init: HomePartnerController(),
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
              title: Text(
                'NeoSaver Partner',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
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
                    // Handle notifications
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
                      padding: const EdgeInsets.only(top: 50, bottom: 30),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade200,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_shipping,
                              color: primaryBlue,
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'NeoSaver Partner',
                            style: TextStyle(
                              fontSize: 24,
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Emergency Response',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryBlue.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
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
                          _buildDrawerItem(
                            icon: Icons.info_outline,
                            title: 'About Us',
                            onTap: controller.navigateToAboutUs,
                          ),
                          Divider(height: 40, thickness: 1),
                          _buildDrawerItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            onTap: () {},
                          ),
                          _buildDrawerItem(
                            icon: Icons.feedback_outlined,
                            title: 'Feedback',
                            onTap: () {},
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
                          icon: Icon(Icons.logout, color: primaryBlue, size: 24),
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
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
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
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Locating your ambulance...',
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
                      // Status indicator
                      Positioned(
                        top: 0,
                        left: 16,
                        right: 16,
                        child: Container(
                          margin: EdgeInsets.only(top: 16),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Online',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                color: primaryBlue,
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
