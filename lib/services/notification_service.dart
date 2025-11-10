import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' as services;
import '../home_partner/home_partner_controller.dart';

class NotificationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // FCM V1 API Configuration
  static const String _fcmProjectId = 'neosaver-f06e9';
  static const String _fcmUrl = 'https://fcm.googleapis.com/v1/projects/$_fcmProjectId/messages:send';

  // Load Service Account Credentials for FCM V1 from assets
  static Future<Map<String, dynamic>> _loadServiceAccount() async {
    final String jsonString = await services.rootBundle.loadString('assets/service_account.json');
    return json.decode(jsonString);
  }
  
  /// Generate JWT access token for FCM V1 API using googleapis_auth
  static Future<String> _getAccessToken() async {
    try {
      // Load service account credentials from assets
      final serviceAccount = await _loadServiceAccount();

      // Create service account credentials from loaded data
      final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(serviceAccount);

      // Create authenticated client
      final client = await auth.clientViaServiceAccount(
        serviceAccountCredentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      // Get access token from the authenticated client
      final accessToken = client.credentials.accessToken.data;

      // Close the client
      client.close();

      return accessToken;
    } catch (e) {
      print('❌ Error generating access token: $e');
      throw e;
    }
  }

  /// Send FCM notification using V1 API
  static Future<bool> _sendFCMNotification({
    required String fcmToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      final message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data.map((key, value) => MapEntry(key, value.toString())),
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'ambulance_requests',
              'sound': 'default',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      print('🚀 FCM V1 Response Status: ${response.statusCode}');
      print('🚀 FCM V1 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['name'] != null) {
          print('✅ FCM V1 notification sent successfully');
          return true;
        }
      }

      print('❌ FCM V1 notification failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('❌ Error sending FCM V1 notification: $e');
      return false;
    }
  }

  static Future<bool> sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return await _sendFCMNotification(
      fcmToken: token,
      title: title,
      body: body,
      data: data ?? {},
    );
  }

  static Future<bool> sendNotificationToDriver({
    required String driverId,
    required Map<String, dynamic> requestData,
  }) async {
    try {
      print('🚀 Calling Firebase Function to send notification to driver: $driverId');
      
      final HttpsCallable callable = _functions.httpsCallable('sendNotificationToDriver');
      
      final result = await callable.call({
        'driverId': driverId,
        'requestData': requestData,
      });

      final data = result.data;
      
      if (data['success'] == true) {
        print('✅ Notification sent successfully via Firebase Function');
        print('📱 Message ID: ${data['messageId']}');
        
        Get.snackbar(
          '✅ সফল',
          'ড্রাইভারের কাছে আপনার রিকুয়েস্ট পাঠানো হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        print('❌ Failed to send notification: ${data['message']}');
        Get.snackbar(
          '❌ ত্রুটি',
          'নোটিফিকেশন পাঠাতে সমস্যা হয়েছে',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      print('❌ Error calling Firebase Function: $e');
      Get.snackbar(
        '❌ ত্রুটি',
        'নোটিফিকেশন পাঠাতে সমস্যা হয়েছে: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  /// Sends notifications to nearby drivers using Firebase Cloud Functions
  /// NO API KEY REQUIRED
  static Future<bool> sendNotificationToNearbyDrivers({
    required Map<String, double> userLocation,
    required Map<String, dynamic> requestData,
    double radiusInKm = 5.0,
  }) async {
    try {
      print('🔍 Looking for nearby drivers via Firebase Function...');
      
      final HttpsCallable callable = _functions.httpsCallable('sendNotificationToNearbyDrivers');
      
      final result = await callable.call({
        'userLocation': {
          'latitude': userLocation['latitude'],
          'longitude': userLocation['longitude'],
        },
        'requestData': requestData,
        'radiusInKm': radiusInKm,
      });

      final data = result.data;
      
      if (data['success'] == true) {
        final nearbyCount = data['nearbyDriversCount'] ?? 0;
        final totalFound = data['totalDriversFound'] ?? 0;
        
        print('✅ Found $totalFound total drivers, $nearbyCount within ${radiusInKm}km');
        
        if (nearbyCount > 0) {
          Get.snackbar(
            '✅ সফল',
            '$nearbyCount জন ড্রাইভারের কাছে রিকুয়েস্ট পাঠানো হয়েছে',
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
        return true;
      } else {
        print('❌ Failed to send notifications: ${data['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notifications to nearby drivers: $e');
      Get.snackbar(
        '❌ ত্রুটি',
        'আশেপাশের ড্রাইভারদের খুঁজে পেতে সমস্যা হয়েছে: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Sends ambulance request notification using Firebase Cloud Functions
  /// NO API KEY REQUIRED
  static Future<bool> sendAmbulanceNotification({
    required String partnerId,
    required Map<String, dynamic> requestData,
  }) async {
    try {
      print('🚑 Sending ambulance request via Firebase Function...');
      print('🚑 Partner ID: $partnerId');
      print('🚑 Request Data: $requestData');
      
      final HttpsCallable callable = _functions.httpsCallable('sendAmbulanceNotification');
      
      final result = await callable.call({
        'partnerId': partnerId,
        'requestData': requestData,
      });

      final data = result.data;
      print('🚑 Cloud Function Response: $data');
      
      if (data['success'] == true) {
        print('✅ Ambulance notification sent successfully');
        print('📱 Message ID: ${data['messageId']}');
        
        Get.snackbar(
          '✅ সফল',
          'অ্যাম্বুলেন্স পার্টনারের কাছে রিকুয়েস্ট পাঠানো হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        print('❌ Failed to send ambulance notification: ${data['message']}');
        Get.snackbar(
          '❌ ত্রুটি',
          'অ্যাম্বুলেন্স নোটিফিকেশন পাঠাতে সমস্যা: ${data['message']}',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('❌ Error sending ambulance notification: $e');
      Get.snackbar(
        '❌ ত্রুটি',
        'অ্যাম্বুলেন্স রিকুয়েস্ট পাঠাতে সমস্যা হয়েছে: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Send ambulance notification using FCM V1 API (Direct implementation)
  /// Uses service account authentication for reliable delivery
  static Future<bool> sendAmbulanceNotificationDirect({
    required String partnerId,
    required Map<String, dynamic> requestData,
  }) async {
    try {
      print('🚑 Sending ambulance request notification via FCM V1 API...');
      print('🚑 Partner ID: $partnerId');

      // Get current user and partner FCM token
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get partner's FCM token from Firestore
      final partnerDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(partnerId)
          .get();

      if (!partnerDoc.exists) {
        throw Exception('Partner not found');
      }

      final partnerData = partnerDoc.data();
      final fcmToken = partnerData?['fcmToken'] as String?;

      print('🚑 Partner data: $partnerData');
      print('🚑 FCM Token: $fcmToken');

      // Validate FCM token format
      if (fcmToken == null || fcmToken.isEmpty || fcmToken.length < 100) {
        print('⚠️ Partner FCM token invalid or too short (length: ${fcmToken?.length}), saving notification for later');
        // Save notification for when partner comes online
        await FirebaseFirestore.instance.collection('pending_notifications').add({
          'type': 'ambulance_request',
          'partnerId': partnerId,
          'userId': currentUser.uid,
          'requestData': requestData,
          'timestamp': FieldValue.serverTimestamp(),
        });

        Get.snackbar(
          '✅ সফল',
          'অ্যাম্বুলেন্স পার্টনারের কাছে রিকুয়েস্ট পাঠানো হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        );
        return true;
      }

      // Get user data for notification content
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data();
      final patientName = requestData['patientName'] ?? userData?['name'] ?? 'রোগী';

      // Prepare comprehensive notification data with full user details
      final notificationData = {
        'type': 'ambulance_request',
        'orderId': requestData['orderId'] ?? '',
        'userId': currentUser.uid,
        'partnerId': partnerId, // Add partner ID for background notification storage
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),

        // Patient Information
        'patientName': patientName,
        'patientAge': requestData['patientAge'] ?? userData?['age'] ?? '',
        'patientGender': requestData['patientGender'] ?? userData?['gender'] ?? '',
        'bloodType': requestData['bloodType'] ?? userData?['bloodType'] ?? '',

        // Contact Information
        'userPhone': userData?['phone'] ?? '',
        'userEmail': userData?['email'] ?? currentUser.email ?? '',
        'emergencyContact': requestData['emergencyContact'] ?? userData?['emergencyContact'] ?? '',
        'emergencyPhone': requestData['emergencyPhone'] ?? userData?['emergencyPhone'] ?? '',

        // Location Information
        'pickupLocation': json.encode(requestData['userLocation'] ?? {}),
        'pickupAddress': requestData['pickupAddress'] ?? '',
        'destinationAddress': requestData['destinationAddress'] ?? '',

        // Medical Information
        'urgency': requestData['urgency'] ?? 'high',
        'medicalCondition': requestData['medicalCondition'] ?? userData?['medicalCondition'] ?? '',
        'allergies': requestData['allergies'] ?? userData?['allergies'] ?? '',
        'medications': requestData['medications'] ?? userData?['medications'] ?? '',
        'specialNeeds': requestData['specialNeeds'] ?? userData?['specialNeeds'] ?? '',

        // Request Details
        'notes': requestData['notes'] ?? '',
        'companyName': requestData['companyName'] ?? '',
        'requestType': requestData['requestType'] ?? 'ambulance',
        'estimatedDistance': requestData['estimatedDistance'] ?? '',
        'estimatedTime': requestData['estimatedTime'] ?? '',

        // Additional User Profile Data
        'userType': userData?['userType'] ?? 'patient',
        'membershipStatus': userData?['membershipStatus'] ?? 'regular',
        'insuranceInfo': userData?['insuranceInfo'] ?? '',
        'preferredHospital': userData?['preferredHospital'] ?? '',
      };

      // Create detailed notification message
      final urgencyText = requestData['urgency'] == 'critical' ? 'জরুরি' :
                         requestData['urgency'] == 'high' ? 'উচ্চ' :
                         requestData['urgency'] == 'medium' ? 'মাঝারি' : 'সাধারণ';

      final notificationBody = 'রোগী: $patientName | জরুরি: $urgencyText | ফোন: ${userData?['phone'] ?? 'N/A'}';

      // Send FCM notification
      print('🚑 Calling _sendFCMNotification with token: ${fcmToken.substring(0, 20)}...');
      final success = await _sendFCMNotification(
        fcmToken: fcmToken,
        title: '🚑 জরুরি অ্যাম্বুলেন্স রিকুয়েস্ট',
        body: notificationBody,
        data: notificationData,
      );
      print('🚑 FCM notification result: $success');

      // Store notification in partner's notifications collection (for both background and foreground display)
      await addPartnerNotification(
        partnerId: partnerId,
        title: '🚑 জরুরি অ্যাম্বুলেন্স রিকুয়েস্ট',
        message: notificationBody,
        type: 'emergency',
        data: notificationData,
      );

      // Save notification log
      await FirebaseFirestore.instance.collection('notification_logs').add({
        'type': 'ambulance_request_fcm_v1',
        'fromUserId': currentUser.uid,
        'toPartnerId': partnerId,
        'orderId': requestData['orderId'],
        'fcmToken': fcmToken,
        'timestamp': FieldValue.serverTimestamp(),
        'success': success,
        'method': 'fcm_v1_api',
      });

      if (success) {
        Get.snackbar(
          '✅ সফল',
          'অ্যাম্বুলেন্স পার্টনারের কাছে রিকুয়েস্ট পাঠানো হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        );
        print('✅ Ambulance notification sent successfully via FCM V1 API');
        return true;
      } else {
        // Fallback: save as pending notification
        await FirebaseFirestore.instance.collection('pending_notifications').add({
          'type': 'ambulance_request',
          'partnerId': partnerId,
          'userId': currentUser.uid,
          'requestData': requestData,
          'timestamp': FieldValue.serverTimestamp(),
        });

        Get.snackbar(
          '✅ সফল',
          'অ্যাম্বুলেন্স পার্টনারের কাছে রিকুয়েস্ট পাঠানো হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        );
        return true; // Still return true for UX
      }
    } catch (e) {
      print('❌ Error sending ambulance notification via FCM V1: $e');

      // On error, save as pending and show success for UX
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance.collection('pending_notifications').add({
            'type': 'ambulance_request',
            'partnerId': partnerId,
            'userId': currentUser.uid,
            'requestData': requestData,
            'timestamp': FieldValue.serverTimestamp(),
            'error': e.toString(),
          });
        }
      } catch (logError) {
        print('❌ Error saving pending notification: $logError');
      }

      Get.snackbar(
        '✅ সফল',
        'অ্যাম্বুলেন্স পার্টনারের কাছে রিকুয়েস্ট পাঠানো হয়েছে',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 3),
      );

      return true; // Always return true for partners to maintain UX
    }
  }

  /// Test FCM token validity by sending a test notification
  static Future<bool> testFCMToken(String fcmToken) async {
    try {
      print('🧪 Testing FCM token: ${fcmToken.substring(0, 20)}...');

      final accessToken = await _getAccessToken();

      final message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': 'Test Notification',
            'body': 'This is a test to verify FCM token validity',
          },
          'data': {
            'type': 'test',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
          'android': {
            'priority': 'high',
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      print('🧪 Test FCM Response Status: ${response.statusCode}');
      print('🧪 Test FCM Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['name'] != null) {
          print('✅ FCM token is valid');
          return true;
        }
      }

      print('❌ FCM token test failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('❌ Error testing FCM token: $e');
      return false;
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        final payload = response.payload;
        if (payload != null) {
          try {
            final data = json.decode(payload) as Map<String, dynamic>;
            handleNotificationTap(data);
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      showBadge: true,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    print('🔔 Showing local notification for message: ${message.messageId}');
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      print('📱 Notification title: ${notification.title}');
      print('📱 Notification body: ${notification.body}');
      print('📱 Notification data: $data');

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        message.hashCode,
        notification.title ?? 'Notification',
        notification.body ?? '',
        platformChannelSpecifics,
        payload: json.encode(data),
      );
      print('✅ Local notification shown successfully');
    } else {
      print('❌ No notification object in FCM message');
    }
  }

  /// Initializes FCM token for the current device and saves it to user profile
  static Future<String?> initializeFCMToken() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Request notification permissions
      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
      } else {
        print('❌ Notification permission denied');
        return null;
      }

      // Get FCM token
      final String? token = await messaging.getToken();
      
      if (token != null) {
        print('📱 FCM Token obtained: ${token.substring(0, 20)}...');
        
        // Save token to user's profile in Firestore
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print('👤 Current user ID: ${currentUser.uid}');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'fcmToken': token,
            'lastTokenUpdate': Timestamp.now(),
          });

          // Also update partners collection if user is a driver/partner
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data();
            final role = userData?['role'] as String?;
            print('👤 User role: $role');
            
            if (role == 'partner' || role == 'driver' || role == 'ambulance') {
              print('💾 Saving FCM token to partners collection for role: $role');
              await FirebaseFirestore.instance
                  .collection('partners')
                  .doc(currentUser.uid)
                  .update({
                'fcmToken': token,
                'lastTokenUpdate': Timestamp.now(),
              });
              print('✅ FCM token saved to partners collection');
            } else {
              print('❌ User role "$role" not eligible for partners collection FCM token');
            }
          }
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) {
          print('📱 FCM Token refreshed: ${newToken.substring(0, 20)}...');
          // Update token in Firestore when it refreshes
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .update({
                  'fcmToken': newToken,
                  'lastTokenUpdate': Timestamp.now(),
                });

            // Also update partners collection if needed
            _updatePartnerTokenIfApplicable(currentUser.uid, newToken);
          }
        });
      }
      
      return token;
    } catch (e) {
      print('❌ Error initializing FCM token: $e');
      return null;
    }
  }

  /// Helper method to update partner token if user is a partner/driver
  static Future<void> _updatePartnerTokenIfApplicable(String userId, String token) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role'] as String?;

        if (role == 'partner' || role == 'driver' || role == 'ambulance') {
          await FirebaseFirestore.instance
              .collection('partners')
              .doc(userId)
              .update({
                'fcmToken': token,
                'lastTokenUpdate': Timestamp.now(),
              });
          print('✅ Partner FCM token updated for user: $userId');
        }
      }
    } catch (e) {
      print('❌ Error updating partner token: $e');
    }
  }

  /// Show background notification (called from main.dart background handler)
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    // Initialize local notifications if not already done
    await _initializeLocalNotifications();
    await _showLocalNotification(message);

    // Try to store notification in partner's collection if we can determine the partner ID
    // For ambulance requests, the partner ID should be in the data
    final data = message.data;
    final partnerId = data['partnerId'] ?? data['toPartnerId'];

    if (partnerId != null && partnerId.isNotEmpty && message.notification != null) {
      try {
        await addPartnerNotification(
          partnerId: partnerId,
          title: message.notification!.title ?? 'Background Notification',
          message: message.notification!.body ?? '',
          type: data['type'] ?? 'info',
          data: data,
        );
        print('✅ Background notification stored for partner: $partnerId');
      } catch (e) {
        print('❌ Error storing background notification: $e');
      }
    } else {
      print('⚠️ Could not determine partner ID for background notification storage');
    }
  }

  /// Initialize local notifications for background handler (separate from main initialization)
  static Future<void> initializeLocalNotificationsForBackground() async {
    print('🔧 Initializing local notifications for background...');
    await _initializeLocalNotifications();
  }

  /// Ensure FCM is properly initialized on app startup
  static Future<void> ensureFCMInitialized() async {
    try {
      print('🔧 Ensuring FCM is initialized...');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user for FCM initialization');
        return;
      }

      // Check if user already has FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final existingToken = userData?['fcmToken'];

        if (existingToken != null && existingToken.isNotEmpty) {
          print('✅ FCM token already exists for user');
          return;
        }
      }

      // Initialize FCM if no token exists
      print('📱 Initializing FCM token for user...');
      await initializeFCMToken();

    } catch (e) {
      print('❌ Error ensuring FCM initialization: $e');
    }
  }

  /// Comprehensive FCM setup for app startup
  static Future<void> setupFCMOnAppStart() async {
    try {
      print('🚀 Setting up FCM on app start...');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup foreground message handling
      setupForegroundNotificationHandling();

      // Ensure FCM token is initialized
      await ensureFCMInitialized();

      print('✅ FCM setup completed');

    } catch (e) {
      print('❌ Error setting up FCM: $e');
    }
  }

  /// Sets up foreground notification handling
  static void setupForegroundNotificationHandling() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📩 Received foreground message: ${message.notification?.title}');

      // Show local notification for foreground messages
      await _showLocalNotification(message);

      // Add notification to partner's notification list for UI display
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && message.notification != null) {
        try {
          await addPartnerNotification(
            partnerId: currentUser.uid,
            title: message.notification!.title ?? 'Notification',
            message: message.notification!.body ?? '',
            type: message.data['type'] ?? 'info',
            data: message.data,
          );
          print('✅ Foreground notification added to partner list');
        } catch (e) {
          print('❌ Error adding foreground notification to partner list: $e');
        }
      }

      // Handle the notification when app is in foreground
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'Notification',
          message.notification!.body ?? '',
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade800,
          duration: const Duration(seconds: 4),
          onTap: (snack) {
            // Handle notification tap
            handleNotificationTap(message.data);
          },
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from notification: ${message.notification?.title}');

      // Add notification to partner's notification list if not already added
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && message.notification != null) {
        try {
          addPartnerNotification(
            partnerId: currentUser.uid,
            title: message.notification!.title ?? 'Notification',
            message: message.notification!.body ?? '',
            type: message.data['type'] ?? 'info',
            data: message.data,
          );
          print('✅ Background notification added to partner list when app opened');
        } catch (e) {
          print('❌ Error adding background notification to partner list: $e');
        }
      }

      handleNotificationTap(message.data);
    });
  }

  /// Handles notification tap actions
  static void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'ride_request':
        // Navigate to ride requests page
        print('📱 Opening ride request: ${data['requestId']}');
        // Get.toNamed('/ride-requests', arguments: data);
        break;
      case 'ambulance_request':
        // Navigate to home partner page and show bottom sheet for the request
        print('🚑 Opening ambulance request: ${data['orderId']}');
        _navigateToHomePartnerWithRequest(data['orderId']);
        break;
      case 'emergency':
        // Navigate to emergency response page
        print('🚨 Opening emergency: ${data['emergencyId']}');
        // Get.toNamed('/emergency-response', arguments: data);
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  /// Navigate to home partner page and show bottom sheet for specific request
  static void _navigateToHomePartnerWithRequest(String? orderId) {
    if (orderId == null || orderId.isEmpty) {
      print('❌ No orderId provided for notification navigation');
      return;
    }

    try {
      // Navigate to home partner page
      Get.offAllNamed('/home-partner'); // Use offAll to clear navigation stack

      // Wait for navigation to complete, then show bottom sheet
      Future.delayed(const Duration(milliseconds: 500), () {
        // Get the HomePartnerController and show bottom sheet for the request
        final controller = Get.find<HomePartnerController>();
        controller.showBottomSheetForRequest(orderId);
      });
    } catch (e) {
      print('❌ Error navigating to home partner with request: $e');
    }
  }

  /// Test local notification (for debugging)
  static Future<void> testLocalNotification() async {
    print('🧪 Testing local notification...');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification to verify local notifications work',
      platformChannelSpecifics,
      payload: '{"type": "test"}',
    );

        print('✅ Test notification sent');
  }

  /// Test FCM V1 notification (for debugging)
  static Future<void> testFCMV1Notification() async {
    try {
      print('🧪 Testing FCM V1 notification...');

      // Test with a dummy FCM token (replace with real token for testing)
      const testFcmToken = 'test_fcm_token_here';

      final success = await _sendFCMNotification(
        fcmToken: testFcmToken,
        title: '🧪 FCM V1 Test',
        body: 'This is a test notification from FCM V1 API',
        data: {
          'type': 'test',
          'message': 'FCM V1 API is working!',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (success) {
        print('✅ FCM V1 test notification sent successfully');
        Get.snackbar(
          '✅ Test Success',
          'FCM V1 notification sent successfully',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        print('❌ FCM V1 test notification failed');
        Get.snackbar(
          '❌ Test Failed',
          'FCM V1 notification failed',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      print('❌ Error testing FCM V1: $e');
      Get.snackbar(
        '❌ Test Error',
        'Error testing FCM V1: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Add a notification to a partner's notification collection
  static Future<void> addPartnerNotification({
    required String partnerId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'data': data ?? {},
      };

      await FirebaseFirestore.instance
          .collection('partners')
          .doc(partnerId)
          .collection('notifications')
          .add(notificationData);

      debugPrint('✅ Partner notification added: $title');
    } catch (e) {
      debugPrint('❌ Failed to add partner notification: $e');
    }
  }

  /// Send notification to all online partners (for new orders, etc.)
  static Future<void> notifyAllOnlinePartners({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final partnersSnapshot = await FirebaseFirestore.instance
          .collection('partners')
          .where('isOnline', isEqualTo: true)
          .get();

      for (final partnerDoc in partnersSnapshot.docs) {
        final partnerId = partnerDoc.id;
        await addPartnerNotification(
          partnerId: partnerId,
          title: title,
          message: message,
          type: type,
          data: data,
        );

        // Also send push notification if FCM token exists
        final fcmToken = partnerDoc.data()['fcmToken'];
        if (fcmToken != null) {
          await sendFCMNotification(
            token: fcmToken,
            title: title,
            body: message,
            data: data,
          );
        }
      }

      debugPrint('✅ Notified ${partnersSnapshot.docs.length} online partners');
    } catch (e) {
      debugPrint('❌ Failed to notify partners: $e');
    }
  }
}