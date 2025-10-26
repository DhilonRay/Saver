import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../partner_orders/partners_orders_page.dart';
import '../partner/partner.dart';
import '../auth/log_in/login_screen.dart';

class HomePartnerController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  @override
  void onInit() {
    super.onInit();
    loadPartnerData();
    loadOrderStats();
    getCurrentLocation();
    setupFCMListeners();
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
      showRequestDialog(data);
    }
  }

  void showRequestDialog(Map<String, dynamic> requestData) {
    final orderId = requestData['orderId'] ?? '';
    final userId = requestData['userId'] ?? '';
    final urgency = requestData['urgency'] ?? 'normal';
    final userLocation = requestData['userLocation'] ?? {};

    Get.dialog(
      AlertDialog(
        title: const Text('🚨 Ambulance Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Urgency: ${urgency.toUpperCase()}',
                style: TextStyle(
                  color: urgency == 'emergency' ? Colors.red :
                         urgency == 'urgent' ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            const Text('A user needs ambulance assistance.'),
            if (userLocation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Location: ${userLocation['latitude']?.toStringAsFixed(4) ?? 'N/A'}, '
                   '${userLocation['longitude']?.toStringAsFixed(4) ?? 'N/A'}'),
            ],
            const SizedBox(height: 16),
            const Text('Do you want to accept this request?',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Decline'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              acceptRequest(orderId, userId, userLocation);
            },
            child: const Text('Accept & Navigate'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
      barrierDismissible: false, // Prevent dismissing by tapping outside
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

      Get.snackbar(
        'Request Accepted',
        'Navigating to user location...',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate to user location on map
      if (userLocation.isNotEmpty) {
        final lat = userLocation['latitude'] as double?;
        final lng = userLocation['longitude'] as double?;

        if (lat != null && lng != null) {
          navigateToUserLocation(lat, lng);
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

  void navigateToUserLocation(double latitude, double longitude) {
    // Animate camera to user location
    if (mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(latitude, longitude),
          16.0, // Zoom level
        ),
      );

      // Add marker for user location
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(title: 'User Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
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

      // Add marker for current location
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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

  void toggleOnlineStatus() {
    isOnline.value = !isOnline.value;
    
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
