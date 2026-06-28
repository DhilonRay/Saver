import 'package:firebase_auth/firebase_auth.dart';
import '../services/supabase_service.dart';

/// Helper class to create and manage admin users
///
/// Usage:
/// 1. Call createAdminUser() with email and password
/// 2. The function will create Firebase Auth user and Supabase admin document
///
/// Example:
/// ```dart
/// await AdminHelper.createAdminUser(
///   email: 'admin@saver.com',
///   password: 'Admin@123',
///   name: 'Main Admin',
/// );
/// ```
class AdminHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates a new admin user in Firebase Auth and Supabase
  ///
  /// Returns the UID of the created admin user
  /// Throws exception if creation fails
  static Future<String> createAdminUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Create admin document in Supabase
      await SupabaseService.client.from('admins').insert({
        'id': uid,
        'email': email,
        'name': name,
        'role': 'admin',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Admin user created successfully!');
      print('UID: $uid');
      print('Email: $email');
      print('Name: $name');

      return uid;
    } catch (e) {
      print('❌ Error creating admin user: $e');
      rethrow;
    }
  }

  /// Check if a user is an admin
  static Future<bool> isAdmin(String uid) async {
    try {
      final doc = await SupabaseService.client
          .from('admins')
          .select()
          .eq('id', uid)
          .maybeSingle();
      return doc != null;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Remove admin privileges from a user
  static Future<void> removeAdmin(String uid) async {
    try {
      await SupabaseService.client.from('admins').delete().eq('id', uid);
      print('✅ Admin privileges removed for UID: $uid');
    } catch (e) {
      print('❌ Error removing admin: $e');
      rethrow;
    }
  }

  /// Get all admins
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final list = await SupabaseService.client.from('admins').select();
      return list.map((item) => SupabaseService.toCamelCase(item)).toList();
    } catch (e) {
      print('Error fetching admins: $e');
      return [];
    }
  }
}
