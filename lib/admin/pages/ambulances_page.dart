import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../admin_theme.dart';

class AmbulancesPage extends StatefulWidget {
  const AmbulancesPage({super.key});

  @override
  State<AmbulancesPage> createState() => _AmbulancesPageState();
}

class _AmbulancesPageState extends State<AmbulancesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('partners').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: AdminTheme.body),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AdminTheme.accent),
            );
          }

          var ambulances = snapshot.data!.docs;
          if (ambulances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AdminTheme.bgSurface.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital_rounded, size: 48, color: AdminTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text('No ambulances found', style: AdminTheme.body),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ambulances.length,
            itemBuilder: (context, index) {
              var rawData = ambulances[index].data() as Map<String, dynamic>;
              var id = ambulances[index].id;
              
              // Normalize partner data to keys expected by UI and detail pages
              Map<String, dynamic> data = {
                'name': rawData['companyName'] ?? rawData['name'] ?? 'Ambulance',
                'driverName': rawData['name'] ?? 'N/A',
                'driverPhone': rawData['phone'] ?? rawData['contact'] ?? 'N/A',
                'type': rawData['ambulanceType'] ?? 'N/A',
                'numberPlate': rawData['vehicleNumber'] ?? 'N/A',
                'lastAddress': rawData['coverageArea'] ?? rawData['address'] ?? 'N/A',
                'lastLocationUpdate': rawData['lastUpdated'],
                'isActive': rawData['isOnline'] ?? false,
                'onTrip': rawData['onTrip'] ?? false,
              };

              bool isActive = data['isActive'] ?? false;
              bool onTrip = data['onTrip'] ?? false;

              final statusColor = !isActive
                  ? AdminTheme.red
                  : onTrip
                      ? AdminTheme.orange
                      : AdminTheme.green;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  accentColor: statusColor,
                  onTap: () => _showAmbulanceDetails(id, data),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.12),
                              blurRadius: 12,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Icon(Icons.local_hospital_rounded, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['name'] ?? 'Ambulance',
                                    style: AdminTheme.heading3,
                                  ),
                                ),
                                AdminStatusBadge(
                                  label: isActive ? (onTrip ? 'ON TRIP' : 'IDLE') : 'INACTIVE',
                                  color: statusColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _quickInfo(Icons.person_outline_rounded, 'Driver: ${data['driverName'] ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            _quickInfo(Icons.phone_outlined, data['driverPhone'] ?? 'N/A'),
                            const SizedBox(height: 4),
                            _quickInfo(Icons.directions_bus_rounded, 'Type: ${data['type'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: AdminTheme.textMuted.withOpacity(0.5), size: 22),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _quickInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AdminTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: AdminTheme.bodySmall, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  void _showAmbulanceDetails(String id, Map<String, dynamic> data) {
    Get.to(() => _AmbulanceDetailPage(ambulanceId: id, data: data));
  }
}

class _AmbulanceDetailPage extends StatelessWidget {
  final String ambulanceId;
  final Map<String, dynamic> data;

  const _AmbulanceDetailPage({required this.ambulanceId, required this.data});

  @override
  Widget build(BuildContext context) {
    bool isActive = data['isActive'] ?? false;
    bool onTrip = data['onTrip'] ?? false;
    final statusColor = !isActive ? AdminTheme.red : onTrip ? AdminTheme.orange : AdminTheme.green;

    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: AdminAppBar(title: data['name'] ?? 'Ambulance'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            GlassCard(
              accentColor: statusColor,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Ambulance', style: AdminTheme.heading1),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AdminStatusBadge(
                              label: isActive ? (onTrip ? 'ON TRIP' : 'IDLE - READY') : 'INACTIVE',
                              color: statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Vehicle info
            const AdminSectionHeader(title: 'Vehicle Information', icon: Icons.directions_bus_rounded),
            GlassCard(
              child: Column(
                children: [
                  AdminDetailRow(label: 'Name', value: data['name'] ?? 'N/A', labelWidth: 120),
                  AdminDetailRow(label: 'Type', value: data['type'] ?? 'N/A', labelWidth: 120),
                  AdminDetailRow(label: 'Number Plate', value: data['numberPlate'] ?? 'N/A', labelWidth: 120),
                  AdminDetailRow(label: 'Status', value: isActive ? 'Active' : 'Inactive', labelWidth: 120),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Driver info
            const AdminSectionHeader(title: 'Driver Information', icon: Icons.person_rounded),
            GlassCard(
              child: Column(
                children: [
                  AdminDetailRow(label: 'Driver Name', value: data['driverName'] ?? 'N/A', labelWidth: 120),
                  AdminDetailRow(label: 'Phone', value: data['driverPhone'] ?? 'N/A', labelWidth: 120),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Last known location
            const AdminSectionHeader(title: 'Last Known Location', icon: Icons.location_on_rounded),
            GlassCard(
              child: Column(
                children: [
                  AdminDetailRow(
                    label: 'Location',
                    value: data['lastAddress'] ?? 'Location data not available',
                    labelWidth: 120,
                  ),
                  if (data['lastLocationUpdate'] != null)
                    AdminDetailRow(
                      label: 'Last Updated',
                      value: _formatTimestamp(data['lastLocationUpdate']),
                      labelWidth: 120,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Current trip details (if on trip)
            if (onTrip) ...[
              AdminSectionHeader(
                title: 'Current Trip Details',
                icon: Icons.emergency_rounded,
                color: AdminTheme.red,
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .where('ambulanceId', isEqualTo: ambulanceId)
                    .where('status', whereIn: ['accepted', 'picked_up', 'in_progress'])
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return GlassCard(
                      child: const AdminDetailRow(label: 'Trip', value: 'No active trip data found'),
                    );
                  }
                  var trip = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  return GlassCard(
                    accentColor: AdminTheme.red,
                    child: Column(
                      children: [
                        AdminDetailRow(label: 'Fare', value: '৳${trip['fare'] ?? 'N/A'}', labelWidth: 120),
                        AdminDetailRow(label: 'Pickup', value: trip['pickupAddress'] ?? 'N/A', labelWidth: 120),
                        AdminDetailRow(label: 'Destination', value: trip['destinationAddress'] ?? 'N/A', labelWidth: 120),
                        AdminDetailRow(label: 'Patient', value: trip['patientName'] ?? 'N/A', labelWidth: 120),
                        AdminDetailRow(label: 'Phone', value: trip['patientPhone'] ?? 'N/A', labelWidth: 120),
                        if (trip['createdAt'] != null)
                          AdminDetailRow(label: 'Started', value: _formatTimestamp(trip['createdAt']), labelWidth: 120),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
    }
    return 'N/A';
  }
}
