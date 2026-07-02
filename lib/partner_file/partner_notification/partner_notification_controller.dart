import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';
import 'package:saver/components/alert.dart';

class PartnerNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'order', 'system', 'emergency', 'info'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data like orderId, userId, etc.

  PartnerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory PartnerNotification.fromMap(String id, Map<String, dynamic> data) {
    DateTime parsedTimestamp = DateTime.now();
    if (data['timestamp'] != null) {
      parsedTimestamp = DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now();
    } else if (data['createdAt'] != null) {
      parsedTimestamp = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
    } else if (data['created_at'] != null) {
      parsedTimestamp = DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now();
    }

    return PartnerNotification(
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

class PartnerNotificationController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<PartnerNotification> notifications = <PartnerNotification>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt unreadCount = 0.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;
  SharedPreferences? _prefs;
  String get _currentUserId => _auth.currentUser?.uid ?? '';
  String get _localStorageKey => 'partner_notifications_${_currentUserId}';

  @override
  void onInit() {
    super.onInit();
    _initLocalStorage();
  }

  Future<void> _initLocalStorage() async {
    _prefs = await SharedPreferences.getInstance();
    _loadNotificationsFromLocal();
    _setupNotificationsStream();
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
          return PartnerNotification(
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
        print('Error loading local notifications: $e');
      }
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

    _notificationsSubscription = SupabaseService.streamPartnerNotifications(user.uid)
        .listen(
          (list) {
            notifications.value = list.map((item) {
              final camelCased = SupabaseService.toCamelCase(item);
              return PartnerNotification.fromMap(
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

      await SupabaseService.updatePartnerNotification(notificationId, {'isRead': true});

      // Update local list
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = PartnerNotification(
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
      Alert.error('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final unreadNotifications = notifications.where((n) => !n.isRead);

      for (final notification in unreadNotifications) {
        await SupabaseService.updatePartnerNotification(notification.id, {'isRead': true});
      }

      // Update local list
      for (int i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = PartnerNotification(
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
      Alert.error('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await SupabaseService.deletePartnerNotification(notificationId);

      // Remove from local list
      notifications.removeWhere((n) => n.id == notificationId);
      unreadCount.value = notifications.where((n) => !n.isRead).length;
      _saveNotificationsToLocal();
    } catch (e) {
      Alert.error('Failed to delete notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await SupabaseService.deleteAllPartnerNotifications(user.uid);
      notifications.clear();
      unreadCount.value = 0;
      _saveNotificationsToLocal();
    } catch (e) {
      Alert.error('Failed to clear notifications: $e');
    }
  }

  // Method to add a test notification (for development)
  Future<void> addTestNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await SupabaseService.addPartnerNotification(
        user.uid,
        {
          'title': 'Test Notification',
          'body': 'This is a test notification for partners',
          'type': 'info',
          'is_read': false,
        },
      );
    } catch (e) {
      Alert.error('Failed to add test notification: $e');
    }
  }
}
