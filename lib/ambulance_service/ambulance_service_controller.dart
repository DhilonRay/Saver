import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AmbulanceServiceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive variables
  var isLoading = false.obs;
  var ambulancePartners = <QueryDocumentSnapshot>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAmbulancePartners();
  }

  Future<void> fetchAmbulancePartners() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore.collection('partners').get();
      ambulancePartners.value = snapshot.docs;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load ambulance partners: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Success',
      'Phone number copied!',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  Future<void> startAirAmbulanceChat(String partnerId, String companyName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Get.snackbar(
        'Authentication Required',
        'You need to be logged in to place an order.',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    // Show booking dialog with urgency selection
    await showBookingDialog(partnerId, companyName);
  }

  Future<void> showBookingDialog(String partnerId, String companyName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    String selectedUrgency = 'normal'; // normal, urgent, emergency
    String additionalNotes = '';

    final result = await Get.dialog(
      AlertDialog(
        title: Text('Book Ambulance - $companyName'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select urgency level:'),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: selectedUrgency,
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedUrgency = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => additionalNotes = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );

    if (result == true) {
      await createAmbulanceRequest(
        partnerId: partnerId,
        companyName: companyName,
        urgency: selectedUrgency,
        notes: additionalNotes,
      );
    }
  }

  Future<void> createAmbulanceRequest({
    required String partnerId,
    required String companyName,
    required String urgency,
    String? notes,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      isLoading.value = true;

      // Get user's current location
      Position? userPosition;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          userPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        }
      } catch (e) {
        print('Could not get user location: $e');
      }

      // Create the order
      final orderData = {
        'userId': userId,
        'partnerId': partnerId,
        'orderStatus': 'pending',
        'createdAt': Timestamp.now(),
        'companyName': companyName,
        'urgency': urgency,
        'notes': notes ?? '',
        'type': 'ambulance_request',
      };

      if (userPosition != null) {
        orderData['userLocation'] = {
          'latitude': userPosition.latitude,
          'longitude': userPosition.longitude,
        };
      }

      final orderRef = await _firestore.collection('orders').add(orderData);

      Get.snackbar(
        'Order Placed',
        'Ambulance request sent to $companyName. Waiting for response.',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 4),
      );

      // Trigger notification to nearby drivers
      orderData['orderId'] = orderRef.id;
      await notifyNearbyDrivers(orderRef.id, orderData);

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to place order: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void refreshData() {
    fetchAmbulancePartners();
  }

  Future<void> notifyNearbyDrivers(String orderId, Map<String, dynamic> orderData) async {
    try {
      // Get user's location for proximity calculation
      final userLocation = orderData['userLocation'];
      
      // Send notification to general ambulance requests topic
      await sendFCMNotificationToTopic('ambulance_requests', orderData);

      // If user location is available, also send to location-specific topics
      if (userLocation != null) {
        // TODO: Determine location-based topic from user coordinates
        // For example, based on city/district
        // await sendFCMNotificationToTopic('ambulance_dhaka', orderData);
      }

    } catch (e) {
      print('Error notifying drivers: $e');
    }
  }

  Future<void> sendFCMNotificationToTopic(String topic, Map<String, dynamic> orderData) async {
    // NOTE: In production, this should be done on a backend server to keep the server key secure
    // This is just for demonstration/testing purposes

    const String serverKey = 'YOUR_FCM_SERVER_KEY_HERE'; // Replace with actual server key

    final Map<String, dynamic> notificationData = {
      'title': 'New Ambulance Request',
      'body': 'Urgency: ${orderData['urgency']} - Tap to respond',
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };

    final Map<String, dynamic> data = {
      'orderId': orderData['orderId'] ?? '',
      'userId': orderData['userId'] ?? '',
      'urgency': orderData['urgency'] ?? 'normal',
      'type': 'ambulance_request',
      'userLocation': orderData['userLocation'] ?? {},
    };

    final Map<String, dynamic> message = {
      'to': '/topics/$topic',
      'notification': notificationData,
      'data': data,
      'priority': 'high',
    };

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('FCM notification sent to topic $topic successfully');
      } else {
        print('Failed to send FCM notification to topic $topic: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending FCM notification to topic $topic: $e');
    }
  }
}
