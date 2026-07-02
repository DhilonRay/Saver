import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saver/components/alert.dart';
import '../../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin_dashboard/admin_dashboard.dart';
import '../admin_theme.dart';
import '../../config/api_keys_secret.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      // ----------------------------------------------------
      // FIXED ADMIN CREDENTIALS BYPASS
      // ----------------------------------------------------
      if (email == ApiKeysSecret.adminEmail && password == ApiKeysSecret.adminPassword) {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        } catch (e) {
          try {
            UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
            await SupabaseService.client.from('admins').insert({
              'id': uc.user!.uid,
              'email': email,
              'created_at': DateTime.now().toIso8601String(),
            });
          } catch (_) {
            // If creation fails (e.g. email exists with diff password), we just bypass.
          }
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
      
        Get.offAll(() => const AdminDashboard());
        return;
      }
      // ----------------------------------------------------

      // Normal Sign in with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user is admin
      final adminDoc = await SupabaseService.client
          .from('admins')
          .select()
          .eq('id', userCredential.user!.uid)
          .maybeSingle();

      if (adminDoc == null) {
        // Not an admin, sign out
        await FirebaseAuth.instance.signOut();
        Alert.info('Access Denied');
        setState(() => _isLoading = false);
        return;
      }

      // Admin verified, navigate to dashboard
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdminLoggedIn', true);
   
      Get.offAll(() => const AdminDashboard());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        if (mounted) setState(() => _isLoading = false);
        _showCreateAccountDialog();
        return;
      }
      
      if (e.code == 'wrong-password') {
        Alert.info('Wrong password');
      } else if (e.code == 'invalid-email') {
        Alert.info('Invalid email address');
      }

      if (mounted) setState(() => _isLoading = false);
      Alert.info('Login Error');
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      Alert.info(
        'Error',
      
      );
    }
  }

  void _showCreateAccountDialog() {
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AdminTheme.bgCard,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AdminTheme.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.info_outline_rounded, color: AdminTheme.orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('Admin Not Found', style: AdminTheme.heading2),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'No admin account found with these credentials.',
                  style: AdminTheme.body.copyWith(color: AdminTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminTheme.accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminTheme.accent.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 18, color: AdminTheme.accent.withOpacity(0.8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Create your admin account first before logging in.',
                          style: AdminTheme.bodySmall.copyWith(color: AdminTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                        ),
                        child: const Text('Try Again', style: TextStyle(color: AdminTheme.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.toNamed('/create-admin');
                        },
                        icon: const Icon(Icons.add_moderator_rounded, color: Colors.white, size: 18),
                        label: const Text('Create Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final resetFormKey = GlobalKey<FormState>();
    bool isResetLoading = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setStateDialog) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: AdminTheme.bgCard,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: resetFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AdminTheme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lock_reset_rounded, color: AdminTheme.accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text('Reset Password', style: AdminTheme.heading2),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter your registered admin email address. We will send you a secure link to reset your password.',
                        style: AdminTheme.body.copyWith(color: AdminTheme.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      
                      // Email label and field
                      _buildLabel('Admin Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isResetLoading,
                        style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'admin@saver.com',
                          hintStyle: AdminTheme.body.copyWith(color: AdminTheme.textMuted.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.mail_outline_rounded, color: AdminTheme.accent.withOpacity(0.6), size: 20),
                          filled: true,
                          fillColor: AdminTheme.bgDeep.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AdminTheme.accent, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AdminTheme.red, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AdminTheme.red, width: 1.5),
                          ),
                          errorStyle: const TextStyle(color: AdminTheme.red, fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!value.contains('@')) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isResetLoading ? null : () => Get.back(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                ),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: AdminTheme.textSecondary)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isResetLoading ? null : () async {
                                if (!resetFormKey.currentState!.validate()) return;
                                
                                setStateDialog(() {
                                  isResetLoading = true;
                                });
                                
                                final email = resetEmailController.text.trim();
                                try {
                                  // Verify if the email is actually registered in admins collection
                                  final adminQuery = await SupabaseService.client
                                      .from('admins')
                                      .select()
                                      .eq('email', email);
                                      
                                  if (adminQuery.isEmpty && email != 'admin@saver.com') {
                                    Alert.info('This email is not registered as an admin');
                                    setStateDialog(() {
                                      isResetLoading = false;
                                    });
                                    return;
                                  }
                                  
                                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                  Get.back(); // close recovery dialog
                                  Alert.info('Password reset link has been sent to your email.');
                                } on FirebaseAuthException catch (e) {
                                  String errorMsg = 'Failed to send reset link';
                                  if (e.code == 'user-not-found') {
                                    errorMsg = 'No user found with this email';
                                  } else if (e.code == 'invalid-email') {
                                    errorMsg = 'Invalid email address';
                                  } else if (e.message != null) {
                                    errorMsg = e.message!;
                                  }
                                  Alert.info(errorMsg);
                                  setStateDialog(() {
                                    isResetLoading = false;
                                  });
                                } catch (e) {
                                  Alert.info('An unexpected error occurred. Please try again.');
                                  setStateDialog(() {
                                    isResetLoading = false;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.accent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: isResetLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: AdminTheme.bgDeep,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Send Reset Link',
                                      style: TextStyle(
                                        color: AdminTheme.bgDeep,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Animated Background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF050D1A),
                  Color(0xFF0A1929),
                  Color(0xFF0D2137),
                  Color(0xFF071320),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // ── Decorative Orbs ──
          Positioned(
            top: -80,
            right: -60,
            child: _glowOrb(180, AdminTheme.accent.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _glowOrb(220, AdminTheme.purple.withOpacity(0.05)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: -40,
            child: _glowOrb(120, AdminTheme.accentGlow.withOpacity(0.04)),
          ),

          // ── Grid Pattern Overlay ──
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _GridPatternPainter(),
          ),

          // ── Main Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo & Icon
                        _buildLogo(),
                        const SizedBox(height: 40),

                        // Glass Login Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AdminTheme.bgCard.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 40,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome Back',
                                      style: AdminTheme.heading1,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sign in to access the admin dashboard',
                                      style: AdminTheme.body.copyWith(color: AdminTheme.textMuted),
                                    ),
                                    const SizedBox(height: 28),

                                    // Email Field
                                    _buildLabel('Email'),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _emailController,
                                      hint: 'admin@saver.com',
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter your email';
                                        if (!value.contains('@')) return 'Please enter a valid email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Password Field
                                    _buildLabel('Password'),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _passwordController,
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      obscure: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AdminTheme.textMuted,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Please enter your password';
                                        if (value.length < 6) return 'Password must be at least 6 characters';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Forgot Password Button
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isLoading ? null : _showForgotPasswordDialog,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: AdminTheme.bodySmall.copyWith(
                                            color: AdminTheme.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Login Button
                                    _buildLoginButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Footer
                        Text(
                          'NeoSaver Admin Console v2.0',
                          style: AdminTheme.caption.copyWith(color: AdminTheme.textMuted.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AdminTheme.accent.withOpacity(0.08),
            border: Border.all(color: AdminTheme.accent.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: AdminTheme.accent.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AdminTheme.accent, Color(0xFF80DEEA)],
            ).createShader(bounds),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AdminTheme.accent, Color(0xFF80DEEA)],
          ).createShader(bounds),
          child: const Text(
            'SAVER ADMIN',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: AdminTheme.caption.copyWith(
        color: AdminTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AdminTheme.body.copyWith(color: AdminTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AdminTheme.body.copyWith(color: AdminTheme.textMuted.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AdminTheme.accent.withOpacity(0.6), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AdminTheme.bgDeep.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminTheme.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminTheme.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminTheme.red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AdminTheme.red, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AdminTheme.accent, AdminTheme.accentGlow],
          ),
          boxShadow: [
            BoxShadow(
              color: AdminTheme.accent.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: AdminTheme.bgDeep,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, color: AdminTheme.bgDeep, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.bgDeep,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

/// Subtle grid pattern painter for the background.
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
