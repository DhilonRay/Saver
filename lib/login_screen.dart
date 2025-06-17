import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'home.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _fcmToken;
  bool _isLoadingToken = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndGetToken();
  }

  Future<void> _initializeFirebaseAndGetToken() async {
    try {
      if (mounted) setState(() => _isLoadingToken = true);
      await Firebase.initializeApp();

      final token = await FirebaseMessaging.instance.getToken();
      if (mounted) {
        setState(() {
          _fcmToken = token;
          _isLoadingToken = false;
        });
      }

      debugPrint('FCM Token: $token');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token Refreshed: $newToken');
        if (mounted) {
          setState(() {
            _fcmToken = newToken;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingToken = false);
      }
      debugPrint('Error getting FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color skyBlue = Color(0xFFB3E5FC);
    const Color lightBlue = Color(0xFFE1F5FE);
    const Color navyBlue = Color(0xFF0D47A1);
    const Color golden = Color(0xFFFFD700);
    const Color redAccent = Color(0xFFE53935);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [skyBlue, lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: golden, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      size: 90,
                      color: redAccent,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome to',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black54,
                      ),
                    ),
                    const Text(
                      'NeoSaver',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: navyBlue,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildFcmTokenStatus(),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: const Icon(Icons.email, color: navyBlue),
                        filled: true,
                        fillColor: lightBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock, color: navyBlue),
                        filled: true,
                        fillColor: lightBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyBlue,
                        foregroundColor: golden,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?",
                            style: TextStyle(color: Colors.black54)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              color: redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    try {
      await Firebase.initializeApp();
      final auth = FirebaseAuth.instance;

      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  HomePage()),
        );
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildFcmTokenStatus() {
    if (_isLoadingToken) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'Generating FCM Token...',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      );
    } else if (_fcmToken != null) {
      return Column(
        children: [
          const Text(
            'FCM Token Generated',
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () {
              debugPrint('FCM Token: $_fcmToken');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('FCM Token copied to console'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Tooltip(
              message: 'Click to view token in console',
              child: Icon(Icons.info_outline,
                  color: Colors.blue[300], size: 18),
            ),
          ),
        ]
      );
    } else {
      return Text(
        'FCM Token not available',
        style: TextStyle(color: Colors.red[400], fontSize: 12),
      );
    }
  }
}