import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'user_id_controller.dart';

class UserIdPage extends StatelessWidget {
  const UserIdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserIdController>(
      init: UserIdController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: Obx(() => Text(
              controller.isEditing.value ? 'Edit Profile' : 'Your Profile',
              style: const TextStyle(fontWeight: FontWeight.w500)
            )),
            backgroundColor: Colors.blueGrey.shade800,
            elevation: 2,
            actions: [
              Obx(() {
                if (!controller.isEditing.value && controller.userData.value != null) {
                  return IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: controller.toggleEditing,
                  );
                }
                if (controller.isEditing.value) {
                  return IconButton(
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    onPressed: controller.updateUserData,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey)
                )
              );
            }

            if (controller.userData.value == null) {
              return const Center(child: Text('No user data available'));
            }

            return SingleChildScrollView(
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
                        _buildProfileRow(
                          Icons.person_outline,
                          'Name',
                          controller.userData.value?['name'],
                          controller.isEditing.value,
                          controller.nameController
                        ),
                        _buildProfileRow(
                          Icons.email_outlined,
                          'Email',
                          controller.userData.value?['email'],
                          controller.isEditing.value,
                          controller.emailController
                        ),
                        _buildProfileRow(
                          Icons.phone_outlined,
                          'Phone Number',
                          controller.userData.value?['phone'],
                          controller.isEditing.value,
                          controller.phoneController
                        ),
                        _buildProfileRow(
                          Icons.location_on_outlined,
                          'Address',
                          controller.userData.value?['address'],
                          controller.isEditing.value,
                          controller.addressController
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProfileSection(
                      title: 'Account Details',
                      children: [
                        _buildProfileRow(Icons.badge_outlined, 'User ID', controller.userData.value?['uid'], false, null),
                        _buildProfileRow(
                          Icons.calendar_today_outlined,
                          'Created At',
                          controller.userData.value?['createdAt'] != null
                              ? DateFormat('yyyy-MM-dd – kk:mm').format((controller.userData.value!['createdAt'] as Timestamp).toDate())
                              : 'N/A',
                          false,
                          null,
                        ),
                      ],
                    ),
                    Obx(() {
                      if (controller.partnerData.value != null) {
                        return Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildProfileSection(
                              title: 'Partner Information',
                              children: [
                                _buildProfileRow(
                                  Icons.airlines,
                                  'Vehicle',
                                  controller.partnerData.value?['vehicleNumber'],
                                  controller.isEditing.value,
                                  controller.vehicleNumberController
                                ),
                                _buildProfileRow(
                                  Icons.assignment_outlined,
                                  'License Number',
                                  controller.partnerData.value?['licenseNumber'],
                                  controller.isEditing.value,
                                  controller.licenseNumberController
                                ),
                                _buildProfileRow(
                                  Icons.local_hospital_outlined,
                                  'Ambulance Type',
                                  controller.partnerData.value?['ambulanceType'],
                                  controller.isEditing.value,
                                  controller.ambulanceTypeController
                                ),
                                _buildProfileRow(
                                  Icons.map_outlined,
                                  'Coverage Area',
                                  controller.partnerData.value?['coverageArea'],
                                  controller.isEditing.value,
                                  controller.coverageAreaController
                                ),
                                _buildProfileRow(
                                  Icons.phone_outlined,
                                  'Contact',
                                  controller.partnerData.value?['contact'],
                                  controller.isEditing.value,
                                  controller.contactController
                                ),
                                _buildProfileRow(
                                  Icons.business_outlined,
                                  'Company Name',
                                  controller.partnerData.value?['companyName'],
                                  controller.isEditing.value,
                                  controller.companyNameController
                                ),
                                _buildProfileRow(
                                  Icons.calendar_today_outlined,
                                  'Partner Created At',
                                  controller.partnerData.value?['createdAt'] != null
                                      ? DateFormat('yyyy-MM-dd – kk:mm').format((controller.partnerData.value!['createdAt'] as Timestamp).toDate())
                                      : 'N/A',
                                  false,
                                  null,
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }),
        );
      },
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