import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return UserNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'info',
      timestamp: data['timestamp'] != null ? DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now() : DateTime.now(),
      isRead: data['isRead'] ?? false,
      data: data['data'],
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
  final SupabaseClient _supabase = Supabase.instance.client;

  final RxList<UserNotification> notifications = <UserNotification>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt unreadCount = 0.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;
  SharedPreferences? _prefs;
  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';
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
    final user = _supabase.auth.currentUser;
    if (user == null) {
      error.value = 'User not logged in';
      isLoading.value = false;
      return;
    }

    _notificationsSubscription = _supabase
        .from('user_notifications')
        .stream(primaryKey: ['id'])
        .eq('userId', user.id)
        .order('timestamp', ascending: false)
        .listen(
          (dataList) {
            notifications.value = dataList.map((data) {
              return UserNotification.fromMap(data['id'], data);
            }).toList();

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
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_notifications')
          .update({'isRead': true})
          .eq('id', notificationId)
          .eq('userId', user.id);

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
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final unreadNotifications = notifications.where((n) => !n.isRead).toList();

      for (final notification in unreadNotifications) {
        await _supabase
            .from('user_notifications')
            .update({'isRead': true})
            .eq('id', notification.id)
            .eq('userId', user.id);
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
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_notifications')
          .delete()
          .eq('id', notificationId)
          .eq('userId', user.id);

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
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Cannot easily batch delete without knowing IDs, but we can delete all matching userId
      await _supabase
          .from('user_notifications')
          .delete()
          .eq('userId', user.id);
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
      final user = _supabase.auth.currentUser;
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

      final testNotification = UserNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: testData['title'],
        message: testData['message'],
        type: testData['type'],
        timestamp: DateTime.now(),
        isRead: false,
        data: {
          'requestId': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
          'partnerId': 'test_partner_123',
          'type': 'ambulance_request'
        },
      );

      final insertData = testNotification.toMap();
      insertData['userId'] = user.id;

      await _supabase
          .from('user_notifications')
          .insert(insertData);

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
