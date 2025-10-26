import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_webservice/directions.dart' as directions;
import '../partner_orders/partners_orders_page.dart';
import '../partner/partner.dart';
import '../auth/log_in/login_screen.dart';

class HomePartnerController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Maps API client
  late directions.GoogleMapsDirections _directions;

  // Reactive variables
  var partnerData = Rx<Map<String, dynamic>?>(null);
  var isLoading = true.obs;
  var totalOrders = 0.obs;
  var pendingOrders = 0.obs;
  var completedOrders = 0.obs;
  var isOnline = false.obs;

  // Location variables
  var currentPosition = Rx<Position?>(null);
  var mapController = Rx<GoogleMapController?>(null);
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;

  // Custom marker icons
  var ambulanceIcon = Rx<BitmapDescriptor?>(null);
  var userIcon = Rx<BitmapDescriptor?>(null);

  // Active service tracking
  var activeOrderId = Rx<String?>(null);
  var isServiceActive = false.obs;
  var isDrivingStarted = false.obs;

  // Animation variables
  var isAnimating = false.obs;
  var animationRoutePoints = <LatLng>[].obs;
  var currentAnimationIndex = 0.obs;
  var animationSpeed = 1.0.obs; // Speed multiplier based on GPS speed

  // Live location tracking
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    // Initialize Google Maps Directions API
    _directions = directions.GoogleMapsDirections(apiKey: 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o');
    loadCustomIcons();
    loadPartnerData();
    loadOrderStats();
    getCurrentLocation();
    setupFCMListeners();
    setupOrderListener();
  }

  Future<void> loadCustomIcons() async {
    try {
      ambulanceIcon.value = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(24, 24)),
        'assets/markers/ambulance.png',
      ) as BitmapDescriptor;
      userIcon.value = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(24, 24)),
        'assets/markers/user.png',
      ) as BitmapDescriptor;
      print('✅ Custom icons loaded successfully');
    } catch (e) {
      print('❌ Error loading custom icons: $e'); 
    }
  }

  void setupOrderListener() {
    final user = _auth.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('orders')
          .where('partnerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .where('type', isEqualTo: 'ambulance')
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            showRequestBottomSheet(change.doc.id, data);
          }
        }
      });
    }
  }

  void setupFCMListeners() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      handleIncomingRequest(message);
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.notification?.title}');
      handleIncomingRequest(message);
    });

    // Subscribe to ambulance requests topic
    subscribeToAmbulanceRequests();
  }

  Future<void> subscribeToAmbulanceRequests() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('ambulance_requests');
      print('Subscribed to ambulance_requests topic');

      // Also subscribe to location-based topics if partner has location
      if (partnerData.value != null) {
        final coverageArea = partnerData.value!['coverageArea'] as String?;
        if (coverageArea != null && coverageArea.isNotEmpty) {
          final topicName = 'ambulance_${coverageArea.toLowerCase().replaceAll(' ', '_')}';
          await FirebaseMessaging.instance.subscribeToTopic(topicName);
          print('Subscribed to location topic: $topicName');
        }
      }
    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }

  void handleIncomingRequest(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'ambulance_request') {
      showRequestBottomSheet(data['orderId'] ?? '', data);
    }
  }

  void showRequestBottomSheet(String orderId, Map<String, dynamic> requestData) {
    final userId = requestData['userId'] ?? '';
    final urgency = requestData['urgency'] ?? 'normal';
    final userLocation = requestData['userLocation'] ?? {};
    final notes = requestData['notes'] ?? '';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🚨 Ambulance Request',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: urgency == 'emergency' ? Colors.red.shade50 :
                       urgency == 'urgent' ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: urgency == 'emergency' ? Colors.red.shade200 :
                         urgency == 'urgent' ? Colors.orange.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    urgency == 'emergency' ? Icons.error :
                    urgency == 'urgent' ? Icons.warning : Icons.info,
                    color: urgency == 'emergency' ? Colors.red :
                           urgency == 'urgent' ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Urgency: ${urgency.toUpperCase()}',
                    style: TextStyle(
                      color: urgency == 'emergency' ? Colors.red :
                             urgency == 'urgent' ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'A user needs ambulance assistance.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            if (userLocation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location: ${userLocation['latitude']?.toStringAsFixed(4) ?? 'N/A'}, '
                      '${userLocation['longitude']?.toStringAsFixed(4) ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notes: $notes',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Do you want to accept this request?',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      acceptRequest(orderId, userId, userLocation);
                    },
                    child: const Text('Accept & Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void acceptRequest(String orderId, String userId, Map<String, dynamic> userLocation) async {
    try {
      // Update order status to accepted
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'orderStatus': 'accepted',
        'acceptedAt': Timestamp.now(),
        'acceptedBy': _auth.currentUser?.uid,
      });

      // Set active service
      activeOrderId.value = orderId;
      isServiceActive.value = true;
      isDrivingStarted.value = false;

      Get.snackbar(
        'Request Accepted',
        'Showing route to user location...',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Show route to user location on map
      if (userLocation.isNotEmpty) {
        final lat = userLocation['latitude'] as double?;
        final lng = userLocation['longitude'] as double?;

        if (lat != null && lng != null) {
          await showRouteToUser(lat, lng);
        }
      }

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept request: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> showRouteToUser(double latitude, double longitude) async {
    if (currentPosition.value == null) return;

    try {
      // Clear existing polylines
      polylines.clear();

      // Ensure current location marker is present
      bool hasCurrentLocationMarker = markers.any((marker) => marker.markerId.value == 'current_location');
      if (!hasCurrentLocationMarker) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
            infoWindow: const InfoWindow(title: 'Your Location (Partner)'),
            icon: ambulanceIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }

      // Add or update destination marker
      markers.removeWhere((marker) => marker.markerId.value == 'user_destination');
      markers.add(
        Marker(
          markerId: const MarkerId('user_destination'),
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(title: 'User Location'),
          icon: userIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Get directions from Google
      final directionsResponse = await _directions.directions(
        directions.Location(lat: currentPosition.value!.latitude, lng: currentPosition.value!.longitude),
        directions.Location(lat: latitude, lng: longitude),
        travelMode: directions.TravelMode.driving,
      );

      if (directionsResponse.isOkay && directionsResponse.routes.isNotEmpty) {
        final route = directionsResponse.routes.first;

        // Decode polyline
        List<LatLng> polylinePoints = [];
        try {
          final dynamic routeData = route;
          final dynamic overviewPolyline = routeData.overviewPolyline;
          if (overviewPolyline != null) {
            final dynamic points = overviewPolyline.points;
            if (points != null && points.isNotEmpty) {
              polylinePoints = _decodePolyline(points);
            }
          }
        } catch (e) {
          polylinePoints = [];
        }

        // Add polyline
        if (polylinePoints.isNotEmpty) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route_to_user'),
              color: Colors.blue.shade700,
              width: 6,
              zIndex: 1,
              points: polylinePoints,
            ),
          );
        } else {
          // Fallback straight line
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route_to_user'),
              color: Colors.orange.shade700,
              width: 6,
              zIndex: 1,
              points: [LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude), LatLng(latitude, longitude)],
            ),
          );
        }

        // Animate camera to fit the route
        if (mapController.value != null) {
          final bounds = LatLngBounds(
            southwest: LatLng(
              currentPosition.value!.latitude < latitude ? currentPosition.value!.latitude : latitude,
              currentPosition.value!.longitude < longitude ? currentPosition.value!.longitude : longitude,
            ),
            northeast: LatLng(
              currentPosition.value!.latitude > latitude ? currentPosition.value!.latitude : latitude,
              currentPosition.value!.longitude > longitude ? currentPosition.value!.longitude : longitude,
            ),
          );
          await mapController.value!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
        }

        Get.snackbar(
          'Route Ready',
          'Follow the blue line to reach the user',
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade800,
          duration: const Duration(seconds: 4),
        );
      } else {
        // Fallback: straight line if directions fail
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route_to_user'),
            color: Colors.red.shade700,
            width: 4,
            zIndex: 1,
            points: [LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude), LatLng(latitude, longitude)],
          ),
        );

        Get.snackbar(
          'Route Warning',
          'Using direct route (directions unavailable)',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }
    } catch (e) {
      debugPrint('Error showing route: $e');
      Get.snackbar(
        'Route Error',
        'Could not load route: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void startDriving() {
    isDrivingStarted.value = true;

    // Start live location tracking
    startLiveLocationTracking();

    // Try to start route animation immediately if route exists
    // If not, it will start when route becomes available
    startRouteAnimation();

    Get.snackbar(
      '🚑 Driving Started',
      'Ambulance is moving towards user location!',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      duration: const Duration(seconds: 3),
    );
  }

  void startRouteAnimation() {
    if (polylines.isEmpty || !isDrivingStarted.value) return;

    isAnimating.value = true;
    currentAnimationIndex.value = 0;

    // Get route points from the polyline
    Polyline? routePolyline;
    for (var polyline in polylines) {
      if (polyline.polylineId.value == 'route_to_user') {
        routePolyline = polyline;
        break;
      }
    }

    if (routePolyline != null) {
      animationRoutePoints.value = routePolyline.points;

      // Show visual feedback that animation started
      Get.snackbar(
        '🚑 Ambulance Moving',
        'Following the route to user location',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
      );

      animateAlongRoute();
    }
  }

  void animateAlongRoute() {
    if (!isAnimating.value || animationRoutePoints.isEmpty) return;

    const int totalPoints = 200; // More animation steps for smoother movement
    final int totalRoutePoints = animationRoutePoints.length;

    if (currentAnimationIndex.value >= totalPoints) {
      isAnimating.value = false;
      return;
    }

    // Calculate current position along the route
    final progress = currentAnimationIndex.value / totalPoints;
    final pointIndex = (progress * (totalRoutePoints - 1)).toInt();
    final nextPointIndex = (pointIndex + 1).clamp(0, totalRoutePoints - 1);

    final currentPoint = animationRoutePoints[pointIndex];
    final nextPoint = animationRoutePoints[nextPointIndex];

    // Interpolate between points
    final segmentProgress = (progress * (totalRoutePoints - 1)) - pointIndex;
    final lat = currentPoint.latitude + (nextPoint.latitude - currentPoint.latitude) * segmentProgress;
    final lng = currentPoint.longitude + (nextPoint.longitude - currentPoint.longitude) * segmentProgress;

    // Update marker position with animation
    updateAnimatedMarkerPosition(LatLng(lat, lng));

    // Calculate animation delay based on speed (faster updates for smoother animation)
    final delay = Duration(milliseconds: (500 / animationSpeed.value).toInt().clamp(50, 200));

    currentAnimationIndex.value++;
    Future.delayed(delay, animateAlongRoute);
  }

  void updateAnimatedMarkerPosition(LatLng position) {
    markers.removeWhere((marker) => marker.markerId.value == 'current_location');
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: position,
        infoWindow: const InfoWindow(title: '🚑 Ambulance Moving'),
        icon: ambulanceIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        rotation: calculateRotation(position),
        zIndex: 2.0, // Make sure ambulance appears above other markers
      ),
    );

    // Smooth camera following with zoom
    if (mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 16.0, // Good zoom level to see the route
            bearing: calculateRotation(position), // Rotate map to match ambulance direction
          ),
        ),
      );
    }
  }

  double calculateRotation(LatLng currentPosition) {
    if (animationRoutePoints.length < 2) return 0.0;

    final nextIndex = (currentAnimationIndex.value + 1).clamp(0, animationRoutePoints.length - 1);
    if (nextIndex >= animationRoutePoints.length) return 0.0;

    final nextPoint = animationRoutePoints[nextIndex];
    final bearing = Geolocator.bearingBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      nextPoint.latitude,
      nextPoint.longitude,
    );

    return bearing;
  }

  void startLiveLocationTracking() {
    // Stop any existing stream
    _positionStreamSubscription?.cancel();

    // Start new location stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      // Update current position
      currentPosition.value = position;

      // Update animation speed based on GPS speed (convert m/s to animation multiplier)
      if (position.speed > 0) {
        // Speed in m/s, convert to animation speed multiplier
        // Normal driving speed ~10-30 km/h = ~3-8 m/s
        animationSpeed.value = (position.speed / 5.0).clamp(0.5, 3.0);
      }

      // Update live location in Firestore for this active order
      if (activeOrderId.value != null) {
        updateLiveLocation(position.latitude, position.longitude);
      }

      // If not animating, update marker position directly
      if (!isAnimating.value) {
        markers.removeWhere((marker) => marker.markerId.value == 'current_location');
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Your Location (Live)'),
            icon: ambulanceIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    });
  }

  Future<void> updateLiveLocation(double latitude, double longitude) async {
    try {
      if (activeOrderId.value != null) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(activeOrderId.value)
            .update({
          'partnerLiveLocation': {
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': Timestamp.now(),
          },
        });
      }
    } catch (e) {
      debugPrint('Error updating live location: $e');
    }
  }

  void completeOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'orderStatus': 'completed',
        'completedAt': Timestamp.now(),
      });

      // Clear active service
      if (activeOrderId.value == orderId) {
        activeOrderId.value = null;
        isServiceActive.value = false;
        isDrivingStarted.value = false;
        isAnimating.value = false; // Stop animation

        // Stop live location tracking
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = null;

        // Clear route
        polylines.clear();
        markers.removeWhere((marker) => marker.markerId.value == 'user_destination');
      }

      Get.snackbar(
        'Order Completed',
        'Service marked as completed.',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      loadOrderStats(); // Refresh stats
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete order: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void completeActiveService() {
    if (activeOrderId.value != null) {
      completeOrder(activeOrderId.value!);
    }
  }

  Future<void> loadPartnerData() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('partners')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          partnerData.value = doc.data();
          print('✅ Partner data loaded: ${partnerData.value}');
        } else {
          print('❌ Partner data not found');
          Get.snackbar(
            'Error',
            'Partner profile not found. Please complete registration.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('❌ Error loading partner data: $e');
      Get.snackbar(
        'Error',
        'Failed to load partner data: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadOrderStats() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get total orders for this partner
        final ordersQuery = await FirebaseFirestore.instance
            .collection('orders')
            .where('partnerId', isEqualTo: user.uid)
            .get();

        totalOrders.value = ordersQuery.docs.length;

        // Count pending and completed orders
        int pending = 0;
        int completed = 0;

        for (var doc in ordersQuery.docs) {
          final status = doc.data()['status'] as String?;
          if (status == 'pending' || status == 'accepted') {
            pending++;
          } else if (status == 'completed') {
            completed++;
          }
        }

        pendingOrders.value = pending;
        completedOrders.value = completed;

        print('📊 Order stats loaded - Total: ${totalOrders.value}, Pending: ${pendingOrders.value}, Completed: ${completedOrders.value}');
      }
    } catch (e) {
      print('❌ Error loading order stats: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Services Disabled',
          'Please enable location services to use the map.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Location Permission Denied',
            'Location permission is required to show your position on the map.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Location Permission Denied Forever',
          'Please enable location permission in app settings.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition.value = position;

      // Update location in Firestore for real-time tracking
      await updatePartnerLocation(position.latitude, position.longitude);

      // Add marker for current location
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: ambulanceIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      print('📍 Current location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Error getting location: $e');
      Get.snackbar(
        'Location Error',
        'Failed to get current location: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> updatePartnerLocation(double latitude, double longitude) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('partners')
            .doc(user.uid)
            .update({
          'latitude': latitude,
          'longitude': longitude,
          'lastLocationUpdate': Timestamp.now(),
          'isOnline': isOnline.value,
        });
        print('📍 Partner location updated in Firestore: $latitude, $longitude');
      }
    } catch (e) {
      print('❌ Error updating partner location: $e');
    }
  }

  void toggleOnlineStatus() {
    isOnline.value = !isOnline.value;
    
    // Update online status in Firestore
    final user = _auth.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .update({
        'isOnline': isOnline.value,
        'lastStatusUpdate': Timestamp.now(),
      }).then((_) {
        print('📊 Partner online status updated: ${isOnline.value}');
      }).catchError((e) {
        print('❌ Error updating online status: $e');
      });
    }
    
    Get.snackbar(
      isOnline.value ? 'Online' : 'Offline',
      isOnline.value ? 'You are now visible to users' : 'You are now offline',
      backgroundColor: isOnline.value ? Colors.green : Colors.grey,
      colorText: Colors.white,
    );
  }

  void navigateToOrders() {
    Get.to(() => PartnersOrdersPage());
  }

  void navigateToProfile() {
    final user = _auth.currentUser;
    if (user != null) {
      Get.to(() => PartnerPage(uid: user.uid));
    }
  }

  void logout() {
    _auth.signOut();
    Get.offAll(() => const LoginPage());
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.value = controller;
    if (currentPosition.value != null) {
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
        ),
      );
    }
  }

  void refreshData() {
    loadPartnerData();
    loadOrderStats();
    getCurrentLocation();
  }
}
