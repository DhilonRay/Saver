import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../admin_controller.dart';
import '../admin_theme.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final AdminController _ctrl = Get.find<AdminController>();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final LatLng _initialPosition = const LatLng(23.8103, 90.4125);
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
      child: RefreshIndicator(
        onRefresh: () => _ctrl.loadDashboardStats(),
        color: AdminTheme.accent,
        backgroundColor: AdminTheme.bgCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome Banner ──
                _buildWelcomeBanner(),
                const SizedBox(height: 22),

                // ── Stats Grid ──
                Obx(() => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.12,
                  children: [
                    AdminStatCard(
                      title: 'Active Ambulances',
                      value: '${_ctrl.activeAmbulances.value}',
                      icon: Icons.local_hospital_rounded,
                      color: AdminTheme.green,
                    ),
                    AdminStatCard(
                      title: 'Trips Today',
                      value: '${_ctrl.totalTripsToday.value}',
                      icon: Icons.route_rounded,
                      color: AdminTheme.blue,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_ctrl.selectedRevenuePeriod.value == 'today') {
                          _ctrl.selectedRevenuePeriod.value = 'month';
                        } else {
                          _ctrl.selectedRevenuePeriod.value = 'today';
                        }
                      },
                      child: AdminStatCard(
                        title: 'Total Revenue',
                        value: _ctrl.selectedRevenuePeriod.value == 'today'
                            ? '৳${_ctrl.revenueToday.value.toStringAsFixed(0)}'
                            : '৳${_ctrl.revenueMonth.value.toStringAsFixed(0)}',
                        icon: Icons.monetization_on_rounded,
                        color: AdminTheme.accent,
                        subtitle: _ctrl.selectedRevenuePeriod.value == 'today'
                            ? 'Today (Tap for Month)'
                            : 'This Month (Tap for Today)',
                      ),
                    ),
                    AdminStatCard(
                      title: 'Total Active Users',
                      value: '${_ctrl.totalUsers.value}',
                      icon: Icons.people_rounded,
                      color: AdminTheme.orange,
                    ),
                  ],
                )),
                const SizedBox(height: 22),

                // ── Map Toggle ──
                _buildMapToggle(),

                // ── Map Section ──
                if (_showMap) ...[
                  const SizedBox(height: 16),
                  _buildMapSection(),
                ],
                const SizedBox(height: 22),

                // ── Quick Revenue ──
                _buildQuickRevenue(),
                const SizedBox(height: 22),

                // ── Recent Alerts ──
                AdminSectionHeader(
                  title: 'Recent Alerts',
                  icon: Icons.notifications_active_rounded,
                  color: AdminTheme.red,
                ),
                _buildAlerts(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return GlassCard(
      accentColor: AdminTheme.accentGlow,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AdminTheme.accent, AdminTheme.accentGlow],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AdminTheme.accent.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back, Admin!',
                  style: AdminTheme.heading2,
                ),
                const SizedBox(height: 4),
                Text(
                  'NeoSaver Ambulance Control Center',
                  style: AdminTheme.bodySmall.copyWith(color: AdminTheme.accent.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapToggle() {
    return GlassCard(
      onTap: () {
        setState(() => _showMap = !_showMap);
        if (_showMap) _loadAmbulanceLocations();
      },
      accentColor: _showMap ? AdminTheme.red : AdminTheme.blue,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (_showMap ? AdminTheme.red : AdminTheme.blue).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _showMap ? Icons.close_rounded : Icons.map_rounded,
              color: _showMap ? AdminTheme.red : AdminTheme.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _showMap ? 'Hide Map' : 'View All Ambulances on Map',
            style: AdminTheme.heading3.copyWith(
              color: _showMap ? AdminTheme.red : AdminTheme.blue,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AdminTheme.accent.withOpacity(0.15)),
        ),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 11),
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: false,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
            ),
            // Legend
            Positioned(
              top: 10,
              left: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AdminTheme.bgDeep.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legendDot(AdminTheme.green, 'Active'),
                        const SizedBox(width: 14),
                        _legendDot(AdminTheme.orange, 'On Trip'),
                        const SizedBox(width: 14),
                        _legendDot(AdminTheme.red, 'Inactive'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRevenue() {
    return Obx(() => GlassCard(
      accentColor: AdminTheme.green,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTheme.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AdminTheme.green.withOpacity(0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.trending_up_rounded, color: AdminTheme.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Revenue', style: AdminTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  '৳${_ctrl.totalRevenue.value.toStringAsFixed(0)}',
                  style: AdminTheme.stat.copyWith(color: AdminTheme.green, fontSize: 24),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Profit', style: AdminTheme.caption.copyWith(color: AdminTheme.textMuted)),
              const SizedBox(height: 2),
              Text(
                '৳${_ctrl.totalProfit.value.toStringAsFixed(0)}',
                style: AdminTheme.heading3.copyWith(color: AdminTheme.accent),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildAlerts() {
    return Obx(() {
      if (_ctrl.alerts.isEmpty) {
        return GlassCard(
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminTheme.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AdminTheme.green, size: 28),
                ),
                const SizedBox(height: 10),
                const Text('All systems normal', style: AdminTheme.body),
              ],
            ),
          ),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _ctrl.alerts.length > 5 ? 5 : _ctrl.alerts.length,
        itemBuilder: (context, index) {
          var alert = _ctrl.alerts[index];
          bool isRed = alert['type'] == 'ambulance_inactive';
          final color = isRed ? AdminTheme.red : AdminTheme.orange;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isRed ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['title'] ?? 'Alert',
                        style: AdminTheme.heading3.copyWith(color: color, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert['message'] ?? '',
                        style: AdminTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AdminTheme.caption.copyWith(color: AdminTheme.textSecondary)),
      ],
    );
  }

  Future<void> _loadAmbulanceLocations() async {
    try {
      QuerySnapshot snap =
          await FirebaseFirestore.instance.collection('partners').get();
      Set<Marker> markers = {};
      for (var doc in snap.docs) {
        var rawData = doc.data() as Map<String, dynamic>;
        double? lat = rawData['latitude']?.toDouble();
        double? lng = rawData['longitude']?.toDouble();

        if (lat != null && lng != null) {
          bool isActive = rawData['isOnline'] ?? false;
          bool onTrip = rawData['onTrip'] ?? false;

          // Normalize the data format to be compatible with UI expectations
          Map<String, dynamic> data = {
            'name': rawData['companyName'] ?? rawData['name'] ?? 'Ambulance',
            'driverName': rawData['name'] ?? 'N/A',
            'driverPhone': rawData['phone'] ?? rawData['contact'] ?? 'N/A',
            'type': rawData['ambulanceType'] ?? 'N/A',
            'isActive': isActive,
            'onTrip': onTrip,
          };

          BitmapDescriptor markerIcon;
          if (!isActive) {
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          } else if (onTrip) {
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          } else {
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          }

          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              icon: markerIcon,
              infoWindow: InfoWindow(
                title: data['name'],
                snippet:
                    '${data['driverName']} | ${isActive ? (onTrip ? 'On Trip' : 'Idle') : 'Inactive'}',
              ),
              onTap: () => _showAmbulanceQuickInfo(doc.id, data),
            ),
          );
        }
      }
      if (mounted) {
        setState(() => _markers = markers);
      }
    } catch (e) {
      debugPrint('Error loading ambulance locations: $e');
    }
  }

  void _showAmbulanceQuickInfo(String id, Map<String, dynamic> data) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AdminTheme.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ((data['isActive'] ?? false) ? AdminTheme.green : AdminTheme.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: (data['isActive'] ?? false) ? AdminTheme.green : AdminTheme.red,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? 'Ambulance', style: AdminTheme.heading2),
                      const SizedBox(height: 4),
                      Text('Driver: ${data['driverName'] ?? 'N/A'}', style: AdminTheme.body),
                    ],
                  ),
                ),
                AdminStatusBadge(
                  label: (data['onTrip'] ?? false) ? 'ON TRIP' : 'IDLE',
                  color: (data['onTrip'] ?? false) ? AdminTheme.orange : AdminTheme.green,
                ),
              ],
            ),
            const SizedBox(height: 20),
            AdminDetailRow(label: 'Phone', value: data['driverPhone'] ?? 'N/A'),
            AdminDetailRow(label: 'Type', value: data['type'] ?? 'N/A'),
            AdminDetailRow(label: 'Status', value: (data['isActive'] ?? false) ? 'Active' : 'Inactive'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
