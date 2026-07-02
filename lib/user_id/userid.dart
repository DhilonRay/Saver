import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'user_id_controller.dart';
import '../loader/loader.dart';

class UserIdPage extends StatelessWidget {
  const UserIdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserIdController>(
      init: UserIdController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F8F9), // Light blue background
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Get.back(),
            ),
            title: Obx(() => Text(
                  controller.isEditing.value ? 'Edit Profile' : 'Your Profile',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                )),
            centerTitle: true,
            actions: [
              Obx(() {
                if (!controller.isEditing.value &&
                    controller.userData.value != null) {
                  return IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.green),
                    onPressed: controller.toggleEditing,
                  );
                }
                if (controller.isEditing.value) {
                  return IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: controller.updateUserData,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                  child: HorizontalRotatingDots(size: 60, colors: [
                Colors.blueGrey,
                Colors.blueGrey.shade300,
                Colors.blueGrey.shade600
              ]));
            }

            if (controller.userData.value == null) {
              return const Center(child: Text('No user data available'));
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Image Section
                    Center(
                      child: GestureDetector(
                        onTap: controller.showProfileImageOptions,
                        child: Obx(() {
                          final imageUrl = controller.profileImageUrl.value;
                          final isUploading = controller.isUploadingImage.value;
                          final progress = controller.uploadProgress.value;

                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                    ),
                                  ],
                                  image: imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: imageUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 50,
                                      )
                                    : null,
                              ),
                              if (isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: progress > 0 ? progress : null,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildProfileSection(
                      title: 'Personal Information',
                      children: [
                        _buildProfileRow(
                            Icons.person,
                            'Name',
                            controller.userData.value?['name'],
                            controller.isEditing.value,
                            controller.nameController),
                        _buildProfileRow(
                            Icons.email,
                            'Email',
                            controller.userData.value?['email'],
                            controller.isEditing.value,
                            controller.emailController),
                        _buildProfileRow(
                            Icons.phone,
                            'Phone',
                            controller.userData.value?['phone'],
                            controller.isEditing.value,
                            controller.phoneController),
                        _buildProfileRow(
                            Icons.location_on,
                            'Address',
                            controller.userData.value?['address'],
                            controller.isEditing.value,
                            controller.addressController),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildProfileSection(
                      title: 'Account Details',
                      children: [
                        _buildProfileRow(
                          Icons.calendar_today,
                          'Created At',
                          controller.userData.value?['createdAt'] != null
                              ? DateFormat('d MMM yyyy . h:mm a').format(
                                  DateTime.parse(controller.userData.value!['createdAt'].toString()))
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
                                    Icons.directions_car,
                                    'Vehicle',
                                    controller
                                        .partnerData.value?['vehicleNumber'],
                                    controller.isEditing.value,
                                    controller.vehicleNumberController),
                                _buildProfileRow(
                                    Icons.card_membership,
                                    'License',
                                    controller
                                        .partnerData.value?['licenseNumber'],
                                    controller.isEditing.value,
                                    controller.licenseNumberController),
                                _buildProfileRow(
                                    Icons.local_hospital,
                                    'Type',
                                    controller
                                        .partnerData.value?['ambulanceType'],
                                    controller.isEditing.value,
                                    controller.ambulanceTypeController),
                                _buildProfileRow(
                                    Icons.map,
                                    'Area',
                                    controller
                                        .partnerData.value?['coverageArea'],
                                    controller.isEditing.value,
                                    controller.coverageAreaController),
                                _buildProfileRow(
                                    Icons.contact_phone,
                                    'Contact',
                                    controller.partnerData.value?['contact'],
                                    controller.isEditing.value,
                                    controller.contactController),
                                _buildProfileRow(
                                    Icons.business,
                                    'Company',
                                    controller
                                        .partnerData.value?['companyName'],
                                    controller.isEditing.value,
                                    controller.companyNameController),
                              ],
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProfileSection(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String? value,
      bool isEditing, TextEditingController? controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF2F7), // Light blue pill color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label :',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isEditing && controller != null
                ? TextFormField(
                    controller: controller,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      value ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
