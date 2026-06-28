import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ambulance_service_controller.dart';

class AmbulanceServicesPage extends StatelessWidget {
  const AmbulanceServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AmbulanceServiceController>(
      init: AmbulanceServiceController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Available Ambulances",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: Colors.blueGrey.shade600,
            elevation: 4,
            shadowColor: Colors.tealAccent.withValues(alpha: 0.6),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.refreshData,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.teal.shade100, Colors.grey.shade200],
              ),
            ),
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.ambulancePartners.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                );
              }

              if (controller.ambulancePartners.isEmpty) {
                return ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _buildChargesInfoBox(),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        "No ambulance partners available.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: controller.ambulancePartners.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildChargesInfoBox();
                  }

                                  final partnerData = controller.ambulancePartners[index - 1];
                  final partnerId = partnerData['uid'] ?? partnerData['id'] ?? '';

                  final companyName = partnerData['companyName'] ?? 'N/A';
                  final ambulanceType = partnerData['ambulanceType'] ?? 'N/A';
                  final coverageArea = partnerData['coverageArea'] ?? 'N/A';
                  final createdAt = partnerData['createdAt'] != null
                      ? partnerData['createdAt'].toString()
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
                          color: Colors.grey.withValues(alpha: 0.3),
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
                                  color: Colors.teal.shade600,
                                  size: 28,
                                  shadows: [
                                    Shadow(
                                        blurRadius: 3,
                                        color: Colors.tealAccent
                                            .withValues(alpha: 0.4),
                                        offset: const Offset(1, 1)),
                                  ]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  companyName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.directions_car, 'Ambulance Type',
                              ambulanceType),
                          _buildInfoRow(
                              Icons.location_on, 'Coverage Area', coverageArea),
                          _buildInfoRow(
                              Icons.calendar_today, 'Registered', createdAt),
                          _buildInfoRow(
                              Icons.badge, 'License Number', licenseNumber),
                          _buildInfoRow(Icons.confirmation_number,
                              'Vehicle Number', vehicleNumber),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => controller.startAirAmbulanceChat(
                                  partnerId, companyName),
                              icon: const Icon(Icons.send, size: 18),
                              label: const Text('Book Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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
            }),
          ),
        );
      },
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
                color: Colors.grey.withValues(alpha: 0.2),
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
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.right,
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
        color: Colors.grey.withValues(alpha: 0.3),
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
