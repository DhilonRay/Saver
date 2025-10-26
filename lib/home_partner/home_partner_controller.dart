import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    Get.snackbar(
      'Status Updated',
      isOnline.value ? 'You are now online and available for orders' : 'You are now offline',
      backgroundColor: isOnline.value ? Colors.green : Colors.orange,
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
