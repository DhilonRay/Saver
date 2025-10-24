import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerPage extends StatefulWidget {
  final String uid;
  const PartnerPage({super.key, required this.uid});

  @override
  State<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends State<PartnerPage> {
  final TextEditingController vehicleNumber = TextEditingController();
  final TextEditingController licenseNumber = TextEditingController();
  final TextEditingController ambulanceType = TextEditingController();
  final TextEditingController coverageArea = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController(); 
  final TextEditingController companyNameController = TextEditingController(); 

  Future<void> savePartnerDetails() async {
    try {
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(widget.uid)
          .set({
        'vehicleNumber': vehicleNumber.text.trim(),
        'licenseNumber': licenseNumber.text.trim(),
        'ambulanceType': ambulanceType.text.trim(),
        'coverageArea': coverageArea.text.trim(),
        'contact': contactNumberController.text.trim(), 
        'companyName': companyNameController.text.trim(), 
        'uid': widget.uid,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner info submitted successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, 
      appBar: AppBar(
        title: const Text(
          "Ambulance Partner Details",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.blueGrey.shade800, 
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildTextField(vehicleNumber, 'Vehicle ', Icons.airlines),
            const SizedBox(height: 12),
            _buildTextField(licenseNumber, 'Driver License Number', Icons.badge_outlined),
            const SizedBox(height: 12),
            _buildTextField(ambulanceType, 'Ambulance Type (AC/Non-AC)', Icons.local_hospital_outlined),
            const SizedBox(height: 12),
            _buildTextField(coverageArea, 'Coverage Area', Icons.map_outlined),
            const SizedBox(height: 12),
            _buildTextField(contactNumberController, 'Contact Number', Icons.phone_outlined), 
            const SizedBox(height: 12),
            _buildTextField(companyNameController, 'Company Name', Icons.business_outlined), 
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: savePartnerDetails,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text("Submit", style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600, 
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.blueGrey.shade800), 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey.shade600), 
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade600), 
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300), 
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300), 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.teal.shade600), 
        ),
      ),
    );
  }
}