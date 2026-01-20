import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saver/feedback/feedback.dart';
import 'package:saver/loader/loader.dart';
import 'home_user_controller.dart';
import '../widgets/fares_widgets.dart';
import '../services/fares_service.dart';
import '../user_notification/user_notification.dart';
import '../user_notification/user_notification_controller.dart';
import '../chat_page/ai_chat_page.dart';

class HomePage extends StatelessWidget {
  final bool isNewSignup;

  HomePage({super.key, this.isNewSignup = false});

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
      init: HomeController(isNewSignup: isNewSignup),
      builder: (controller) {
        // Initialize UserNotificationController if not already initialized
        if (!Get.isRegistered<UserNotificationController>()) {
          Get.put(UserNotificationController());
        }

        return Container(
          decoration: BoxDecoration(),
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
              actions: [
                Obx(() {
                  final notificationController =
                      Get.find<UserNotificationController>();
                  return Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications,
                          color: primaryBlue,
                          size: 28,
                        ),
                        onPressed: () {
                          Get.to(() => const UserNotificationPage());
                        },
                      ),
                      if (notificationController.unreadCount.value > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              notificationController.unreadCount.value
                                  .toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
            drawer: Drawer(
              child: SafeArea(
                child: Column(
                  children: <Widget>[
                    // Header with Logo and Name
                    Container(
                      padding: const EdgeInsets.only(top: 30, bottom: 20),
                      child: Column(
                        children: [
                          // NeoSaver Logo
                          Image.asset(
                            'assets/images/neo.png',
                            width: 80,
                            height: 80,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryBlue.withValues(alpha: 0.1),
                                ),
                                child: Icon(
                                  Icons.local_hospital,
                                  color: primaryBlue,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16),
                          Obx(() => Text(
                                controller.userName.value,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.blueGrey.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                          SizedBox(height: 4),
                          Text(
                            'Emergency Response',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildDrawerItem(
                            imagePath: 'assets/images/profile.png',
                            icon: Icons.person_outline,
                            title: 'Profile',
                            onTap: controller.navigateToUserId,
                          ),
                          _buildDrawerItem(
                            imagePath: 'assets/images/trip.png',
                            icon: Icons.assignment_outlined,
                            title: 'Your Trip',
                            onTap: controller.navigateToUserOrders,
                          ),
                          _buildDrawerItem(
                            imagePath: 'assets/images/tracking.png',
                            icon: Icons.track_changes_outlined,
                            title: 'Tracking',
                            onTap: controller.navigateToTrackingPage,
                          ),

                          // AI Chat Assistant
                          _buildDrawerItem(
                            icon: Icons.smart_toy,
                            title: 'AI Assistant',
                            onTap: () {
                              Get.back();
                              Get.to(() => const AIChatPage());
                            },
                          ),

                          // Quick access: available/online ambulances (live list)
                          _buildDrawerItem(
                            imagePath: 'assets/images/availabeAmbulances.png',
                            icon: Icons.local_hospital,
                            title: 'Available Ambulances',
                            onTap: controller.navigateToAmbulanceServices,
                          ),

                          Obx(() {
                            final online = controller.onlineAmbulances;
                            if (online.isEmpty) return SizedBox.shrink();

                            // show up to 2 providers as quick links
                            final displayItems =
                                online.length > 2 ? 2 : online.length;
                            return Column(
                              children: [
                                for (var i = 0; i < displayItems; i++)
                                  InkWell(
                                    onTap: () => controller
                                        .viewAmbulanceDetails(online[i]),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 8),
                                          Text(
                                            '${i + 1}.${online[i]['name']?.toString() ?? 'Ambulance'}',
                                            style: TextStyle(
                                              color: Colors.blueGrey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey.shade400,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),

                          Divider(
                              height: 30,
                              thickness: 1,
                              color: Colors.grey.shade200),
                          _buildDrawerItem(
                            icon: Icons.info_outline,
                            title: 'About Us',
                            onTap: controller.navigateToAboutUs,
                          ),
                          _buildDrawerItem(
                            imagePath: 'assets/images/privacyPolicy.png',
                            icon: Icons.security_outlined,
                            title: 'Privacy Policy',
                            onTap: () {
                              Get.toNamed('/privacy-policy');
                            },
                          ),
                          _buildDrawerItem(
                            imagePath: 'assets/images/termsConditions.png',
                            icon: Icons.description_outlined,
                            title: 'Terms & Conditions',
                            onTap: () {
                              Get.toNamed('/terms-conditions');
                            },
                          ),
                          _buildDrawerItem(
                            imagePath: 'assets/images/feadbackDrawer.png',
                            icon: Icons.feedback_outlined,
                            title: 'Feedback',
                            onTap: () {
                              try {
                                Get.back();
                              } catch (_) {}
                              Get.to(() => const FeedbackPage());
                            },
                          ),
                        ],
                      ),
                    ),
                    // Sign Out Button
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: controller.signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Sign Out',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
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
                              size: 60,
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
                      /* // Ambulance status indicator
                      Obx(() {
                        if (controller.showAmbulances.value) {
                          return Container(
                            margin: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_hospital,
                                  color: Colors.green.shade700,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Nearby ambulances visible',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      }),
 */
                      // Destination input container
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 350),
                        child: Container(
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
                                  onChanged:
                                      controller.onDestinationTextChanged,
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
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              // Autocomplete suggestions - show only when user has typed something
                              Obx(() {
                                final query =
                                    controller.destinationQuery.value.trim();
                                // Do not show suggestions when the input is empty
                                final showSuggestions = query.isNotEmpty &&
                                    (controller.placeSuggestions.isNotEmpty ||
                                        controller.isLoadingSuggestions.value);

                                if (!showSuggestions) {
                                  return SizedBox.shrink();
                                }

                                return Container(
                                  margin: EdgeInsets.only(
                                      bottom: 16, left: 16, right: 16),
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        200, // Limit height to prevent overflow
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
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: controller.isLoadingSuggestions.value
                                      ? Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 20),
                                          child: Row(
                                            children: [
                                              HorizontalRotatingDots(
                                                size: 20,
                                                colors: [
                                                  primaryBlue,
                                                  secondaryBlue,
                                                  accentBlue
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          physics:
                                              ClampingScrollPhysics(), // Prevent scroll conflicts
                                          itemCount: controller
                                                      .placeSuggestions.length >
                                                  3
                                              ? 3 // Limit to 3 suggestions to prevent overflow
                                              : controller
                                                  .placeSuggestions.length,
                                          itemBuilder: (context, index) {
                                            final place = controller
                                                .placeSuggestions[index];
                                            return InkWell(
                                              onTap: () =>
                                                  controller.selectPlace(place),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 18,
                                                    horizontal: 16),
                                                decoration: BoxDecoration(
                                                  border: index <
                                                          (controller.placeSuggestions
                                                                      .length >
                                                                  3
                                                              ? 2
                                                              : controller
                                                                      .placeSuggestions
                                                                      .length -
                                                                  1)
                                                      ? Border(
                                                          bottom: BorderSide(
                                                              color: Colors.grey
                                                                  .shade100,
                                                              width: 1))
                                                      : null,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: lightBlue,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        size: 20,
                                                        color: primaryBlue,
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            place['name']
                                                                    ?.toString() ??
                                                                'Unknown Place',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .blueGrey
                                                                  .shade800,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          if (place['formattedAddress'] !=
                                                                  null &&
                                                              (place['formattedAddress']
                                                                          as String?)
                                                                      ?.isNotEmpty ==
                                                                  true)
                                                            Padding(
                                                              padding: EdgeInsets
                                                                  .only(top: 2),
                                                              child: Text(
                                                                place['formattedAddress']
                                                                        ?.toString() ??
                                                                    '',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .blueGrey
                                                                      .shade500,
                                                                  fontSize: 12,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.chevron_right,
                                                      color:
                                                          Colors.grey.shade400,
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
                      ),

                      // Fare Estimate Display (show only when destination is set and we have partner rates loaded)
                      Obx(() {
                        if (controller.destinationPosition.value != null &&
                            controller.partnerRates.isNotEmpty) {
                          // Get the first available partner's rates for estimation (you can modify this logic as needed)
                          final firstPartnerRates =
                              controller.partnerRates.values.firstWhere(
                            (rates) => rates.isNotEmpty,
                            orElse: () => {
                              'indoorCityRate': 2500,
                              'outdoorCityRate': 10000
                            },
                          );

                          return Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: FareEstimationWidget(
                              distance: controller.currentPosition.value !=
                                          null &&
                                      controller.destinationPosition.value !=
                                          null
                                  ? FareCalculationService.calculateDistance(
                                      controller
                                          .currentPosition.value!.latitude,
                                      controller
                                          .currentPosition.value!.longitude,
                                      controller
                                          .destinationPosition.value!.latitude,
                                      controller
                                          .destinationPosition.value!.longitude,
                                    )
                                  : 5.0, // Default distance if calculation fails
                              serviceType: 'ambulance',
                              partnerRates: firstPartnerRates,
                              urgency:
                                  'normal', // Default urgency, can be made dynamic if needed
                              // Assume indoor city for now
                            ),
                          );
                        } else {
                          return SizedBox
                              .shrink(); // Don't show anything if no destination is set or no rates loaded
                        }
                      }),

                      /* // Spacer to push floating buttons to bottom
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
                            Obx(() => _buildEmergencyButton(
                                  icon: Icons.local_hospital,
                                  label: controller.showAmbulances.value
                                      ? 'Ambulances On'
                                      : 'Ambulance',
                                  color: controller.showAmbulances.value
                                      ? Colors.green.shade700
                                      : Colors.green.shade600,
                                  onPressed:
                                      controller.navigateToAmbulanceServices,
                                  isActive: controller.showAmbulances.value,
                                )),
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
                      ), */
                    ],
                  ),
                ),

                // Zoom controls positioned on the right side
                // Emergency floating button - bottom-left
                Positioned(
                  left: 16,
                  bottom: 40,
                  child: GestureDetector(
                    onTap: () => controller.callCenter(),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/emergency.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.red.shade600,
                              child: Center(
                                child: Icon(
                                  Icons.call,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // AI Chat floating button - bottom-right (above zoom controls)
                Positioned(
                  right: 16,
                  bottom: 230,
                  child: GestureDetector(
                    onTap: () => Get.to(() => const AIChatPage()),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.asset(
                          'assets/images/ai.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryBlue, secondaryBlue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.smart_toy,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Zoom controls - bottom-right
                Positioned(
                  right: 16,
                  bottom: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zoom In Button
                      Container(
                        width: 40,
                        height: 40,
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: controller.zoomIn,
                          icon: Icon(
                            Icons.add,
                            color: Colors.grey.shade700,
                            size: 22,
                          ),
                          tooltip: 'Zoom In',
                        ),
                      ),

                      // Zoom Out Button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: controller.zoomOut,
                          icon: Icon(
                            Icons.remove,
                            color: Colors.grey.shade700,
                            size: 22,
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
        );
      },
    );
  }

  Widget _buildDrawerItem({
    IconData? icon,
    String? imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    icon ?? Icons.circle,
                    color: primaryBlue,
                    size: 20,
                  );
                },
              )
            else
              Icon(
                icon ?? Icons.circle,
                color: primaryBlue,
                size: 20,
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
