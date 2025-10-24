import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class UserIdPage extends StatefulWidget {
  const UserIdPage({super.key});

  @override
  State<UserIdPage> createState() => _UserIdPageState();
}

class _UserIdPageState extends State<UserIdPage> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? partnerData;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _ambulanceTypeController = TextEditingController();
  final TextEditingController _coverageAreaController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final userDoc = await userDocRef.get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data();
            _nameController.text = userData?['name'] ?? '';
            _phoneController.text = userData?['phone'] ?? '';
            _addressController.text = userData?['address'] ?? '';
            _emailController.text = userData?['email'] ?? '';
          });
        } else {
          setState(() {
            userData = {
              'name': 'N/A',
              'email': FirebaseAuth.instance.currentUser!.email,
              'phone': 'N/A',
              'address': 'N/A',
              'uid': uid,
              'createdAt': Timestamp.now(),
            };
            _nameController.text = 'N/A';
            _phoneController.text = 'N/A';
            _addressController.text = 'N/A';
            _emailController.text = FirebaseAuth.instance.currentUser!.email ?? 'N/A';
          });
          await userDocRef.set(userData!);
        }

        final partnerDoc = await FirebaseFirestore.instance.collection('partners').doc(uid).get();
        if (partnerDoc.exists) {
          setState(() {
            partnerData = partnerDoc.data();
            _vehicleNumberController.text = partnerData?['vehicleNumber'] ?? '';
            _licenseNumberController.text = partnerData?['licenseNumber'] ?? '';
            _ambulanceTypeController.text = partnerData?['ambulanceType'] ?? '';
            _coverageAreaController.text = partnerData?['coverageArea'] ?? '';
            _contactController.text = partnerData?['contact'] ?? '';
            _companyNameController.text = partnerData?['companyName'] ?? '';
          });
        }

        await _updateLocation(uid);
      } catch (e) {
        // TODO: Handle user data fetch errors appropriately
        // For now, continue without user data to avoid crashes
      }
    }
  }

  Future<void> _updateUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'email': _emailController.text.trim(),
        });

        if (partnerData != null) {
          await FirebaseFirestore.instance.collection('partners').doc(uid).update({
            'vehicleNumber': _vehicleNumberController.text.trim(),
            'licenseNumber': _licenseNumberController.text.trim(),
            'ambulanceType': _ambulanceTypeController.text.trim(),
            'coverageArea': _coverageAreaController.text.trim(),
            'contact': _contactController.text.trim(),
            'companyName': _companyNameController.text.trim(),
          });
          setState(() {
            partnerData?['vehicleNumber'] = _vehicleNumberController.text.trim();
            partnerData?['licenseNumber'] = _licenseNumberController.text.trim();
            partnerData?['ambulanceType'] = _ambulanceTypeController.text.trim();
            partnerData?['coverageArea'] = _coverageAreaController.text.trim();
            partnerData?['contact'] = _contactController.text.trim();
            partnerData?['companyName'] = _companyNameController.text.trim();
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _isEditing = false;
          userData?['name'] = _nameController.text.trim();
          userData?['phone'] = _phoneController.text.trim();
          userData?['address'] = _addressController.text.trim();
          userData?['email'] = _emailController.text.trim();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateLocation(String uid) async {
    try {
      Position position = await _getCurrentLocation();
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      
    } catch (e) {
      // TODO: Handle location update errors (permission denied, network issues, etc.)
      // For now, silently fail to avoid disrupting user experience
    }
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Your Profile', style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.blueGrey.shade800,
        elevation: 2,
        actions: [
          if (!_isEditing && userData != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              onPressed: _updateUserData,
            ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blueGrey,
                            child: Icon(Icons.account_circle, size: 70, color: Colors.white),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.teal,
                              child: Icon(Icons.verified, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileSection(
                      title: 'Personal Information',
                      children: [
                        _buildProfileRow(Icons.person_outline, 'Name', userData?['name'], _isEditing, _nameController),
                        _buildProfileRow(Icons.email_outlined, 'Email', userData?['email'], _isEditing, _emailController),
                        _buildProfileRow(Icons.phone_outlined, 'Phone Number', userData?['phone'], _isEditing, _phoneController),
                        _buildProfileRow(Icons.location_on_outlined, 'Address', userData?['address'], _isEditing, _addressController),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProfileSection(
                      title: 'Account Details',
                      children: [
                        _buildProfileRow(Icons.badge_outlined, 'User ID', userData?['uid'], false, null),
                        _buildProfileRow(
                          Icons.calendar_today_outlined,
                          'Created At',
                          userData?['createdAt'] != null
                              ? DateFormat('yyyy-MM-dd – kk:mm').format((userData!['createdAt'] as Timestamp).toDate())
                              : 'N/A',
                          false,
                          null,
                        ),
                      ],
                    ),
                    if (partnerData != null) ...[
                      const SizedBox(height: 20),
                      _buildProfileSection(
                        title: 'Partner Information',
                        children: [
                          _buildProfileRow(Icons.airlines, 'Vehicle', partnerData?['vehicleNumber'], _isEditing, _vehicleNumberController),
                          _buildProfileRow(Icons.assignment_outlined, 'License Number', partnerData?['licenseNumber'], _isEditing, _licenseNumberController),
                          _buildProfileRow(Icons.local_hospital_outlined, 'Ambulance Type', partnerData?['ambulanceType'], _isEditing, _ambulanceTypeController),
                          _buildProfileRow(Icons.map_outlined, 'Coverage Area', partnerData?['coverageArea'], _isEditing, _coverageAreaController),
                          _buildProfileRow(Icons.phone_outlined, 'Contact', partnerData?['contact'], _isEditing, _contactController),
                          _buildProfileRow(Icons.business_outlined, 'Company Name', partnerData?['companyName'], _isEditing, _companyNameController),
                          _buildProfileRow(
                            Icons.calendar_today_outlined,
                            'Partner Created At',
                            partnerData?['createdAt'] != null
                                ? DateFormat('yyyy-MM-dd – kk:mm').format((partnerData!['createdAt'] as Timestamp).toDate())
                                : 'N/A',
                            false,
                            null,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade800,
            ),
          ),
          const Divider(color: Colors.grey, height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String? value, bool isEditing, TextEditingController? controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                if (isEditing && controller != null)
                  TextFormField(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  )
                else
                  Text(
                    value ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}