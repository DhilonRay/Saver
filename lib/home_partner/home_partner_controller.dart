import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
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
    setupOrderListener();
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

  void navigateToUserLocation(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      Get.snackbar(
        'Navigation Error',
        'Could not open Google Maps: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
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
