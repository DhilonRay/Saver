import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AmbulanceServicesPage extends StatefulWidget {
  const AmbulanceServicesPage({super.key});

  @override
  State<AmbulanceServicesPage> createState() => _AmbulanceServicesPageState();
}

class _AmbulanceServicesPageState extends State<AmbulanceServicesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<QuerySnapshot> _getAmbulancePartners() async {
    return await FirebaseFirestore.instance.collection('partners').get();
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied!')),
    );
  }

  void _startAirAmbulanceChat(
      BuildContext context, String partnerId, String companyName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need to be logged in to place an order.')),
      );
      return;
    }

    try {
      await _firestore.collection('orders').add({
        'userId': userId,
        'partnerId': partnerId,
        'orderStatus': 'pending',
        'createdAt': Timestamp.now(),
        'companyName': companyName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Order placed with $companyName. Waiting for confirmation.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Available Ambulances",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey.shade600,
        elevation: 4,
        shadowColor: Colors.tealAccent.withOpacity(0.6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade100, Colors.grey.shade200],
          ),
        ),
        child: FutureBuilder<QuerySnapshot>(
          future: _getAmbulancePartners(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent));
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text("Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildChargesInfoBox(),
                  const SizedBox(height: 16),
                  const Center(
                      child: Text("No ambulance partners available.",
                          style: TextStyle(fontSize: 16))),
                ],
              );
            }

            final ambulancePartners = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: ambulancePartners.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildChargesInfoBox();
                }

                final partnerDoc = ambulancePartners[index - 1];
                final partnerData =
                    partnerDoc.data() as Map<String, dynamic>;

                final companyName = partnerData['companyName'] ?? 'N/A';
                final ambulanceType = partnerData['ambulanceType'] ?? 'N/A';
                final coverageArea = partnerData['coverageArea'] ?? 'N/A';
                final createdAt = partnerData['createdAt'] != null
                    ? (partnerData['createdAt'] as Timestamp).toDate().toString()
                    : 'N/A';
                final licenseNumber = partnerData['licenseNumber'] ?? 'N/A';
                final vehicleNumber = partnerData['vehicleNumber'] ?? 'N/A';
                final contact = partnerData['contact'] ?? 'N/A';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_hospital_outlined,
                                color: Colors.teal.shade600, size: 28,
                                shadows: [
                                  Shadow(
                                      blurRadius: 3,
                                      color: Colors.tealAccent.withOpacity(0.4),
                                      offset: const Offset(1, 1)),
                                ]),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                companyName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                  shadows: [
                                    Shadow(
                                        blurRadius: 1,
                                        color: Colors.tealAccent,
                                        offset: Offset(0.5, 0.5)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                            color: Colors.grey, thickness: 1, height: 20),
                        _buildInfoRow(
                            Icons.phone_outlined, "Contact:", contact),
                        _buildInfoRow(Icons.airplanemode_active, "Vehicle:",
                            vehicleNumber),
                        _buildInfoRow(Icons.medical_services_outlined,
                            "Type:", ambulanceType),
                        _buildInfoRow(Icons.location_on_outlined,
                            "Coverage:", coverageArea),
                        _buildInfoRow(Icons.assignment_outlined, "License:",
                            licenseNumber),
                        _buildInfoRow(Icons.calendar_today_outlined,
                            "Registered:", createdAt),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (contact != 'N/A') {
                                  _copyToClipboard(context, contact);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'No contact number available to copy.')),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade500,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.greenAccent.withOpacity(0.4),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy_outlined,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                              blurRadius: 2,
                                              color: Colors.greenAccent
                                                  .withOpacity(0.6),
                                              offset: const Offset(1, 1)),
                                        ]),
                                    const SizedBox(width: 8),
                                    Text(
                                      contact != 'N/A' ? 'Call' : 'No Contact',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                final partnerId = partnerDoc.id;
                                final companyName =
                                    partnerData['companyName'] ?? 'N/A';
                                _startAirAmbulanceChat(
                                    context, partnerId, companyName);
                              },
                              icon: const Icon(Icons.assignment_outlined,
                                  color: Colors.white),
                              label: const Text('Order',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade500,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade400, shadows: [
            Shadow(
                blurRadius: 1,
                color: Colors.grey.withOpacity(0.2),
                offset: const Offset(0.5, 0.5)),
          ]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.w500, color: Colors.blueGrey.shade700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        "All ambulances charges 500 tk per km inside the metropolitan cities which have a heliport or an airport and all places outside charged 1500 tk per km.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
    );
  }
}