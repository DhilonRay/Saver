import 'package:supabase_flutter/supabase_flutter.dart';


/// Helper class to create and manage admin users
///
/// Usage:
/// 1. Call createAdminUser() with email and password
/// 2. The function will create Firebase Auth user and Firestore admin document
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
  static final GoTrueClient _auth = Supabase.instance.client.auth;
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates a new admin user in Firebase Auth and Firestore
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
      AuthResponse userCredential =
          await _auth.signUp(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.id;

      // Create admin document in Firestore
      await Supabase.instance.client.from('admins').upsert({'id': uid, 
        'email': email,
        'name': name,
        'role': 'admin',
        'createdAt': DateTime.now().toIso8601String(),
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
      Map<String, dynamic>? doc =
          await Supabase.instance.client.from('admins').select().eq('id', uid).maybeSingle();
      return doc != null;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Remove admin privileges from a user
  static Future<void> removeAdmin(String uid) async {
    try {
      await Supabase.instance.client.from('admins').delete().eq('id', uid);
      print('✅ Admin privileges removed for UID: $uid');
    } catch (e) {
      print('❌ Error removing admin: $e');
      rethrow;
    }
  }

  /// Get all admins
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      List<Map<String, dynamic>> snapshot = await Supabase.instance.client.from('admins').select();
      return snapshot
          .map((doc) => {
                'uid': doc['id'],
                ...doc,
              })
          .toList();
    } catch (e) {
      print('Error fetching admins: $e');
      return [];
    }
  }
}

// Example usage in your app:
/*

// Create first admin (run this once from a button or on first launch)
void createFirstAdmin() async {
  try {
    String adminUid = await AdminHelper.createAdminUser(
      email: 'admin@saver.com',
      password: 'SecurePassword123!',
      name: 'Super Admin',
    );
    
    print('Admin created with UID: $adminUid');
    
    // Show success message
    Get.snackbar(
      'Success',
      'Admin user created successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to create admin: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// Check if current user is admin
void checkAdminStatus() async {
  User? currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    bool isAdmin = await AdminHelper.isAdmin(currentUser.id);
    if (isAdmin) {
      print('Current user is an admin');
      // Navigate to admin panel
      Get.toNamed('/admin-login');
    } else {
      print('Current user is not an admin');
    }
  }
}

// Get all admins
void listAllAdmins() async {
  List<Map<String, dynamic>> admins = await AdminHelper.getAllAdmins();
  print('Total admins: ${admins.length}');
  for (var admin in admins) {
    print('Admin: ${admin['name']} (${admin['email']})');
  }
}

*/
