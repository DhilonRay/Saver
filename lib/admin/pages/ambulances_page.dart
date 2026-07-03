import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../admin_theme.dart';
import '../../services/supabase_service.dart';

class AmbulancesPage extends StatefulWidget {
  const AmbulancesPage({super.key});

  @override
  State<AmbulancesPage> createState() => _AmbulancesPageState();
}

class _AmbulancesPageState extends State<AmbulancesPage> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.streamPartners(),
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

          var ambulances = snapshot.data ?? [];
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
              var partner = SupabaseService.toCamelCase(ambulances[index]);
              var id = partner['uid'] ?? partner['id'] ?? '';
              var rawData = partner;

              // Normalize partner data to keys expected by UI and detail pages
              Map<String, dynamic> data = {
                'name': rawData['companyName'] ?? rawData['name'] ?? 'Ambulance',
                'driverName': rawData['name'] ?? 'N/A',
                'driverEmail': rawData['email'] ?? 'N/A',
                'driverPhone': rawData['phone'] ?? rawData['contact'] ?? 'N/A',
                'type': rawData['ambulanceType'] ?? 'N/A',
                'numberPlate': rawData['vehicleNumber'] ?? 'N/A',
                'licenseNumber': rawData['licenseNumber'] ?? 'N/A',
                'roadTaxToken': rawData['roadTaxToken'] ?? 'N/A',
                'nationalId': rawData['nationalId'] ?? 'N/A',
                'referenceId': rawData['referenceId'] ?? 'N/A',
                'lastAddress': rawData['coverageArea'] ?? rawData['address'] ?? 'N/A',
                'lastLocationUpdate': rawData['lastLocationUpdate'] ?? rawData['lastUpdated'],
                'isActive': rawData['isOnline'] ?? false,
                'onTrip': rawData['onTrip'] ?? false,
                'isApproved': rawData['isApproved'] ?? false,
                'createdAt': rawData['createdAt'],
                // Document images from registration
                'profileImageUrl': rawData['profileImageUrl'],
                'licenseImageUrl': rawData['licenseImageUrl'],
                'ambulanceImageUrl': rawData['ambulanceImageUrl'],
                'nidImageUrl': rawData['nidImageUrl'],
                'registrationPapersImageUrl': rawData['registrationPapersImageUrl'],
              };

              bool isActive = data['isActive'] ?? false;
              bool onTrip = data['onTrip'] ?? false;

              if (isActive) {
                final lastUpdatedRaw = data['lastLocationUpdate'];
                DateTime? lastUpdated;
                if (lastUpdatedRaw is String) {
                  lastUpdated = DateTime.tryParse(lastUpdatedRaw);
                }
                if (lastUpdated != null) {
                  final difference = DateTime.now().difference(lastUpdated);
                  if (difference.inMinutes > 10) {
                    isActive = false;
                  }
                } else {
                  isActive = false;
                }
              }
              
              // Update the map so detail view gets the correct status
              data['isActive'] = isActive;

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

// ──────────────────────────────────────────────────────────
// Detail Page
// ──────────────────────────────────────────────────────────

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
            // ── Status Header ──
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
                            const SizedBox(width: 8),
                            if (data['isApproved'] == true)
                              AdminStatusBadge(label: 'VERIFIED', color: AdminTheme.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Vehicle Information ──
            const AdminSectionHeader(title: 'Vehicle Information', icon: Icons.directions_bus_rounded),
            GlassCard(
              child: Column(
                children: [
                  AdminDetailRow(label: 'Company Name', value: data['name'] ?? 'N/A', labelWidth: 140),
                  AdminDetailRow(label: 'Type', value: data['type'] ?? 'N/A', labelWidth: 140),
                  AdminDetailRow(label: 'Number Plate', value: data['numberPlate'] ?? 'N/A', labelWidth: 140),
                  AdminDetailRow(label: 'License No.', value: data['licenseNumber'] ?? 'N/A', labelWidth: 140),
                  AdminDetailRow(label: 'Road Tax Token', value: data['roadTaxToken'] ?? 'N/A', labelWidth: 140),
                  AdminDetailRow(label: 'Status', value: isActive ? 'Active / Online' : 'Inactive / Offline', labelWidth: 140),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Driver Information ──
            const AdminSectionHeader(title: 'Driver Information', icon: Icons.person_rounded),
            GlassCard(
              child: Column(
                children: [
                  AdminDetailRow(label: 'Driver Name', value: data['driverName'] ?? 'N/A', labelWidth: 140),
                  AdminDetailRow(label: 'Phone', value: data['driverPhone'] ?? 'N/A', labelWidth: 140),
                  AdminDetailRow(label: 'Email', value: data['driverEmail'] ?? 'N/A', labelWidth: 140),
                  AdminDetailRow(label: 'National ID', value: data['nationalId'] ?? 'N/A', labelWidth: 140),
                  if ((data['referenceId'] ?? '').toString().isNotEmpty && data['referenceId'] != 'N/A')
                    AdminDetailRow(label: 'Reference ID', value: data['referenceId'] ?? 'N/A', labelWidth: 140),
                  if (data['createdAt'] != null)
                    AdminDetailRow(label: 'Joined', value: _formatTimestamp(data['createdAt']), labelWidth: 140),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Submitted Documents ──
            AdminSectionHeader(
              title: 'Submitted Documents',
              icon: Icons.folder_copy_rounded,
              color: AdminTheme.blue,
            ),
            _buildDocumentsSection(context),
            const SizedBox(height: 16),

            // ── Last Known Location ──
            const AdminSectionHeader(title: 'Last Known Location', icon: Icons.location_on_rounded),
            GlassCard(
              child: Column(
                children: [
                  AdminDetailRow(
                    label: 'Coverage Area',
                    value: data['lastAddress'] ?? 'Location data not available',
                    labelWidth: 140,
                  ),
                  if (data['lastLocationUpdate'] != null)
                    AdminDetailRow(
                      label: 'Last Updated',
                      value: _formatTimestamp(data['lastLocationUpdate']),
                      labelWidth: 140,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Current Trip Details (if on trip) ──
            if (onTrip) ...[
              AdminSectionHeader(
                title: 'Current Trip Details',
                icon: Icons.emergency_rounded,
                color: AdminTheme.red,
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.client
                    .from('orders')
                    .stream(primaryKey: ['id'])
                    .eq('partner_id', ambulanceId)
                    .map((list) => list
                        .where((o) => ['accepted', 'picked_up', 'in_progress'].contains(o['status']))
                        .toList()),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return GlassCard(
                      child: const AdminDetailRow(label: 'Trip', value: 'No active trip data found'),
                    );
                  }
                  var trip = SupabaseService.toCamelCase(snapshot.data!.first);
                  return GlassCard(
                    accentColor: AdminTheme.red,
                    child: Column(
                      children: [
                        AdminDetailRow(label: 'Fare', value: '৳${trip['fareAmount'] ?? trip['finalFare'] ?? trip['confirmedFare'] ?? trip['fare'] ?? 'N/A'}', labelWidth: 120),
                        AdminDetailRow(label: 'Pickup', value: trip['pickupAddress'] ?? 'N/A', labelWidth: 120),
                        AdminDetailRow(label: 'Destination', value: trip['destinationAddress'] ?? 'N/A', labelWidth: 120),
                        AdminDetailRow(label: 'Patient', value: trip['patientName'] ?? 'N/A', labelWidth: 120),
                        AdminDetailRow(label: 'Phone', value: trip['patientPhone'] ?? trip['phone'] ?? 'N/A', labelWidth: 120),
                        if (trip['timestamp'] != null)
                          AdminDetailRow(label: 'Started', value: _formatTimestamp(trip['timestamp']), labelWidth: 120),
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

  Widget _buildDocumentsSection(BuildContext context) {
    final docs = <Map<String, String?>>[
      {'label': 'Profile Photo', 'url': data['profileImageUrl']},
      {'label': 'Driver License', 'url': data['licenseImageUrl']},
      {'label': 'Ambulance Photo', 'url': data['ambulanceImageUrl']},
      {'label': 'NID / Identity', 'url': data['nidImageUrl']},
      {'label': 'Registration Papers', 'url': data['registrationPapersImageUrl']},
    ];

    final available = docs.where((d) => d['url'] != null && (d['url'] ?? '').isNotEmpty).toList();
    final missing = docs.where((d) => d['url'] == null || (d['url'] ?? '').isEmpty).toList();

    if (available.isEmpty) {
      return GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminTheme.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_off_rounded, color: AdminTheme.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('No documents submitted yet', style: AdminTheme.body),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Document image grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: available.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, i) {
            final doc = available[i];
            return _DocumentCard(
              label: doc['label']!,
              imageUrl: doc['url']!,
              onTap: () => _openImageFullScreen(context, doc['label']!, doc['url']!),
            );
          },
        ),

        // Missing docs notice
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 12),
          GlassCard(
            accentColor: AdminTheme.amber,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AdminTheme.amber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Not submitted: ${missing.map((d) => d['label']).join(', ')}',
                    style: AdminTheme.bodySmall.copyWith(color: AdminTheme.amber),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _openImageFullScreen(BuildContext context, String label, String url) {
    Get.to(
      () => _FullScreenImagePage(label: label, imageUrl: url),
      transition: Transition.fadeIn,
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is String) {
      final parsed = DateTime.tryParse(ts);
      if (parsed != null) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      }
    }
    return 'N/A';
  }
}

// ──────────────────────────────────────────────────────────
// Document Thumbnail Card
// ──────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final String label;
  final String imageUrl;
  final VoidCallback onTap;

  const _DocumentCard({required this.label, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AdminTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.accent.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AdminTheme.bgSurface,
                        child: const Icon(Icons.broken_image_rounded, color: AdminTheme.textMuted, size: 40),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AdminTheme.bgSurface,
                          child: const Center(
                            child: CircularProgressIndicator(color: AdminTheme.accent, strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                    // Tap hint overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.open_in_full_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: AdminTheme.bgCard,
                child: Text(
                  label,
                  style: AdminTheme.caption.copyWith(color: AdminTheme.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Full Screen Image Viewer
// ──────────────────────────────────────────────────────────

class _FullScreenImagePage extends StatelessWidget {
  final String label;
  final String imageUrl;

  const _FullScreenImagePage({required this.label, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(label, style: AdminTheme.heading3.copyWith(color: Colors.white)),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60),
                const SizedBox(height: 16),
                Text('Failed to load image', style: AdminTheme.body.copyWith(color: Colors.white54)),
              ],
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: AdminTheme.accent);
            },
          ),
        ),
      ),
    );
  }
}
