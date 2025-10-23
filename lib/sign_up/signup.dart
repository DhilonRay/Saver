import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../partner.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  String _selectedRole = 'user';

  Future<void> registerUser(BuildContext context) async {
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.trim().isEmpty ||
        confirmPassword.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the fields')),
      );
      return;
    }

    if (password.text.trim() != confirmPassword.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (!isValidEmail(email.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (!isValidName(name.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot contain numbers')),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
        'email': email.text.trim(),
        'uid': userCredential.user!.uid,
        'role': _selectedRole,
        'createdAt': Timestamp.now(),
      });

      if (_selectedRole == 'driver') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PartnerPage(uid: userCredential.user!.uid),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User registered successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^[\w-]+(\.[\w-]+)*@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidName(String name) {
    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blueGrey.shade800,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: name,
              style: TextStyle(color: Colors.blueGrey.shade800),
              decoration: _inputDecoration('Name', Icons.person_outline),
              onChanged: (value) {
                setState(() {}); 
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phone,
              style: TextStyle(color: Colors.blueGrey.shade800),
              decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: address,
              style: TextStyle(color: Colors.blueGrey.shade800),
              decoration: _inputDecoration('Address', Icons.home_outlined),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: email,
              style: TextStyle(color: Colors.blueGrey.shade800),
              decoration: _inputDecoration('Email', Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: password,
              obscureText: true,
              style: TextStyle(color: Colors.blueGrey.shade800),
              decoration: _inputDecoration('Password', Icons.lock_outline),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmPassword,
              obscureText: true,
              style: TextStyle(color: Colors.blueGrey.shade800),
              decoration:
                  _inputDecoration('Confirm Password', Icons.lock_outline),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Text("Register as:",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(
                          value: 'user',
                          child:
                              Text('User', style: TextStyle(color: Colors.blueGrey)),
                        ),
                        DropdownMenuItem(
                          value: 'driver',
                          child: Text('Ambulance Partner',
                              style: TextStyle(color: Colors.blueGrey)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => registerUser(context),
              icon: const Icon(Icons.app_registration_outlined, color: Colors.white),
              label: const Text('Register',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.blueGrey.shade600),
      prefixIcon: Icon(icon, color: Colors.blueGrey.shade600),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.teal.shade600),
      ),
    );
  }
}