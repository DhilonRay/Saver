import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'partner_profile_controller.dart';
import '../../loader/loader.dart';
import 'package:intl/intl.dart';

class PartnerProfilePage extends StatelessWidget {
  const PartnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(
      () {
        final controller = Get.put(PartnerProfileController());
        if (controller.isLoading.value) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Partner Profile'),
              centerTitle: true,
              backgroundColor: colorScheme.primary,
              titleTextStyle:
                  TextStyle(color: colorScheme.onPrimary, fontSize: 18),
            ),
            body: Center(
                child: HorizontalRotatingDots(size: 60, colors: [
              Colors.teal.shade800,
              Colors.orange.shade600,
              Colors.purple.shade600
            ])),
          );
        }
        if (controller.error.value.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Partner Profile'),
              centerTitle: true,
              backgroundColor: colorScheme.primary,
              titleTextStyle:
                  TextStyle(color: colorScheme.onPrimary, fontSize: 18),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.error.value,
                    style: TextStyle(color: colorScheme.error, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      controller.error.value = '';
                      controller.isLoading.value = true;
                      controller.restartListeners();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final personal = controller.personalInfo;
        final partner = controller.partnerInfo;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Partner Profile'),
            centerTitle: true,
            backgroundColor: colorScheme.primary,
            titleTextStyle:
                TextStyle(color: colorScheme.onPrimary, fontSize: 18),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
              onPressed: () => Get.back(),
            ),
            actions: [
              Obx(() => controller.isEditing.value
                  ? IconButton(
                      icon: Icon(Icons.save, color: colorScheme.onPrimary),
                      onPressed: controller.saveChanges,
                    )
                  : IconButton(
                      icon: Icon(Icons.edit, color: colorScheme.onPrimary),
                      onPressed: controller.toggleEditing,
                    )),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image Container at the top
                Card(
                  elevation: 12,
                  /*  shadowColor: colorScheme.primary.withValues(alpha: 0.4), */
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    /* decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.1),
                          colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ), */
                    child: Center(
                      child: Obx(() {
                        final controller = Get.find<PartnerProfileController>();
                        return GestureDetector(
                          onTap: controller.showProfileImageOptions,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: colorScheme.primary,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  image:
                                      controller.profileImageUrl.value != null
                                          ? DecorationImage(
                                              image: NetworkImage(controller
                                                  .profileImageUrl.value!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: controller.profileImageUrl.value == null
                                    ? Icon(
                                        Icons.local_shipping,
                                        color: colorScheme.primary,
                                        size: 60,
                                      )
                                    : null,
                              ),
                              if (controller.isUploadingImage.value)
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              if (controller.isEditing.value)
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.camera_alt,
                                          color: colorScheme.onPrimary,
                                          size: 24),
                                      onPressed: controller.pickAndUploadImage,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 8,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          colorScheme.surface.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _editableInfoRow('Name', personal, 'name'),
                                const Divider(height: 16),
                                _editableInfoRow('Email', personal, 'email'),
                                const Divider(height: 16),
                                _editableInfoRow('Phone', personal, 'phone'),
                                const Divider(height: 16),
                                _editableInfoRow(
                                    'Address', personal, 'address'),
                                const Divider(height: 16),
                                _infoRow('User ID', personal['uid'] ?? ''),
                                if ((personal['role'] ?? '').isNotEmpty) ...[
                                  const Divider(height: 16),
                                  _infoRow('Role', personal['role']),
                                ],
                                if (personal['createdAt'] != null) ...[
                                  const Divider(height: 16),
                                  _infoRow(
                                      'Created At',
                                      _formatDate(
                                          personal['createdAt'].toDate())),
                                ],
                                if (personal['lastLogin'] != null) ...[
                                  const Divider(height: 16),
                                  _infoRow(
                                      'Last Login',
                                      _formatDate(
                                          personal['lastLogin'].toDate())),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 8,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          colorScheme.surface.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Partner Information',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow('Ambulance Type',
                                    partner['ambulanceType'] ?? 'N/A'),
                                const Divider(height: 16),
                                _infoRow('Vehicle Number',
                                    partner['vehicleNumber'] ?? 'N/A'),
                                const Divider(height: 16),
                                _infoRow('License Number',
                                    partner['licenseNumber'] ?? 'N/A'),
                                const Divider(height: 16),
                                _infoRow('Company Name',
                                    partner['companyName'] ?? 'N/A'),
                                const Divider(height: 16),
                                _editableInfoRow('Contact', partner, 'contact'),
                                const Divider(height: 16),
                                _infoRow('Coverage Area',
                                    partner['coverageArea'] ?? 'N/A'),
                                const Divider(height: 16),
                                _editableInfoRow('Indoor City Rate', partner,
                                    'indoorCityRate',
                                    isNumber: true, isCurrency: true),
                                const Divider(height: 16),
                                _editableInfoRow('Outdoor City Rate', partner,
                                    'outdoorCityRate',
                                    isNumber: true, isCurrency: true),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    Text('Status:',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: partner['isOnline'] == true
                                            ? Colors.green
                                                .withValues(alpha: 0.1)
                                            : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: partner['isOnline'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        partner['isOnline'] == true
                                            ? 'Online'
                                            : 'Offline',
                                        style: TextStyle(
                                          color: partner['isOnline'] == true
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (partner['latitude'] != null &&
                                    partner['longitude'] != null) ...[
                                  const Divider(height: 16),
                                  Obx(() {
                                    final controller =
                                        Get.find<PartnerProfileController>();
                                    final address =
                                        controller.locationAddress.value;
                                    return _infoRow('Location',
                                        address ?? 'Loading address...');
                                  }),
                                ],
                                if (partner['createdAt'] != null) ...[
                                  const Divider(height: 16),
                                  _infoRow(
                                      'Created At',
                                      _formatDate(
                                          partner['createdAt'].toDate())),
                                ],
                                if (partner['lastUpdated'] != null) ...[
                                  const Divider(height: 16),
                                  _infoRow(
                                      'Last Updated',
                                      _formatDate(
                                          partner['lastUpdated'].toDate())),
                                ],
                                if (partner['ratesLastUpdated'] != null) ...[
                                  const Divider(height: 16),
                                  _infoRow(
                                      'Rates Last Updated',
                                      _formatDate(partner['ratesLastUpdated']
                                          .toDate())),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$title:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _editableInfoRow(String title, RxMap<String, dynamic> data, String key,
      {bool isNumber = false, bool isCurrency = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$title:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() {
            final controller = Get.find<PartnerProfileController>();
            return controller.isEditing.value
                ? TextFormField(
                    initialValue: data[key]?.toString() ?? '',
                    keyboardType:
                        isNumber ? TextInputType.number : TextInputType.text,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Theme.of(Get.context!).colorScheme.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      if (isNumber) {
                        data[key] = int.tryParse(value) ?? 0;
                      } else {
                        data[key] = value;
                      }
                    },
                  )
                : Text(
                    isCurrency && data[key] != null
                        ? '৳${data[key]}'
                        : (data[key]?.toString() ?? 'N/A'),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  );
          }),
        ),
      ],
    );
  }

  // Helper method to format dates in user-friendly format
  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy, hh:mm:ss a').format(date);
  }
}
