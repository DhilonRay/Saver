import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' as services;
import '../partner_file/home_partner/home_partner_controller.dart';
import 'package:saver/components/constants/alert.dart';

class NotificationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // FCM V1 API Configuration
  static const String _fcmProjectId = 'neosaver-f06e9';
  static const String _fcmUrl =
      'https://fcm.googleapis.com/v1/projects/$_fcmProjectId/messages:send';

  // Load Service Account Credentials for FCM V1 from assets
  static Future<Map<String, dynamic>> _loadServiceAccount() async {
    final String jsonString =
        await services.rootBundle.loadString('assets/service_account.json');
    return json.decode(jsonString);
  }

  /// Generate JWT access token for FCM V1 API using googleapis_auth
  static Future<String> _getAccessToken() async {
    try {
      // Load service account credentials from assets
      final serviceAccount = await _loadServiceAccount();

      // Create service account credentials from loaded data
      final serviceAccountCredentials =
          auth.ServiceAccountCredentials.fromJson(serviceAccount);

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

      print(
          '❌ FCM V1 notification failed: ${response.statusCode} - ${response.body}');
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
      print(
          '🚀 Calling Firebase Function to send notification to driver: $driverId');

      final HttpsCallable callable =
          _functions.httpsCallable('sendNotificationToDriver');

      final result = await callable.call({
        'driverId': driverId,
        'requestData': requestData,
      });

      final data = result.data;

      if (data['success'] == true) {
        print('✅ Notification sent successfully via Firebase Function');
        print('📱 Message ID: ${data['messageId']}');

        Alert.info('ড্রাইভারের কাছে আপনার রিকুয়েস্ট পাঠানো হয়েছে');
        return true;
      } else {
        print('❌ Failed to send notification: ${data['message']}');
        Alert.error('নোটিফিকেশন পাঠাতে সমস্যা হয়েছে');
        return false;
      }
    } catch (e) {
      print('❌ Error calling Firebase Function: $e');
      Alert.error('নোটিফিকেশন পাঠাতে সমস্যা হয়েছে: $e');
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

      final HttpsCallable callable =
          _functions.httpsCallable('sendNotificationToNearbyDrivers');

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

        print(
            '✅ Found $totalFound total drivers, $nearbyCount within ${radiusInKm}km');

        if (nearbyCount > 0) {
          Alert.info(
              '$nearbyCount জন ড্রাইভারের কাছে রিকুয়েস্ট পাঠানো হয়েছে');
        } else {
          Alert.info('আশেপাশে কোন অনলাইন ড্রাইভার পাওয়া যায়নি');
        }
        return true;
      } else {
        print('❌ Failed to send notifications: ${data['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notifications to nearby drivers: $e');
      Alert.error('আশেপাশের ড্রাইভারদের খুঁজে পেতে সমস্যা হয়েছে: $e');
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

      final HttpsCallable callable =
          _functions.httpsCallable('sendAmbulanceNotification');

      final result = await callable.call({
        'partnerId': partnerId,
        'requestData': requestData,
      });

      final data = result.data;
      print('🚑 Cloud Function Response: $data');

      if (data['success'] == true) {
        print('✅ Ambulance notification sent successfully');
        print('📱 Message ID: ${data['messageId']}');

        Alert.info('অ্যাম্বুলেন্স পার্টনারের কাছে রিকুয়েস্ট পাঠানো হয়েছে');
        return true;
      } else {
        print('❌ Failed to send ambulance notification: ${data['message']}');
        Alert.error(
            'অ্যাম্বুলেন্স নোটিফিকেশন পাঠাতে সমস্যা: ${data['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending ambulance notification: $e');
      Alert.error('অ্যাম্বুলেন্স রিকুয়েস্ট পাঠাতে সমস্যা হয়েছে: $e');
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

      // Get partner's FCM token from Supabase
      final partnerDocMap = await SupabaseService.getPartner(partnerId);

      if (partnerDocMap == null) {
        throw Exception('Partner not found');
      }

      final partnerData = SupabaseService.toCamelCase(partnerDocMap);
      final fcmToken = partnerData['fcmToken'] as String?;

      print('🚑 Partner data: $partnerData');
      print('🚑 FCM Token: $fcmToken');

      // Validate FCM token format
      if (fcmToken == null || fcmToken.isEmpty || fcmToken.length < 20) {
        print(
            '⚠️ Partner FCM token invalid or too short (length: ${fcmToken?.length}), saving notification for later');
        // Save notification for when partner comes online
        await SupabaseService.client.from('pending_notifications').insert({
          'type': 'ambulance_request',
          'partner_id': partnerId,
          'user_id': currentUser.uid,
          'request_data': requestData,
          'timestamp': DateTime.now().toIso8601String(),
        });

        return true;
      }

      // Get user data for notification content
      final userDocMap = await SupabaseService.getUser(currentUser.uid);
      final userData = userDocMap != null ? SupabaseService.toCamelCase(userDocMap) : null;
      final patientName =
          requestData['patientName'] ?? userData?['name'] ?? 'রোগী';

      // Prepare comprehensive notification data with full user details
      final notificationData = {
        'type': 'ambulance_request',
        'orderId': requestData['orderId'] ?? '',
        'userId': currentUser.uid,
        'partnerId':
            partnerId, // Add partner ID for background notification storage
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),

        // Patient Information
        'patientName': patientName,
        'patientAge': requestData['patientAge'] ?? userData?['age'] ?? '',
        'patientGender':
            requestData['patientGender'] ?? userData?['gender'] ?? '',
        'bloodType': requestData['bloodType'] ?? userData?['bloodType'] ?? '',

        // Contact Information
        'userPhone': userData?['phone'] ?? '',
        'userEmail': userData?['email'] ?? currentUser.email ?? '',
        'emergencyContact': requestData['emergencyContact'] ??
            userData?['emergencyContact'] ??
            '',
        'emergencyPhone':
            requestData['emergencyPhone'] ?? userData?['emergencyPhone'] ?? '',

        // Location Information
        'pickupLocation': json.encode(requestData['userLocation'] ?? {}),
        'pickupAddress': requestData['pickupAddress'] ?? '',
        'destinationAddress': requestData['destinationAddress'] ?? '',

        // Medical Information
        'urgency': requestData['urgency'] ?? 'high',
        'medicalCondition': requestData['medicalCondition'] ??
            userData?['medicalCondition'] ??
            '',
        'allergies': requestData['allergies'] ?? userData?['allergies'] ?? '',
        'medications':
            requestData['medications'] ?? userData?['medications'] ?? '',
        'specialNeeds':
            requestData['specialNeeds'] ?? userData?['specialNeeds'] ?? '',

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
      final urgencyText = requestData['urgency'] == 'critical'
          ? 'জরুরি'
          : requestData['urgency'] == 'high'
              ? 'উচ্চ'
              : requestData['urgency'] == 'medium'
                  ? 'মাঝারি'
                  : 'সাধারণ';

      final notificationBody =
          'রোগী: $patientName | জরুরি: $urgencyText | ফোন: ${userData?['phone'] ?? 'N/A'}';

      // Send FCM notification
      print(
          '🚑 Calling _sendFCMNotification with token: ${fcmToken.substring(0, 20)}...');
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
      await SupabaseService.client.from('notification_logs').insert({
        'type': 'ambulance_request_fcm_v1',
        'from_user_id': currentUser.uid,
        'to_partner_id': partnerId,
        'order_id': requestData['orderId'],
        'fcm_token': fcmToken,
        'timestamp': DateTime.now().toIso8601String(),
        'success': success,
        'method': 'fcm_v1_api',
      });

      if (success) {
        print('✅ Ambulance notification sent successfully via FCM V1 API');
        return true;
      } else {
        // Fallback: save as pending notification
        await SupabaseService.client.from('pending_notifications').insert({
          'type': 'ambulance_request',
          'partner_id': partnerId,
          'user_id': currentUser.uid,
          'request_data': requestData,
          'timestamp': DateTime.now().toIso8601String(),
        });

        return true; // Still return true for UX
      }
    } catch (e) {
      print('❌ Error sending ambulance notification via FCM V1: $e');

      // On error, save as pending and show success for UX
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await SupabaseService.client.from('pending_notifications').insert({
            'type': 'ambulance_request',
            'partner_id': partnerId,
            'user_id': currentUser.uid,
            'request_data': requestData,
            'timestamp': DateTime.now().toIso8601String(),
            'error': e.toString(),
          });
        }
      } catch (logError) {
        print('❌ Error saving pending notification: $logError');
      }

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

      print(
          '❌ FCM token test failed: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('❌ Error testing FCM token: $e');
      return false;
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
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

    // Create user notification channel
    const AndroidNotificationChannel userChannel = AndroidNotificationChannel(
      'user_notifications',
      'User Notifications',
      description: 'This channel is used for user ambulance notifications.',
      importance: Importance.high,
      showBadge: true,
      playSound: true,
      enableVibration: true,
    );

    // Create ambulance requests notification channel (CRITICAL FIX)
    const AndroidNotificationChannel ambulanceChannel =
        AndroidNotificationChannel(
      'ambulance_requests',
      'Ambulance Requests',
      description: 'This channel is used for incoming ambulance requests.',
      importance: Importance.max,
      showBadge: true,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(userChannel);
    await androidPlugin?.createNotificationChannel(ambulanceChannel);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    print('🔔 Showing local notification for message: ${message.messageId}');
    final notification = message.notification;
    final data = message.data;

    final type = data['type'];
    // Check if it's a critical notification type that should always show
    final isCritical = type == 'ambulance_request' ||
        type == 'emergency' ||
        type == 'ride_request';

    if (notification != null || isCritical) {
      final title = notification?.title ?? data['title'] ?? 'New Request';
      final body = notification?.body ??
          data['body'] ??
          data['message'] ??
          'You have a new request';

      print('📱 Local Notification Title: $title');
      print('📱 Local Notification Body: $body');
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
        icon: '@drawable/notification_icon',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
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
        title,
        body,
        platformChannelSpecifics,
        payload: json.encode(data),
      );
      print('✅ Local notification shown successfully');
    } else {
      print('❌ No notification object in FCM message and not a critical type');
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

        // Save token to user's profile in Firestore (Try both users and drivers collections)
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print('👤 Current user ID: ${currentUser.uid}');

          // Try updating users collection
          bool updatedInUsers = false;
          try {
            await SupabaseService.updateUser(currentUser.uid, {
              'fcmToken': token,
              'lastTokenUpdate': DateTime.now().toIso8601String(),
            });
            updatedInUsers = true;
            print('✅ FCM token updated in users collection');
          } catch (e) {
            print('ℹ️ User not found in users collection, trying drivers...');
          }

          // Try updating drivers collection
          bool updatedInDrivers = false;
          try {
            await SupabaseService.updateDriver(currentUser.uid, {
              'fcmToken': token,
              'lastTokenUpdate': DateTime.now().toIso8601String(),
            });
            updatedInDrivers = true;
            print('✅ FCM token updated in drivers collection');
          } catch (e) {
            print('ℹ️ User not found in drivers collection');
          }

          // Also update partners collection if user is a driver/partner
          // We check both collections to find the role
          String? role;
          if (updatedInUsers) {
            final userDoc = await SupabaseService.getUser(currentUser.uid);
            role = userDoc != null ? SupabaseService.toCamelCase(userDoc)['role'] : null;
          }

          if (role == null && updatedInDrivers) {
            final driverDoc = await SupabaseService.getDriver(currentUser.uid);
            role = driverDoc != null ? SupabaseService.toCamelCase(driverDoc)['role'] : null;
          }

          print('👤 User role identified: $role');

          if (role == 'partner' || role == 'driver' || role == 'ambulance') {
            print('💾 Saving FCM token to partners collection for role: $role');
            await SupabaseService.client.from('partners').upsert({
              'id': currentUser.uid,
              'fcm_token': token,
              'last_token_update': DateTime.now().toIso8601String(),
            });
            print('✅ FCM token saved to partners collection');
          }
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) {
          print('📱 FCM Token refreshed: ${newToken.substring(0, 20)}...');
          // Update token in Firestore when it refreshes
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            SupabaseService.updateUser(currentUser.uid, {
              'fcmToken': newToken,
              'lastTokenUpdate': DateTime.now().toIso8601String(),
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
  static Future<void> _updatePartnerTokenIfApplicable(
      String userId, String token) async {
    try {
      // Check users collection
      final userDoc = await SupabaseService.getUser(userId);

      String? role;
      if (userDoc != null) {
        role = SupabaseService.toCamelCase(userDoc)['role'];
      } else {
        // Check drivers collection
        final driverDoc = await SupabaseService.getDriver(userId);
        if (driverDoc != null) {
          role = SupabaseService.toCamelCase(driverDoc)['role'];
        }
      }

      if (role == 'partner' || role == 'driver' || role == 'ambulance') {
        await SupabaseService.client.from('partners').upsert({
          'id': userId,
          'fcm_token': token,
          'last_token_update': DateTime.now().toIso8601String(),
        });
        print('✅ Partner FCM token updated for user: $userId');
      }
    } catch (e) {
      print('❌ Error updating partner token: $e');
    }
  }

  /// Show background notification (called from main.dart background handler)
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    // Initialize local notifications if not already done
    // Initialize local notifications if not already done
    await _initializeLocalNotifications();

    // Skip local notification if message has notification payload (System handles it in background)
    // UNLESS it's a critical partner notification which needs explicit handling
    final data = message.data;
    final isPartnerRequest =
        data['type'] == 'ambulance_request' || data['type'] == 'emergency';

    if (message.notification == null || isPartnerRequest) {
      await _showLocalNotification(message);
    } else {
      print(
          '🔕 Skipping local notification in background to prevent duplicate (System handles it)');
    }

    // Handle User Notification Storage (New)
    final userId = data['userId'] ?? data['toUserId'];
    if (userId != null && userId.isNotEmpty && message.notification != null) {
      try {
        await SupabaseService.client.from('user_notifications').insert({
          'user_id': userId,
          'title': message.notification!.title ?? 'Notification',
          'message': message.notification!.body ?? '',
          'type': data['type'] ?? 'info',
          'is_read': false,
          'timestamp': DateTime.now().toIso8601String(),
          'data': data,
        });
        print('✅ Background notification stored for user: $userId');
      } catch (e) {
        print('❌ Error storing background notification for user: $e');
      }
    }

    final partnerId = data['partnerId'] ?? data['toPartnerId'];

    if (partnerId != null &&
        partnerId.isNotEmpty &&
        message.notification != null) {
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
      print(
          '⚠️ Could not determine partner ID for background notification storage');
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
      final userDoc = await SupabaseService.getUser(currentUser.uid);

      if (userDoc != null) {
        final userData = SupabaseService.toCamelCase(userDoc);
        final existingToken = userData['fcmToken'];

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

      // Handle the initial message if the app was opened from a terminated state
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print(
            '📱 App opened from terminated state via notification: ${initialMessage.notification?.title}');
        handleNotificationTap(initialMessage.data);
      }

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

      // Add notification to user/partner notification list for UI display
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && message.notification != null) {
        try {
          // Check if this is a user notification
          final notificationType = message.data['type'] ?? 'info';
          if (notificationType.contains('ambulance') ||
              notificationType.contains('user')) {
            // Add to user notifications
            await SupabaseService.client.from('user_notifications').insert({
              'user_id': currentUser.uid,
              'title': message.notification!.title ?? 'Notification',
              'message': message.notification!.body ?? '',
              'type': notificationType,
              'is_read': false,
              'timestamp': DateTime.now().toIso8601String(),
              'data': message.data,
            });
            print('✅ Foreground notification added to user list');
          } else {
            // Add to partner notifications (existing logic)
            await addPartnerNotification(
              partnerId: currentUser.uid,
              title: message.notification!.title ?? 'Notification',
              message: message.notification!.body ?? '',
              type: notificationType,
              data: message.data,
            );
            print('✅ Foreground notification added to partner list');
          }
        } catch (e) {
          print('❌ Error adding foreground notification to list: $e');
        }
      }

      // Handle the notification when app is in foreground
      // Handle the notification when app is in foreground
      // Note: We use _showLocalNotification above instead of Get.snackbar to avoid overlay errors
      // and ensure consistent behavior with background notifications.
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
          print(
              '✅ Background notification added to partner list when app opened');
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
      icon: '@drawable/notification_icon',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
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
        Alert.info('✅ Test Success: FCM V1 notification sent successfully');
      } else {
        print('❌ FCM V1 test notification failed');
        Alert.error('❌ Test Failed: FCM V1 notification failed');
      }
    } catch (e) {
      print('❌ Error testing FCM V1: $e');
      Alert.error('❌ Test Error: Error testing FCM V1: $e');
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

      await SupabaseService.client.from('partner_notifications').insert({
        'partner_id': partnerId,
        'title': title,
        'message': message,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
        'data': data ?? {},
      });

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
      final partnersSnapshot = await SupabaseService.client
          .from('partners')
          .select()
          .eq('is_online', true);

      for (final partnerDoc in partnersSnapshot) {
        final partnerData = SupabaseService.toCamelCase(partnerDoc);
        final partnerId = partnerData['id'] ?? partnerData['uid'] ?? '';
        await addPartnerNotification(
          partnerId: partnerId,
          title: title,
          message: message,
          type: type,
          data: data,
        );

        // Also send push notification if FCM token exists
        final fcmToken = partnerData['fcmToken'];
        if (fcmToken != null) {
          await sendFCMNotification(
            token: fcmToken,
            title: title,
            body: message,
            data: data,
          );
        }
      }

      debugPrint('✅ Notified ${partnersSnapshot.length} online partners');
    } catch (e) {
      debugPrint('❌ Failed to notify partners: $e');
    }
  }

  /// Send push notification to user via FCM
  static Future<bool> sendUserNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📱 Sending notification to user: $userId');
      debugPrint('📱 Title: $title');
      debugPrint('📱 Message: $message');

      // Get user's FCM token from Firestore
      final userDoc = await SupabaseService.getUser(userId);

      if (userDoc == null) {
        debugPrint('❌ User not found');
        return false;
      }

      final userData = SupabaseService.toCamelCase(userDoc);
      final fcmToken = userData['fcmToken'] as String?;

      debugPrint('📱 User FCM Token: ${fcmToken?.substring(0, 20)}...');

      // Validate FCM token format
      if (fcmToken == null || fcmToken.isEmpty || fcmToken.length < 20) {
        debugPrint(
            '⚠️ User FCM token invalid or too short (length: ${fcmToken?.length})');
        return false;
      }

      // Get access token for FCM V1 API
      final accessToken = await _getAccessToken();
      debugPrint('📱 Access token obtained for FCM V1');

      // Prepare notification payload for FCM V1
      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': message,
          },
          'data': data != null
              ? Map<String, String>.from(
                  data.map((k, v) => MapEntry(k, v.toString())))
              : <String, String>{},
          'android': {
            'notification': {
              'channel_id': 'user_notifications',
              'sound': 'default',
              'default_vibrate_timings': true,
            },
            'priority': 'high',
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': message,
                },
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      debugPrint('📱 Sending FCM V1 request...');

      // Send notification via FCM V1 API
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(payload),
      );

      debugPrint('📱 FCM Response Status: ${response.statusCode}');
      debugPrint('📱 FCM Response Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ User notification sent successfully');
        return true;
      } else {
        debugPrint('❌ Failed to send user notification: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending user notification: $e');
      return false;
    }
  }
}
