import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Enhanced medical-themed color palette
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            
          ),
          child: Scaffold(
            key: _scaffoldKey,
            
            appBar: AppBar(
              
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: primaryBlue,
                  size: 28,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            drawer: Drawer(
              child: Container(
                decoration: BoxDecoration(
                  
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
                             
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shield,
                              color: Colors.blueGrey,
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'NeoSaver',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Every Second Matters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey.withValues(alpha: 0.8),
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
                            icon: Icons.person_outline,
                            title: 'User Profile',
                            onTap: controller.navigateToUserId,
                          ),
                          _buildDrawerItem(
                            icon: Icons.assignment_ind_outlined,
                            title: 'Partner Orders',
                            onTap: controller.navigateToPartnersOrders,
                          ),
                          _buildDrawerItem(
                            icon: Icons.assignment_outlined,
                            title: 'Your Orders',
                            onTap: controller.navigateToUserOrders,
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
                    polylines: controller.polylines.toSet(),
                    onMapCreated: controller.onMapCreated,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  );
                }),

                // Overlay controls on top of map
                SafeArea(
                  child: Column(
                    children: [
                   
                      // Destination input container
                      Container(
                        margin: EdgeInsets.all(16),

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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: TextField(
                                controller: controller.destinationController,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade800,
                                  fontSize: 16,
                                ),
                                onChanged: controller.onDestinationTextChanged,
                                decoration: InputDecoration(
                                  hintText: 'Enter destination',
                                  hintStyle: TextStyle(
                                    color: Colors.blueGrey.shade400,
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Container(
                                    margin: EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      color: primaryBlue,
                                      size: 24,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: primaryBlue,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),

                            // Autocomplete suggestions - show only when user has typed something
                            Obx(() {
                              final query = controller.destinationQuery.value.trim();
                              // Do not show suggestions when the input is empty
                              final showSuggestions = query.isNotEmpty && (controller.placeSuggestions.isNotEmpty || controller.isLoadingSuggestions.value);

                              if (!showSuggestions) {
                                return SizedBox.shrink();
                              }

                              return Container(
                                margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                constraints: BoxConstraints(
                                  maxHeight: 300, // Limit height to prevent overflow
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: controller.isLoadingSuggestions.value
                                  ? Container(
                                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                primaryBlue
                                              ),
                                            ),
                                          ),
                                       
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      physics: ClampingScrollPhysics(), // Prevent scroll conflicts
                                      itemCount: controller.placeSuggestions.length > 5
                                          ? 5 // Limit to 5 suggestions to prevent overflow
                                          : controller.placeSuggestions.length,
                                      itemBuilder: (context, index) {
                                        final place = controller.placeSuggestions[index];
                                        return InkWell(
                                          onTap: () => controller.selectPlace(place),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                            decoration: BoxDecoration(
                                              border: index < (controller.placeSuggestions.length > 5 ? 4 : controller.placeSuggestions.length - 1)
                                                ? Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))
                                                : null,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: lightBlue,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.location_on_outlined,
                                                    size: 20,
                                                    color: primaryBlue,
                                                  ),
                                                ),
                                                SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        place['name']?.toString() ?? 'Unknown Place',
                                                        style: TextStyle(
                                                          color: Colors.blueGrey.shade800,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (place['formattedAddress'] != null && (place['formattedAddress'] as String?)?.isNotEmpty == true)
                                                        Padding(
                                                          padding: EdgeInsets.only(top: 2),
                                                          child: Text(
                                                            place['formattedAddress']?.toString() ?? '',
                                                            style: TextStyle(
                                                              color: Colors.blueGrey.shade500,
                                                              fontSize: 12,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: Colors.grey.shade400,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              );
                            }),

                            
                          ],
                        ),
                      ),

                      // Spacer to push floating buttons to bottom
                      Expanded(child: SizedBox()),
                    

                      // Emergency action buttons at bottom
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.symmetric(vertical: 8),
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
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEmergencyButton(
                              icon: Icons.local_hospital,
                              label: 'Ambulance',
                              color: Colors.green.shade600,
                              onPressed: controller.navigateToAmbulanceServices,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade200,
                            ),
                            _buildEmergencyButton(
                              icon: Icons.chat_bubble,
                              label: 'SOS Chat',
                              color: primaryBlue,
                              onPressed: controller.navigateToSOSChat,
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

  Widget _buildEmergencyButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric( horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}