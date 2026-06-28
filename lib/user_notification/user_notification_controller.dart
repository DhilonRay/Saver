import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';

class UserNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'ambulance', 'system', 'emergency', 'info'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data like requestId, partnerId, etc.

  UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory UserNotification.fromMap(String id, Map<String, dynamic> data) {
    DateTime parsedTimestamp = DateTime.now();
    if (data['timestamp'] != null) {
      parsedTimestamp = DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now();
    } else if (data['createdAt'] != null) {
      parsedTimestamp = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
    } else if (data['created_at'] != null) {
      parsedTimestamp = DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now();
    }

    return UserNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? data['body'] ?? '',
      type: data['type'] ?? 'info',
      timestamp: parsedTimestamp,
      isRead: data['isRead'] ?? data['is_read'] ?? false,
      data: data['data'] ?? data['extraData'] ?? data['extra_data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }
}

class UserNotificationController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<UserNotification> notifications = <UserNotification>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt unreadCount = 0.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;
  SharedPreferences? _prefs;
  String get _currentUserId => _auth.currentUser?.uid ?? '';
  String get _localStorageKey => 'user_notifications_${_currentUserId}';

  @override
  void onInit() {
    super.onInit();
    _initLocalStorage();
  }

  Future<void> _initLocalStorage() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadNotificationsFromLocal();
      _setupNotificationsStream();
    } catch (e) {
      error.value = 'Failed to initialize: $e';
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _notificationsSubscription?.cancel();
    super.onClose();
  }

  // Local Storage Methods
  Future<void> _loadNotificationsFromLocal() async {
    if (_prefs == null || _currentUserId.isEmpty) return;

    final storedData = _prefs!.getString(_localStorageKey);
    if (storedData != null) {
      try {
        final List<dynamic> notificationsData = json.decode(storedData);
        final localNotifications = notificationsData.map((data) {
          return UserNotification(
            id: data['id'],
            title: data['title'],
            message: data['message'],
            type: data['type'],
            timestamp: DateTime.parse(data['timestamp']),
            isRead: data['isRead'] ?? false,
            data: data['data'],
          );
        }).toList();

        notifications.value = localNotifications;
        unreadCount.value = localNotifications.where((n) => !n.isRead).length;
        isLoading.value = false;
      } catch (e) {
        // Silent error handling
      }
    } else {
      isLoading.value = false;
    }
  }

  Future<void> _saveNotificationsToLocal() async {
    if (_prefs == null || _currentUserId.isEmpty) return;

    try {
      final notificationsData = notifications.map((notification) {
        return {
          'id': notification.id,
          'title': notification.title,
          'message': notification.message,
          'type': notification.type,
          'timestamp': notification.timestamp.toIso8601String(),
          'isRead': notification.isRead,
          'data': notification.data,
        };
      }).toList();

      await _prefs!.setString(_localStorageKey, json.encode(notificationsData));
    } catch (e) {
      print('Error saving notifications to local: $e');
    }
  }

  void _setupNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      error.value = 'User not logged in';
      isLoading.value = false;
      return;
    }

    _notificationsSubscription = SupabaseService.streamUserNotifications(user.uid)
        .listen(
          (list) {
            notifications.value = list.map((item) {
              final camelCased = SupabaseService.toCamelCase(item);
              return UserNotification.fromMap(
                camelCased['uid'] ?? camelCased['id'] ?? '',
                camelCased,
              );
            }).toList();

            // Sort notifications descending by timestamp
            notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            // Update unread count
            unreadCount.value = notifications.where((n) => !n.isRead).length;

            // Save to local storage
            _saveNotificationsToLocal();

            isLoading.value = false;
            error.value = '';
          },
          onError: (e) {
            error.value = 'Failed to load notifications: $e';
            isLoading.value = false;
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await SupabaseService.updateUserNotification(notificationId, {'isRead': true});

      // Update local list
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = UserNotification(
          id: notifications[index].id,
          title: notifications[index].title,
          message: notifications[index].message,
          type: notifications[index].type,
          timestamp: notifications[index].timestamp,
          isRead: true,
          data: notifications[index].data,
        );
        unreadCount.value = notifications.where((n) => !n.isRead).length;
        _saveNotificationsToLocal();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final unreadNotifications = notifications.where((n) => !n.isRead);

      for (final notification in unreadNotifications) {
        await SupabaseService.updateUserNotification(notification.id, {'isRead': true});
      }

      // Update local list
      for (int i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = UserNotification(
            id: notifications[i].id,
            title: notifications[i].title,
            message: notifications[i].message,
            type: notifications[i].type,
            timestamp: notifications[i].timestamp,
            isRead: true,
            data: notifications[i].data,
          );
        }
      }
      unreadCount.value = 0;
      _saveNotificationsToLocal();
    } catch (e) {
      Get.snackbar('Error', 'Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await SupabaseService.deleteUserNotification(notificationId);

      // Remove from local list
      notifications.removeWhere((n) => n.id == notificationId);
      unreadCount.value = notifications.where((n) => !n.isRead).length;
      _saveNotificationsToLocal();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await SupabaseService.deleteAllUserNotifications(user.uid);
      notifications.clear();
      unreadCount.value = 0;
      _saveNotificationsToLocal();
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear notifications: $e');
    }
  }

  // Method to add a test notification (for development)
  Future<void> addTestNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Create different types of test notifications
      final List<Map<String, dynamic>> testNotifications = [
        {
          'title': '🚑 অ্যাম্বুলেন্স সেবা গ্রহণ করা হয়েছে',
          'message': 'আপনার অ্যাম্বুলেন্স রিকুয়েস্ট গ্রহণ করা হয়েছে। পার্টনার খুব শীঘ্রই আপনার কাছে পৌঁছাবে।',
          'type': 'ambulance'
        },
        {
          'title': '📍 অ্যাম্বুলেন্স আপনার কাছাকাছি',
          'message': 'আপনার অ্যাম্বুলেন্স ৫ মিনিটের মধ্যে পৌঁছাবে। প্রস্তুত থাকুন।',
          'type': 'emergency'
        },
        {
          'title': '✅ সেবা সম্পন্ন হয়েছে',
          'message': 'আপনার অ্যাম্বুলেন্স সেবা সফলভাবে সম্পন্ন হয়েছে। আমাদের সেবা নিয়ে রিভিউ দিন।',
          'type': 'system'
        }
      ];

      final random = DateTime.now().millisecond % testNotifications.length;
      final testData = testNotifications[random];

      await SupabaseService.addUserNotification(
        user.uid,
        {
          'title': testData['title'],
          'body': testData['message'],
          'type': testData['type'],
          'is_read': false,
          'extra_data': {
            'requestId': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
            'partnerId': 'test_partner_123',
            'type': 'ambulance_request'
          },
        },
      );

      Get.snackbar(
        'সফল', 
        'টেস্ট নোটিফিকেশন যোগ করা হয়েছে',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to add test notification: $e');
    }
  }
}
