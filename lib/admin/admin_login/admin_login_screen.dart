import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_dashboard/admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Sign in with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if user is admin
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userCredential.user!.uid)
          .get();

      if (!adminDoc.exists) {
        // Not an admin, sign out
        await FirebaseAuth.instance.signOut();
        Get.snackbar(
          'Access Denied',
          'You do not have admin privileges',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => _isLoading = false);
        return;
      }

      // Admin verified, navigate to dashboard
      Get.offAll(() => const AdminDashboard());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        // Show helpful message with create account option
        if (mounted) setState(() => _isLoading = false);
        _showCreateAccountDialog();
        return;
      }
      
      String message = 'Login failed';
      if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }

      if (mounted) setState(() => _isLoading = false);
      Get.snackbar(
        'Login Error',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showCreateAccountDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Admin Not Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No admin account found with these credentials.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Need to create admin first?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You need to create your admin account first before you can login.',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Try Again'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.toNamed('/create-admin');
            },
            icon: const Icon(Icons.add_moderator, color: Colors.white),
            label: const Text('Create Admin Now', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
              Colors.cyan.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Admin Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 64,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
