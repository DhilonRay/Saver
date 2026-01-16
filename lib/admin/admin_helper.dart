import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Create admin document in Firestore
      await _firestore.collection('admins').doc(uid).set({
        'email': email,
        'name': name,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
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
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Remove admin privileges from a user
  static Future<void> removeAdmin(String uid) async {
    try {
      await _firestore.collection('admins').doc(uid).delete();
      print('✅ Admin privileges removed for UID: $uid');
    } catch (e) {
      print('❌ Error removing admin: $e');
      rethrow;
    }
  }

  /// Get all admins
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('admins').get();
      return snapshot.docs
          .map((doc) => {
                'uid': doc.id,
                ...doc.data() as Map<String, dynamic>,
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
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    bool isAdmin = await AdminHelper.isAdmin(currentUser.uid);
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
