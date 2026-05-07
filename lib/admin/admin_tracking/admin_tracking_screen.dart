import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});

  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final LatLng _initialPosition = const LatLng(23.8103, 90.4125); // Dhaka

  @override
  void initState() {
    super.initState();
    _loadActiveDeliveries();
  }

  Future<void> _loadActiveDeliveries() async {
    try {
      QuerySnapshot activeOrders = await _firestore
          .collection('orders')
          .where('status', whereIn: ['accepted', 'picked_up']).get();

      Set<Marker> markers = {};

      for (var doc in activeOrders.docs) {
        var orderData = doc.data() as Map<String, dynamic>;

        // Add pickup marker
        if (orderData['pickupLocation'] != null) {
          var pickupLoc = orderData['pickupLocation'] as Map<String, dynamic>;
          markers.add(
            Marker(
              markerId: MarkerId('pickup_${doc.id}'),
              position: LatLng(
                pickupLoc['latitude'] ?? 23.8103,
                pickupLoc['longitude'] ?? 90.4125,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(
                title: 'Pickup',
                snippet: orderData['pickupAddress'] ?? 'Pickup Location',
              ),
            ),
          );
        }

        // Add delivery marker
        if (orderData['deliveryLocation'] != null) {
          var deliveryLoc =
              orderData['deliveryLocation'] as Map<String, dynamic>;
          markers.add(
            Marker(
              markerId: MarkerId('delivery_${doc.id}'),
              position: LatLng(
                deliveryLoc['latitude'] ?? 23.8103,
                deliveryLoc['longitude'] ?? 90.4125,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: 'Delivery',
                snippet: orderData['deliveryAddress'] ?? 'Delivery Location',
              ),
            ),
          );
        }

        // Add partner marker if available
        if (orderData['partnerLocation'] != null) {
          var partnerLoc = orderData['partnerLocation'] as Map<String, dynamic>;
          markers.add(
            Marker(
              markerId: MarkerId('partner_${doc.id}'),
              position: LatLng(
                partnerLoc['latitude'] ?? 23.8103,
                partnerLoc['longitude'] ?? 90.4125,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
              infoWindow: InfoWindow(
                title: 'Partner',
                snippet: orderData['partnerName'] ?? 'Delivery Partner',
              ),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _markers = markers;
        });
      }
    } catch (e) {
      print('Error loading active deliveries: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveDeliveries,
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegend('Pickup', Colors.orange),
                _buildLegend('Delivery', Colors.green),
                _buildLegend('Partner', Colors.blue),
              ],
            ),
          ),

          // Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),

          // Active Deliveries List
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .where('status', whereIn: ['accepted', 'picked_up'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var orders = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
                // Sort locally to avoid Firestore composite index requirement
                orders.sort((a, b) {
                  try {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTime = aData['createdAt'] as Timestamp?;
                    final bTime = bData['createdAt'] as Timestamp?;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  } catch (e) {
                    return 0;
                  }
                });

                if (orders.isEmpty) {
                  return const Center(
                    child: Text('No active deliveries'),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'Active Deliveries (${orders.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          var orderData =
                              orders[index].data() as Map<String, dynamic>;
                          var orderId = orders[index].id;

                          return Card(
                            margin: const EdgeInsets.only(right: 12),
                            child: Container(
                              width: 250,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${orderId.substring(0, 6)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              orderData['status'] == 'accepted'
                                                  ? Colors.blue.shade100
                                                  : Colors.purple.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          orderData['status']
                                              .toString()
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: orderData['status'] ==
                                                    'accepted'
                                                ? Colors.blue.shade700
                                                : Colors.purple.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    orderData['userName'] ?? 'Customer',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (orderData['partnerName'] != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.delivery_dining,
                                          size: 16,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            orderData['partnerName'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: () => _focusOnOrder(orderData),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade900,
                                      minimumSize:
                                          const Size(double.infinity, 32),
                                    ),
                                    child: const Text(
                                      'View on Map',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _focusOnOrder(Map<String, dynamic> orderData) async {
    if (_mapController != null && orderData['deliveryLocation'] != null) {
      try {
        var location = orderData['deliveryLocation'] as Map<String, dynamic>;
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                location['latitude'] ?? 23.8103,
                location['longitude'] ?? 90.4125,
              ),
              zoom: 15,
            ),
          ),
        );
      } catch (e) {
        debugPrint('AdminTracking: animateCamera failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
