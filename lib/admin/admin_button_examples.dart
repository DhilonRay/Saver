import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Example Settings Page showing how to add the admin creation button
///
/// Copy this example to see exactly where to add the admin button
class ExampleSettingsWithAdmin extends StatelessWidget {
  const ExampleSettingsWithAdmin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: ListView(
        children: [
          // ... Your existing settings ...

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Admin Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ==========================================
          // 🎯 ADD THIS: CREATE ADMIN BUTTON (One-Time)
          // ==========================================
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.green.shade700,
                ),
              ),
              title: const Text(
                'Create Admin Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('One-time setup - Create your admin login'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 🚀 THIS OPENS THE EASY ADMIN CREATOR
                Get.toNamed('/create-admin');
              },
            ),
          ),

          // ==========================================
          // 🎯 ADD THIS: ADMIN LOGIN BUTTON
          // ==========================================
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.login,
                  color: Colors.blue.shade700,
                ),
              ),
              title: const Text(
                'Admin Login',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Access admin panel'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 🔐 THIS OPENS THE ADMIN LOGIN
                Get.toNamed('/admin-login');
              },
            ),
          ),

          // ... Your other settings ...
        ],
      ),
    );
  }
}

// ==========================================
// 🎯 SIMPLE VERSION: Just add these buttons
// ==========================================
class SimpleAdminButtons extends StatelessWidget {
  const SimpleAdminButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // CREATE ADMIN BUTTON (Use once, then remove)
        ElevatedButton.icon(
          onPressed: () => Get.toNamed('/create-admin'),
          icon: const Icon(Icons.add_moderator, color: Colors.white),
          label: const Text(
            'Create Admin Account',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // ADMIN LOGIN BUTTON (Keep this)
        ElevatedButton.icon(
          onPressed: () => Get.toNamed('/admin-login'),
          icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
          label: const Text(
            'Admin Login',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 🎯 SECRET ACCESS: Long press to open admin
// ==========================================
class SecretAdminAccess extends StatelessWidget {
  const SecretAdminAccess({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Long press on logo to open admin
      onLongPress: () {
        Get.dialog(
          AlertDialog(
            title: const Text('Admin Access'),
            content: const Text('Choose action:'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed('/create-admin');
                },
                child: const Text('Create Admin'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed('/admin-login');
                },
                child: const Text('Admin Login'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Column(
          children: [
            Icon(Icons.admin_panel_settings, size: 50),
            Text('Long press for admin'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🎯 FLOATING ACTION BUTTON VERSION
// ==========================================
class PageWithAdminFAB extends StatelessWidget {
  const PageWithAdminFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My App')),
      body: const Center(child: Text('Your content here')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/create-admin'),
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text('Setup Admin'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// ==========================================
// 🎯 USAGE INSTRUCTIONS
// ==========================================
/*

STEP 1: Choose one of the methods above
STEP 2: Copy the code to your existing page
STEP 3: Run app and tap the button
STEP 4: Admin created! 🎉

EXAMPLE 1: Add to your existing settings page
-------------------------------------------------
In your settings page, add:

  ElevatedButton(
    onPressed: () => Get.toNamed('/create-admin'),
    child: Text('Create Admin'),
  ),

EXAMPLE 2: Add as list item
-------------------------------------------------
  ListTile(
    leading: Icon(Icons.admin_panel_settings),
    title: Text('Create Admin'),
    onTap: () => Get.toNamed('/create-admin'),
  ),

EXAMPLE 3: Secret long press
-------------------------------------------------
  GestureDetector(
    onLongPress: () => Get.toNamed('/create-admin'),
    child: YourAppLogo(),
  ),

That's it! Super easy! 🚀

After creating admin once, you can remove the create button
and keep only the login button.

Login credentials will be:
Email: admin@saver.com
Password: Admin@12345

*/
