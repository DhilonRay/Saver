import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class RequestRideController extends GetxController {
  var isLoading = false.obs;
  var nearbyDrivers = <Map<String, dynamic>>[].obs;

  /// Example function to send ride request to a specific driver
  Future<void> sendRideRequestToSpecificDriver({
    required String driverId,
    required String destinationAddress,
    String? notes,
    String urgency = 'normal',
  }) async {
    try {
      isLoading.value = true;

      // Get driver's FCM token from Supabase
      final driverDocMap = await SupabaseService.getPartner(driverId);

      if (driverDocMap == null) {
        Get.snackbar('ত্রুটি', 'ড্রাইভার পাওয়া যায়নি');
        return;
      }

      final driverData = SupabaseService.toCamelCase(driverDocMap);
      final fcmToken = driverData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        Get.snackbar('ত্রুটি', 'ড্রাইভারের নোটিফিকেশন টোকেন পাওয়া যায়নি');
        return;
      }

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

      // Create ride request data
      final requestData = {
        'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
        'driverId': driverId,
        'pickupLocation': userPosition != null ? {
          'latitude': userPosition.latitude,
          'longitude': userPosition.longitude,
        } : null,
        'destinationAddress': destinationAddress,
        'notes': notes ?? '',
        'urgency': urgency,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      // Save request to Supabase first
      final requestId = requestData['requestId'] as String;
      await SupabaseService.client.from('ride_requests').upsert({
        ...SupabaseService.toSnakeCase(requestData),
        'id': requestId,
      });

      // Send push notification to driver
      final success = await NotificationService.sendNotificationToDriver(
        driverId: driverId,
        requestData: requestData,
      );

      if (success) {
        print('✅ Ride request sent successfully to driver: $driverId');
      }

    } catch (e) {
      print('❌ Error sending ride request: $e');
      Get.snackbar(
        'ত্রুটি',
        'রাইড রিকুয়েস্ট পাঠাতে সমস্যা হয়েছে: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Find and send request to nearby drivers
  Future<void> sendRequestToNearbyDrivers({
    required String destinationAddress,
    String? notes,
    String urgency = 'normal',
    double radiusInKm = 5.0,
  }) async {
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
        Get.snackbar('ত্রুটি', 'আপনার অবস্থান পেতে সমস্যা হয়েছে');
        return;
      }

      if (userPosition == null) {
        Get.snackbar('ত্রুটি', 'আপনার বর্তমান অবস্থান পাওয়া যায়নি');
        return;
      }

      // Find nearby drivers from Supabase
      final list = await SupabaseService.query(
        'partners',
        filters: {
          'role': 'driver',
          'is_online': true,
        },
      );

      int notificationsSent = 0;
      nearbyDrivers.clear();

      for (var item in list) {
        final driverData = SupabaseService.toCamelCase(item);
        final driverLocation = driverData['currentLocation'];
        final fcmToken = driverData['fcmToken'];
        final driverId = driverData['id'] ?? driverData['uid'] ?? '';
        
        if (driverLocation != null && fcmToken != null && fcmToken.isNotEmpty && driverId.isNotEmpty) {
          final driverLat = driverLocation['latitude'] as double?;
          final driverLng = driverLocation['longitude'] as double?;
          
          if (driverLat != null && driverLng != null) {
            // Calculate distance between user and driver
            final distance = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              driverLat,
              driverLng,
            ) / 1000; // Convert to kilometers
            
            // Add to nearby drivers list and send notification if within radius
            if (distance <= radiusInKm) {
              nearbyDrivers.add({
                'id': driverId,
                'name': driverData['name'] ?? 'Unknown Driver',
                'distance': distance,
                'fcmToken': fcmToken,
                ...driverData,
              });

              // Create ride request data
              final requestData = {
                'requestId': '${DateTime.now().millisecondsSinceEpoch}_$driverId',
                'driverId': driverId,
                'pickupLocation': {
                  'latitude': userPosition.latitude,
                  'longitude': userPosition.longitude,
                },
                'destinationAddress': destinationAddress,
                'notes': notes ?? '',
                'urgency': urgency,
                'timestamp': DateTime.now().toIso8601String(),
                'status': 'pending',
                'distance': distance,
              };

              // Save request to Supabase
              final requestId2 = requestData['requestId'] as String;
              await SupabaseService.client.from('ride_requests').upsert({
                ...SupabaseService.toSnakeCase(requestData),
                'id': requestId2,
              });

              // Send notification to this driver
              final success = await NotificationService.sendNotificationToDriver(
                driverId: driverId,
                requestData: requestData,
              );

              if (success) {
                notificationsSent++;
                print('✅ Notification sent to driver: $driverId at ${distance.toStringAsFixed(2)}km');
              }
            }
          }
        }
      }

      if (notificationsSent > 0) {
        Get.snackbar(
          '✅ সফল',
          '$notificationsSent জন ড্রাইভারের কাছে রিকুয়েস্ট পাঠানো হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          '⚠️ তথ্য',
          'আশেপাশে কোন অনলাইন ড্রাইভার পাওয়া যায়নি',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        );
      }

    } catch (e) {
      print('❌ Error sending requests to nearby drivers: $e');
      Get.snackbar(
        'ত্রুটি',
        'আশেপাশের ড্রাইভারদের খুঁজে পেতে সমস্যা হয়েছে: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Example ambulance request
  Future<void> sendAmbulanceRequest({
    required String partnerId,
    required String companyName,
    String urgency = 'high',
    String? notes,
  }) async {
    try {
      isLoading.value = true;

      // Get partner's FCM token from Supabase
      final partnerDocMap = await SupabaseService.getPartner(partnerId);

      if (partnerDocMap == null) {
        Get.snackbar('ত্রুটি', 'অ্যাম্বুলেন্স পার্টনার পাওয়া যায়নি');
        return;
      }

      final partnerData = SupabaseService.toCamelCase(partnerDocMap);
      final fcmToken = partnerData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        Get.snackbar('ত্রুটি', 'পার্টনারের নোটিফিকেশন টোকেন পাওয়া যায়নি');
        return;
      }

      // Get user's current location
      Position? userPosition;
      try {
        userPosition = await Geolocator.getCurrentPosition();
      } catch (e) {
        print('Could not get user location: $e');
      }

      // Create ambulance request data
      final Map<String, dynamic> requestData = {
        'orderId': DateTime.now().millisecondsSinceEpoch.toString(),
        'partnerId': partnerId,
        'companyName': companyName,
        'urgency': urgency,
        'notes': notes ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
        'type': 'ambulance',
      };

      if (userPosition != null) {
        requestData['userLocation'] = {
          'latitude': userPosition.latitude,
          'longitude': userPosition.longitude,
        };
      }

      // Save request to Supabase
      final orderId = requestData['orderId'] as String;
      await SupabaseService.client.from('orders').upsert({
        ...SupabaseService.toSnakeCase(requestData),
        'id': orderId,
      });

      // Send push notification
      final success = await NotificationService.sendAmbulanceNotificationDirect(
        partnerId: partnerId,
        requestData: requestData,
      );

      if (success) {
        print('✅ Ambulance request sent successfully');
      }

    } catch (e) {
      print('❌ Error sending ambulance request: $e');
      Get.snackbar(
        'ত্রুটি',
        'অ্যাম্বুলেন্স রিকুয়েস্ট পাঠাতে সমস্যা হয়েছে: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }
}