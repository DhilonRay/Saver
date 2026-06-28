import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Centralized Supabase service for NeoSaver app.
/// Replaces all Firestore CRUD operations with Supabase PostgreSQL queries.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // =============================================
  // USERS
  // =============================================

  /// Get a user by ID
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final response =
          await client.from('users').select().eq('id', uid).maybeSingle();
      return response;
    } catch (e) {
      debugPrint('SupabaseService.getUser error: $e');
      return null;
    }
  }

  /// Create or update a user
  static Future<void> upsertUser(
      String uid, Map<String, dynamic> data) async {
    try {
      data['id'] = uid;
      data = _convertToSnakeCase(data);
      await client.from('users').upsert(data);
    } catch (e) {
      debugPrint('SupabaseService.upsertUser error: $e');
      rethrow;
    }
  }

  /// Update user fields
  static Future<void> updateUser(
      String uid, Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('users').update(data).eq('id', uid);
    } catch (e) {
      debugPrint('SupabaseService.updateUser error: $e');
      rethrow;
    }
  }

  /// Delete a user
  static Future<void> deleteUser(String uid) async {
    try {
      await client.from('users').delete().eq('id', uid);
    } catch (e) {
      debugPrint('SupabaseService.deleteUser error: $e');
      rethrow;
    }
  }

  /// Get all users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await client.from('users').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getAllUsers error: $e');
      return [];
    }
  }

  /// Stream all users (realtime)
  static Stream<List<Map<String, dynamic>>> streamUsers() {
    return client.from('users').stream(primaryKey: ['id']);
  }

  // =============================================
  // DRIVERS
  // =============================================

  static Future<Map<String, dynamic>?> getDriver(String uid) async {
    try {
      final response =
          await client.from('drivers').select().eq('id', uid).maybeSingle();
      return response;
    } catch (e) {
      debugPrint('SupabaseService.getDriver error: $e');
      return null;
    }
  }

  static Future<void> upsertDriver(
      String uid, Map<String, dynamic> data) async {
    try {
      data['id'] = uid;
      data = _convertToSnakeCase(data);
      await client.from('drivers').upsert(data);
    } catch (e) {
      debugPrint('SupabaseService.upsertDriver error: $e');
      rethrow;
    }
  }

  static Future<void> updateDriver(
      String uid, Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('drivers').update(data).eq('id', uid);
    } catch (e) {
      debugPrint('SupabaseService.updateDriver error: $e');
      rethrow;
    }
  }

  // =============================================
  // PARTNERS
  // =============================================

  static Future<Map<String, dynamic>?> getPartner(String uid) async {
    try {
      final response =
          await client.from('partners').select().eq('id', uid).maybeSingle();
      return response;
    } catch (e) {
      debugPrint('SupabaseService.getPartner error: $e');
      return null;
    }
  }

  static Future<void> upsertPartner(
      String uid, Map<String, dynamic> data) async {
    try {
      data['id'] = uid;
      data = _convertToSnakeCase(data);
      await client.from('partners').upsert(data);
    } catch (e) {
      debugPrint('SupabaseService.upsertPartner error: $e');
      rethrow;
    }
  }

  static Future<void> updatePartner(
      String uid, Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('partners').update(data).eq('id', uid);
    } catch (e) {
      debugPrint('SupabaseService.updatePartner error: $e');
      rethrow;
    }
  }

  static Future<void> deletePartner(String pid) async {
    try {
      await client.from('partners').delete().eq('id', pid);
    } catch (e) {
      debugPrint('SupabaseService.deletePartner error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllPartners() async {
    try {
      final response = await client.from('partners').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getAllPartners error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getOnlinePartners() async {
    try {
      final response =
          await client.from('partners').select().eq('is_online', true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getOnlinePartners error: $e');
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamPartners() {
    return client.from('partners').stream(primaryKey: ['id']);
  }

  // =============================================
  // ORDERS
  // =============================================

  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final response = await client
          .from('orders')
          .select()
          .eq('id', orderId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('SupabaseService.getOrder error: $e');
      return null;
    }
  }

  static Future<String> createOrder(Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      final response =
          await client.from('orders').insert(data).select('id').single();
      return response['id'] as String;
    } catch (e) {
      debugPrint('SupabaseService.createOrder error: $e');
      rethrow;
    }
  }

  static Future<void> upsertOrder(
      String orderId, Map<String, dynamic> data) async {
    try {
      data['id'] = orderId;
      data = _convertToSnakeCase(data);
      await client.from('orders').upsert(data);
    } catch (e) {
      debugPrint('SupabaseService.upsertOrder error: $e');
      rethrow;
    }
  }

  static Future<void> updateOrder(
      String orderId, Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('orders').update(data).eq('id', orderId);
    } catch (e) {
      debugPrint('SupabaseService.updateOrder error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getOrdersByUserId(
      String userId) async {
    try {
      final response =
          await client.from('orders').select().eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getOrdersByUserId error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getOrdersByPartnerId(
      String partnerId) async {
    try {
      final response =
          await client.from('orders').select().eq('partner_id', partnerId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getOrdersByPartnerId error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getOrdersByStatus(
      String status) async {
    try {
      final response =
          await client.from('orders').select().eq('status', status);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getOrdersByStatus error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getActiveOrders(
      {List<String> activeStatuses = const [
        'accepted',
        'picked_up'
      ]}) async {
    try {
      final response = await client
          .from('orders')
          .select()
          .inFilter('status', activeStatuses);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getActiveOrders error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await client.from('orders').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getAllOrders error: $e');
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamOrders() {
    return client.from('orders').stream(primaryKey: ['id']);
  }

  static Stream<List<Map<String, dynamic>>> streamOrderById(String orderId) {
    return client
        .from('orders')
        .stream(primaryKey: ['id']).eq('id', orderId);
  }

  static Stream<List<Map<String, dynamic>>> streamOrdersByStatus(
      List<String> statuses) {
    // Supabase stream doesn't support inFilter, so stream all and filter
    return client
        .from('orders')
        .stream(primaryKey: ['id']).map(
            (list) => list.where((o) => statuses.contains(o['status'])).toList());
  }

  // =============================================
  // RIDE REQUESTS
  // =============================================

  static Future<void> upsertRideRequest(
      String requestId, Map<String, dynamic> data) async {
    try {
      data['id'] = requestId;
      data = _convertToSnakeCase(data);
      await client.from('ride_requests').upsert(data);
    } catch (e) {
      debugPrint('SupabaseService.upsertRideRequest error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getRideRequestsByDriverId(
      String driverId) async {
    try {
      final response =
          await client.from('ride_requests').select().eq('driver_id', driverId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getRideRequestsByDriverId error: $e');
      return [];
    }
  }

  // =============================================
  // ORDER REVIEWS
  // =============================================

  static Future<void> addOrderReview(Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('order_reviews').insert(data);
    } catch (e) {
      debugPrint('SupabaseService.addOrderReview error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllOrderReviews() async {
    try {
      final response = await client
          .from('order_reviews')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getAllOrderReviews error: $e');
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamOrderReviews() {
    return client
        .from('order_reviews')
        .stream(primaryKey: ['id']);
  }

  // =============================================
  // ADMINS
  // =============================================

  static Future<Map<String, dynamic>?> getAdmin(String uid) async {
    try {
      final response =
          await client.from('admins').select().eq('id', uid).maybeSingle();
      return response;
    } catch (e) {
      debugPrint('SupabaseService.getAdmin error: $e');
      return null;
    }
  }

  static Future<void> upsertAdmin(
      String uid, Map<String, dynamic> data) async {
    try {
      data['id'] = uid;
      data = _convertToSnakeCase(data);
      await client.from('admins').upsert(data);
    } catch (e) {
      debugPrint('SupabaseService.upsertAdmin error: $e');
      rethrow;
    }
  }

  static Future<void> deleteAdmin(String uid) async {
    try {
      await client.from('admins').delete().eq('id', uid);
    } catch (e) {
      debugPrint('SupabaseService.deleteAdmin error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final response = await client.from('admins').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getAllAdmins error: $e');
      return [];
    }
  }

  // =============================================
  // GLM ACCOUNTS
  // =============================================

  static Future<Map<String, dynamic>?> getGLMAccount(String glmId) async {
    try {
      final response = await client
          .from('glm_accounts')
          .select()
          .eq('id', glmId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('SupabaseService.getGLMAccount error: $e');
      return null;
    }
  }

  static Future<void> upsertGLMAccount(
      String glmId, Map<String, dynamic> data) async {
    try {
      data['id'] = glmId;
      data = _convertToSnakeCase(data);
      await client.from('glm_accounts').upsert(data);
    } catch (e) {
      debugPrint('SupabaseService.upsertGLMAccount error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllGLMAccounts() async {
    try {
      final response = await client
          .from('glm_accounts')
          .select()
          .order('score', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getAllGLMAccounts error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTopGLMAccounts(
      int limit) async {
    try {
      final response = await client
          .from('glm_accounts')
          .select()
          .order('score', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getTopGLMAccounts error: $e');
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamGLMAccounts() {
    return client.from('glm_accounts').stream(primaryKey: ['id']);
  }

  // =============================================
  // NOTIFICATION LOGS
  // =============================================

  static Future<void> addNotificationLog(Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('notification_logs').insert(data);
    } catch (e) {
      debugPrint('SupabaseService.addNotificationLog error: $e');
    }
  }

  // =============================================
  // PENDING NOTIFICATIONS
  // =============================================

  static Future<void> addPendingNotification(
      Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('pending_notifications').insert(data);
    } catch (e) {
      debugPrint('SupabaseService.addPendingNotification error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingNotifications(
      String recipientId) async {
    try {
      final response = await client
          .from('pending_notifications')
          .select()
          .eq('recipient_id', recipientId)
          .eq('status', 'pending');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getPendingNotifications error: $e');
      return [];
    }
  }

  static Future<void> deletePendingNotification(String id) async {
    try {
      await client.from('pending_notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('SupabaseService.deletePendingNotification error: $e');
    }
  }

  // =============================================
  // ADMIN NOTIFICATIONS
  // =============================================

  static Future<void> addAdminNotification(
      Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('admin_notifications').insert(data);
    } catch (e) {
      debugPrint('SupabaseService.addAdminNotification error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>>
      getRecentAdminNotifications() async {
    try {
      final response = await client
          .from('admin_notifications')
          .select()
          .order('sent_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getRecentAdminNotifications error: $e');
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamAdminNotifications() {
    return client
        .from('admin_notifications')
        .stream(primaryKey: ['id']);
  }

  // =============================================
  // ADMIN ALERTS
  // =============================================

  static Future<void> addAdminAlert(Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('admin_alerts').insert(data);
    } catch (e) {
      debugPrint('SupabaseService.addAdminAlert error: $e');
    }
  }

  static Future<void> updateAdminAlert(
      String alertId, Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('admin_alerts').update(data).eq('id', alertId);
    } catch (e) {
      debugPrint('SupabaseService.updateAdminAlert error: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> streamAdminAlerts() {
    return client.from('admin_alerts').stream(primaryKey: ['id']);
  }

  // =============================================
  // USER NOTIFICATIONS (subcollection replacement)
  // =============================================

  static Future<void> addUserNotification(
      String userId, Map<String, dynamic> data) async {
    try {
      data['user_id'] = userId;
      data = _convertToSnakeCase(data);
      await client.from('user_notifications').insert(data);
    } catch (e) {
      debugPrint('SupabaseService.addUserNotification error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserNotifications(
      String userId) async {
    try {
      final response = await client
          .from('user_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getUserNotifications error: $e');
      return [];
    }
  }

  static Future<void> updateUserNotification(
      String notifId, Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client.from('user_notifications').update(data).eq('id', notifId);
    } catch (e) {
      debugPrint('SupabaseService.updateUserNotification error: $e');
    }
  }

  static Future<void> deleteUserNotification(String notifId) async {
    try {
      await client.from('user_notifications').delete().eq('id', notifId);
    } catch (e) {
      debugPrint('SupabaseService.deleteUserNotification error: $e');
    }
  }

  static Future<void> deleteAllUserNotifications(String userId) async {
    try {
      await client
          .from('user_notifications')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('SupabaseService.deleteAllUserNotifications error: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> streamUserNotifications(
      String userId) {
    return client
        .from('user_notifications')
        .stream(primaryKey: ['id']).eq('user_id', userId);
  }

  // =============================================
  // PARTNER NOTIFICATIONS (subcollection replacement)
  // =============================================

  static Future<void> addPartnerNotification(
      String partnerId, Map<String, dynamic> data) async {
    try {
      data['partner_id'] = partnerId;
      data = _convertToSnakeCase(data);
      await client.from('partner_notifications').insert(data);
    } catch (e) {
      debugPrint('SupabaseService.addPartnerNotification error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPartnerNotifications(
      String partnerId) async {
    try {
      final response = await client
          .from('partner_notifications')
          .select()
          .eq('partner_id', partnerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.getPartnerNotifications error: $e');
      return [];
    }
  }

  static Future<void> updatePartnerNotification(
      String notifId, Map<String, dynamic> data) async {
    try {
      data = _convertToSnakeCase(data);
      await client
          .from('partner_notifications')
          .update(data)
          .eq('id', notifId);
    } catch (e) {
      debugPrint('SupabaseService.updatePartnerNotification error: $e');
    }
  }

  static Future<void> deletePartnerNotification(String notifId) async {
    try {
      await client.from('partner_notifications').delete().eq('id', notifId);
    } catch (e) {
      debugPrint('SupabaseService.deletePartnerNotification error: $e');
    }
  }

  static Future<void> deleteAllPartnerNotifications(
      String partnerId) async {
    try {
      await client
          .from('partner_notifications')
          .delete()
          .eq('partner_id', partnerId);
    } catch (e) {
      debugPrint('SupabaseService.deleteAllPartnerNotifications error: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> streamPartnerNotifications(
      String partnerId) {
    return client
        .from('partner_notifications')
        .stream(primaryKey: ['id']).eq('partner_id', partnerId);
  }

  // =============================================
  // GENERIC HELPERS
  // =============================================

  /// Check if a record exists in a table
  static Future<bool> exists(String table, String id) async {
    try {
      final response =
          await client.from(table).select('id').eq('id', id).maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Generic query helper
  static Future<List<Map<String, dynamic>>> query(
    String table, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = client.from(table).select();

      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SupabaseService.query error on $table: $e');
      return [];
    }
  }

  // =============================================
  // CONVERSION HELPERS
  // =============================================

  /// Convert camelCase keys to snake_case for Supabase
  static Map<String, dynamic> _convertToSnakeCase(Map<String, dynamic> data) {
    final Map<String, dynamic> converted = {};
    data.forEach((key, value) {
      final snakeKey = _camelToSnake(key);
      // Skip Firestore-specific fields
      if (value is DateTime) {
        converted[snakeKey] = value.toIso8601String();
      } else if (value is Map<String, dynamic>) {
        // For nested objects (like locations), store as JSONB or flatten
        if (key == 'pickupLocation' ||
            key == 'userLocation' ||
            key == 'destinationLocation') {
          // Flatten lat/lng into separate columns
          if (value.containsKey('latitude')) {
            final prefix = key == 'destinationLocation'
                ? 'destination'
                : key == 'pickupLocation'
                    ? 'pickup'
                    : 'pickup';
            converted['${prefix}_latitude'] = value['latitude'];
            converted['${prefix}_longitude'] = value['longitude'];
          }
        } else {
          // Store other nested objects as JSON
          converted[snakeKey] = value;
        }
      } else {
        converted[snakeKey] = value;
      }
    });

    // Remove Firestore-specific keys that don't exist in Supabase
    converted.remove('data_ref');

    return converted;
  }

  /// Convert a camelCase string to snake_case
  static String _camelToSnake(String input) {
    // Handle common Firestore field mappings
    const Map<String, String> fieldMap = {
      'uid': 'id',
      'firstName': 'first_name',
      'lastName': 'last_name',
      'postCode': 'post_code',
      'profileImageUrl': 'profile_image_url',
      'licenseImageUrl': 'license_image_url',
      'ambulanceImageUrl': 'ambulance_image_url',
      'nidImageUrl': 'nid_image_url',
      'registrationPapersImageUrl': 'registration_papers_image_url',
      'isApproved': 'is_approved',
      'isOnline': 'is_online',
      'isActive': 'is_active',
      'companyName': 'company_name',
      'fcmToken': 'fcm_token',
      'acceptedTerms': 'accepted_terms',
      'createdAt': 'created_at',
      'updatedAt': 'updated_at',
      'lastLogin': 'last_login',
      'userId': 'user_id',
      'partnerId': 'partner_id',
      'orderId': 'order_id',
      'requestId': 'request_id',
      'userName': 'user_name',
      'userPhone': 'user_phone',
      'partnerName': 'partner_name',
      'partnerPhone': 'partner_phone',
      'pickupAddress': 'pickup_address',
      'destinationAddress': 'destination_address',
      'pickupLatitude': 'pickup_latitude',
      'pickupLongitude': 'pickup_longitude',
      'destinationLatitude': 'destination_latitude',
      'destinationLongitude': 'destination_longitude',
      'initialFare': 'initial_fare',
      'counterFare': 'counter_fare',
      'finalFare': 'final_fare',
      'userFare': 'user_fare',
      'partnerFare': 'partner_fare',
      'distanceKm': 'distance_km',
      'durationMins': 'duration_mins',
      'fareStatus': 'fare_status',
      'paymentMethod': 'payment_method',
      'isRated': 'is_rated',
      'acceptedAt': 'accepted_at',
      'pickedUpAt': 'picked_up_at',
      'completedAt': 'completed_at',
      'cancelledAt': 'cancelled_at',
      'driverId': 'driver_id',
      'isRead': 'is_read',
      'extraData': 'extra_data',
      'recipientId': 'recipient_id',
      'recipientType': 'recipient_type',
      'senderId': 'sender_id',
      'recipientCount': 'recipient_count',
      'sentAt': 'sent_at',
      'currentAddress': 'current_address',
      'lastLocationUpdate': 'last_location_update',
      'dataRef': 'data_ref',
    };

    if (fieldMap.containsKey(input)) {
      return fieldMap[input]!;
    }

    // Generic camelCase to snake_case conversion
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  static Map<String, dynamic> toSnakeCase(Map<String, dynamic> data) =>
      _convertToSnakeCase(data);

  /// Convert snake_case Supabase data back to camelCase for app compatibility
  static Map<String, dynamic> toCamelCase(Map<String, dynamic> data) {
    final Map<String, dynamic> converted = {};
    data.forEach((key, value) {
      final camelKey = _snakeToCamel(key);
      converted[camelKey] = value;
    });
    return converted;
  }

  static String _snakeToCamel(String input) {
    if (input == 'id') return 'uid';
    final parts = input.split('_');
    if (parts.length == 1) return input;
    return parts[0] +
        parts
            .skip(1)
            .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}')
            .join();
  }
}
