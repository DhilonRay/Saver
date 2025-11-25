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
                  final notificationController = Get.find<UserNotificationController>();
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
                              notificationController.unreadCount.value.toString(),
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
              child: Container(
                decoration: BoxDecoration(),
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
                                            Icons.person,
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
                                            )
                                          else
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'Uploading...',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
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
                                controller.userName.value,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
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
                          _buildDrawerItem(
                            icon: Icons.person_outline,
                            title: 'Profile',
                            onTap: controller.navigateToUserId,
                          ),
                          _buildDrawerItem(
                            icon: Icons.assignment_outlined,
                            title: 'Your Orders',
                            onTap: controller.navigateToUserOrders,
                          ),
                          _buildDrawerItem(
                            icon: Icons.track_changes_outlined,
                            title: 'Tracking',
                            onTap: controller.navigateToTrackingPage,
                          ),

                          // Quick access: available/online ambulances (live list)
                          _buildDrawerItem(
                            icon: Icons.local_hospital,
                            title: 'Available Ambulances',
                            onTap: controller.navigateToAmbulanceServices,
                          ),

                          Obx(() {
                            final online = controller.onlineAmbulances;
                            if (online.isEmpty) return SizedBox.shrink();

                            final count = online.length;
                            // show up to 3 providers as quick links
                            final displayItems = online.length > 3 ? 3 : online.length;
                            return Column(
                              children: [
                                for (var i = 0; i < displayItems; i++)
                                  InkWell(
                                    onTap: () => controller.viewAmbulanceDetails(online[i]),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.local_taxi,
                                              size: 18,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  online[i]['name']?.toString() ?? 'Ambulance',
                                                  style: TextStyle(
                                                    color: Colors.blueGrey.shade800,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  online[i]['ambulanceType']?.toString() ?? '',
                                                  style: TextStyle(
                                                    color: Colors.blueGrey.shade500,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
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
                                  ),

                                if (count > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                    child: GestureDetector(
                                      onTap: controller.navigateToAmbulanceServices,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('See all available ambulances', style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13)),
                                          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blueGrey.shade400),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),

                          Divider(height: 40, thickness: 1),
                          _buildDrawerItem(
                            icon: Icons.info_outline,
                            title: 'About Us',
                            onTap: controller.navigateToAboutUs,
                          ),
                          _buildDrawerItem(
                            icon: Icons.help_outline,
                            title: 'Privacy Policy',
                            onTap: () {
                              // Navigate to Privacy Policy page
                              Get.toNamed('/privacy-policy');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.description,
                            title: 'Terms & Conditions',
                            onTap: () {
                              // Navigate to Terms & Conditions page
                              Get.toNamed('/terms-conditions');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.feedback_outlined,
                            title: 'Feedback',
                            onTap: () {
                              // Close the drawer and navigate to Feedback page
                              try {
                                Get.back();
                              } catch (_) {}
                              Get.to(() => const FeedbackPage());
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
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
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
                                                  vertical: 18, horizontal: 16),
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
                                                            color: Colors
                                                                .grey.shade100,
                                                            width: 1))
                                                    : null,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: lightBlue,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
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
                                                                FontWeight.w500,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        if (place['formattedAddress'] !=
                                                                null &&
                                                            (place['formattedAddress']
                                                                        as String?)
                                                                    ?.isNotEmpty ==
                                                                true)
                                                          Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    top: 2),
                                                            child: Text(
                                                              place['formattedAddress']
                                                                      ?.toString() ??
                                                                  '',
                                                              style: TextStyle(
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
                // Call center floating button - bottom-left
                Positioned(
                  left: 16,
                  bottom: 60,
                  child: GestureDetector(
                    onTap: () => controller.callCenter(),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 120, // Position above the emergency buttons
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
    bool isActive = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                    if (isActive)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                  ],
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
