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
              title: const Text('Partner Profile',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.black87)),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            backgroundColor: const Color(0xFFE3F2FD),
            body: Center(
                child: HorizontalRotatingDots(size: 60, colors: [
              const Color(0xFF1976D2),
              Colors.orange.shade600,
              Colors.purple.shade600
            ])),
          );
        }
        if (controller.error.value.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Partner Profile',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.black87)),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            backgroundColor: const Color(0xFFE3F2FD),
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
            title: const Text('Partner Profile',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black87)),
            centerTitle: true,
            backgroundColor: const Color(0xFFE1F5FE), // Light Blue
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Get.back(),
            ),
            actions: [
              Obx(() => IconButton(
                    icon: Icon(
                      controller.isEditing.value ? Icons.save : Icons.edit,
                      color: Colors.black87,
                    ),
                    onPressed: controller.isEditing.value
                        ? controller.saveChanges
                        : controller.toggleEditing,
                  )),
            ],
          ),
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image Container at the top - Ambulance Image Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey
                            .withValues(alpha: 0.3), // Soft shadow color
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE1F5FE), // Light blue background
                        border: Border.all(
                          color: const Color(0xFFFF5252), // Coral/red border
                          width: 3.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/images/ambulance.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Ambulance Photo Card - Blue themed
                // Ambulance Photo Card - Blue themed
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color(0xFFD2EDFB), // Exact design color
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey
                            .withValues(alpha: 0.3), // Soft shadow color
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with ambulance icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                      0xFFB2DFDB), // Light teal border
                                  width: 1.5,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/ambulance.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ambulance Photo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          const Color(0xFF26A69A), // Teal color
                                    ),
                                  ),
                                  Text(
                                    'Help users identify your ambulance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Upload area - White card inside
                        Obx(() {
                          final controller =
                              Get.find<PartnerProfileController>();
                          return GestureDetector(
                            onTap: controller.showAmbulanceImageOptions,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: controller.isUploadingAmbulanceImage.value
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: controller
                                                        .ambulanceUploadProgress
                                                        .value >
                                                    0
                                                ? controller
                                                    .ambulanceUploadProgress
                                                    .value
                                                : null,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    const Color(0xFF26A69A)),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${(controller.ambulanceUploadProgress.value * 100).toInt()}%',
                                            style: TextStyle(
                                              color: const Color(0xFF26A69A),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : controller.ambulanceImageUrl.value != null
                                      ? Stack(
                                          fit: StackFit.loose,
                                          alignment: Alignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                controller
                                                    .ambulanceImageUrl.value!,
                                                height: 140,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return SizedBox(
                                                    height: 140,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                const Color(
                                                                    0xFF26A69A)),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return _buildUploadPlaceholder();
                                                },
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Change',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : _buildUploadPlaceholder(),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Users will see this photo when viewing\navailable ambulances',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Earnings Summary Card - Yellow/Cream themed
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFFFF9C4), // Cream background
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row with icons
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      const Color(0xFFFFB300), // Amber border
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.savings, // Money bag/savings icon
                                color: const Color(0xFF43A047), // Green
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Earnings Summary',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: const Color(0xFFFFB300), // Amber text
                                ),
                              ),
                            ),
                            Icon(
                              Icons.currency_exchange,
                              color: const Color(0xFF43A047), // Green
                              size: 24,
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final controller =
                              Get.find<PartnerProfileController>();
                          if (controller.isCalculatingEarnings.value) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFFFFB300)),
                                ),
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                // Total Earnings
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Earning',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      controller.formatCurrency(
                                          controller.totalEarnings.value),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFB300), // Amber
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                    height: 24, color: Colors.grey.shade200),
                                // Monthly Earnings
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'This Month',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      controller.formatCurrency(
                                          controller.monthlyEarnings.value),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFB300), // Amber
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                    height: 24, color: Colors.grey.shade200),
                                // Completed Rides
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Completed Rides',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${controller.completedRides.value}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFB300), // Amber
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Personal Information Card - Redesigned
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Avatar
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD), // Light Blue bg
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person,
                                color: const Color(0xFF1976D2), // Blue
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Information Pills
                        Column(
                          children: [
                            _buildInfoPill(Icons.person, 'Name',
                                personal['name']?.toString() ?? 'N/A',
                                data: personal, dataKey: 'name'),
                            _buildInfoPill(Icons.email, 'Email',
                                personal['email']?.toString() ?? 'N/A',
                                data: personal, dataKey: 'email'),
                            _buildInfoPill(Icons.phone, 'Phone',
                                personal['phone']?.toString() ?? 'N/A',
                                data: personal, dataKey: 'phone'),
                            _buildInfoPill(Icons.location_on, 'Address',
                                personal['address']?.toString() ?? 'N/A',
                                data: personal, dataKey: 'address'),
                            _buildInfoPill(Icons.badge, 'User ID',
                                personal['uid'] ?? 'N/A',
                                isReadOnly: true),
                            if ((personal['role'] ?? '').isNotEmpty)
                              _buildInfoPill(
                                  Icons.work, 'Role', personal['role'],
                                  isReadOnly: true),
                            if (personal['createdAt'] != null)
                              _buildInfoPill(Icons.calendar_today, 'Created At',
                                  _formatDate(personal['createdAt'].toDate()),
                                  isReadOnly: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Partner Information Card - Redesigned
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                    'assets/images/ambulance.png',
                                    fit: BoxFit.contain),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Partner Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Information Pills
                        Column(
                          children: [
                            _buildInfoPill(Icons.person, 'Ambulance Type',
                                partner['ambulanceType'] ?? 'N/A',
                                data: partner, dataKey: 'ambulanceType'),
                            _buildInfoPill(Icons.person, 'Vehicle Number',
                                partner['vehicleNumber'] ?? 'N/A',
                                data: partner, dataKey: 'vehicleNumber'),
                            _buildInfoPill(Icons.person, 'License Number',
                                partner['licenseNumber'] ?? 'N/A',
                                data: partner, dataKey: 'licenseNumber'),
                            _buildInfoPill(Icons.person, 'Company Name',
                                partner['companyName'] ?? 'N/A',
                                data: partner, dataKey: 'companyName'),
                            _buildInfoPill(Icons.person, 'Contact',
                                partner['contact'] ?? 'N/A',
                                data: partner, dataKey: 'contact'),
                            _buildInfoPill(Icons.person, 'Coverage Area',
                                partner['coverageArea'] ?? 'N/A',
                                data: partner, dataKey: 'coverageArea'),
                            _buildInfoPill(Icons.person, 'Indoor City Rate',
                                partner['indoorCityRate']?.toString() ?? 'N/A',
                                data: partner,
                                dataKey: 'indoorCityRate',
                                isNumber: true),
                            _buildInfoPill(Icons.person, 'Outdoor City Rate',
                                partner['outdoorCityRate']?.toString() ?? 'N/A',
                                data: partner,
                                dataKey: 'outdoorCityRate',
                                isNumber: true),

                            // Status Row
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 20, color: Colors.grey.shade700),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Status :',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: partner['isOnline'] == true
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: partner['isOnline'] == true
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    child: Text(
                                      partner['isOnline'] == true
                                          ? 'Online'
                                          : 'Offline',
                                      style: TextStyle(
                                        color: partner['isOnline'] == true
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Location and Dates
                            if (partner['latitude'] != null &&
                                partner['longitude'] != null)
                              Obx(() {
                                final controller =
                                    Get.find<PartnerProfileController>();
                                final address =
                                    controller.locationAddress.value;
                                return _buildInfoPill(Icons.person, 'Location',
                                    address ?? 'Loading...');
                              }),
                            if (partner['createdAt'] != null)
                              _buildInfoPill(Icons.person, 'Created At',
                                  _formatDate(partner['createdAt'].toDate())),
                            if (partner['lastUpdated'] != null)
                              _buildInfoPill(Icons.person, 'Last Updated',
                                  _formatDate(partner['lastUpdated'].toDate())),
                          ],
                        ),
                      ],
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

  // Helper method to build the upload placeholder for ambulance photo
  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Landscape/Gallery icon with plus badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Main icon container with gradient
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF4DD0E1), // Cyan
                    const Color(0xFF26A69A), // Teal
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  // Sun icon
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F), // Yellow
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Landscape icon
                  Center(
                    child: Icon(
                      Icons.landscape,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 38,
                    ),
                  ),
                ],
              ),
            ),
            // Blue plus badge
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5), // Blue
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Ambulance Photo',
          style: TextStyle(
            color: const Color(0xFF26A69A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Max 2MB',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Helper method to format dates in user-friendly format
  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy, hh:mm:ss a').format(date);
  }

  Widget _buildInfoPill(IconData icon, String label, String value,
      {RxMap<String, dynamic>? data,
      String? dataKey,
      bool isNumber = false,
      bool isReadOnly = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light Blue
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Text(
            '$label :',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() {
              final controller = Get.find<PartnerProfileController>();
              bool isEditing = controller.isEditing.value;

              if (isEditing && !isReadOnly && data != null && dataKey != null) {
                return SizedBox(
                  height: 24,
                  child: TextFormField(
                    initialValue: data[dataKey]?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    keyboardType:
                        isNumber ? TextInputType.number : TextInputType.text,
                    onChanged: (val) {
                      if (isNumber) {
                        data[dataKey] = num.tryParse(val) ?? val;
                      } else {
                        data[dataKey] = val;
                      }
                    },
                  ),
                );
              }

              return Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              );
            }),
          ),
        ],
      ),
    );
  }
}
