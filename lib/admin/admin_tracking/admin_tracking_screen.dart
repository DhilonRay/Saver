import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_theme.dart';

class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});
  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final LatLng _initialPosition = const LatLng(23.8103, 90.4125);

  @override
  void initState() { super.initState(); _loadActiveDeliveries(); }

  Future<void> _loadActiveDeliveries() async {
    try {
      QuerySnapshot activeOrders = await _fs.collection('orders').where('status', whereIn: ['accepted', 'picked_up']).get();
      Set<Marker> markers = {};
      for (var doc in activeOrders.docs) {
        var od = doc.data() as Map<String, dynamic>;
        if (od['pickupLocation'] != null) {
          var loc = od['pickupLocation'] as Map<String, dynamic>;
          markers.add(Marker(markerId: MarkerId('pickup_${doc.id}'), position: LatLng(loc['latitude'] ?? 23.8103, loc['longitude'] ?? 90.4125), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), infoWindow: InfoWindow(title: 'Pickup', snippet: od['pickupAddress'] ?? 'Pickup Location')));
        }
        if (od['deliveryLocation'] != null) {
          var loc = od['deliveryLocation'] as Map<String, dynamic>;
          markers.add(Marker(markerId: MarkerId('delivery_${doc.id}'), position: LatLng(loc['latitude'] ?? 23.8103, loc['longitude'] ?? 90.4125), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: InfoWindow(title: 'Delivery', snippet: od['deliveryAddress'] ?? 'Delivery Location')));
        }
        if (od['partnerLocation'] != null) {
          var loc = od['partnerLocation'] as Map<String, dynamic>;
          markers.add(Marker(markerId: MarkerId('partner_${doc.id}'), position: LatLng(loc['latitude'] ?? 23.8103, loc['longitude'] ?? 90.4125), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), infoWindow: InfoWindow(title: 'Partner', snippet: od['partnerName'] ?? 'Delivery Partner')));
        }
      }
      if (mounted) setState(() => _markers = markers);
    } catch (e) { print('Error loading active deliveries: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: AdminAppBar(title: 'Live Tracking', actions: [
        GestureDetector(onTap: _loadActiveDeliveries, child: Container(margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AdminTheme.bgSurface.withOpacity(0.5), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.refresh_rounded, color: AdminTheme.textSecondary, size: 22))),
      ]),
      body: Column(children: [
        // Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: AdminTheme.bgCard.withOpacity(0.6), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04)))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _legendDot('Pickup', AdminTheme.orange), _legendDot('Delivery', AdminTheme.green), _legendDot('Partner', AdminTheme.blue),
          ]),
        ),
        // Map
        Expanded(child: GoogleMap(initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 12), markers: _markers, onMapCreated: (c) => _mapController = c, myLocationEnabled: true, myLocationButtonEnabled: true, zoomControlsEnabled: true)),
        // Active Deliveries
        Container(
          height: 200,
          decoration: BoxDecoration(color: AdminTheme.bgCard, border: Border(top: BorderSide(color: Colors.white.withOpacity(0.04)))),
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs.collection('orders').where('status', whereIn: ['accepted', 'picked_up']).snapshots(),
            builder: (ctx, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: AdminTheme.body));
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
              var orders = List<QueryDocumentSnapshot>.from(snap.data!.docs);
              orders.sort((a, b) { try { final at = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?; final bt = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?; if (at == null) return 1; if (bt == null) return -1; return bt.compareTo(at); } catch (_) { return 0; } });
              if (orders.isEmpty) return const Center(child: Text('No active deliveries', style: AdminTheme.body));
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.all(12), child: Text('Active Deliveries (${orders.length})', style: AdminTheme.heading3)),
                Expanded(child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: orders.length, itemBuilder: (ctx, i) {
                  var od = orders[i].data() as Map<String, dynamic>;
                  var oid = orders[i].id;
                  final isAccepted = od['status'] == 'accepted';
                  return Container(
                    width: 250, margin: const EdgeInsets.only(right: 12),
                    child: GlassCard(
                      accentColor: isAccepted ? AdminTheme.blue : AdminTheme.purple,
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Order #${oid.substring(0, 6)}', style: AdminTheme.heading3.copyWith(fontSize: 13)),
                          AdminStatusBadge(label: od['status'].toString().toUpperCase(), color: isAccepted ? AdminTheme.blue : AdminTheme.purple),
                        ]),
                        const SizedBox(height: 8),
                        Text(od['userName'] ?? 'Customer', style: AdminTheme.bodySmall),
                        if (od['partnerName'] != null) ...[const SizedBox(height: 4), Row(children: [Icon(Icons.delivery_dining_rounded, size: 14, color: AdminTheme.green.withOpacity(0.7)), const SizedBox(width: 4), Expanded(child: Text(od['partnerName'], style: AdminTheme.bodySmall.copyWith(color: AdminTheme.green), overflow: TextOverflow.ellipsis))])],
                        const Spacer(),
                        SizedBox(width: double.infinity, height: 36, child: ElevatedButton(
                          onPressed: () => _focusOnOrder(od),
                          style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                          child: Text('View on Map', style: TextStyle(fontSize: 12, color: AdminTheme.bgDeep, fontWeight: FontWeight.w600)),
                        )),
                      ]),
                    ),
                  );
                })),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _legendDot(String label, Color color) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)])),
    const SizedBox(width: 6), Text(label, style: AdminTheme.bodySmall.copyWith(color: AdminTheme.textSecondary)),
  ]);

  Future<void> _focusOnOrder(Map<String, dynamic> od) async {
    if (_mapController != null && od['deliveryLocation'] != null) {
      try {
        var loc = od['deliveryLocation'] as Map<String, dynamic>;
        await _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(loc['latitude'] ?? 23.8103, loc['longitude'] ?? 90.4125), zoom: 15)));
      } catch (e) { debugPrint('AdminTracking: animateCamera failed: $e'); }
    }
  }

  @override
  void dispose() { _mapController?.dispose(); super.dispose(); }
}
