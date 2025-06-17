import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100, 
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'About Us',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white), 
          ),
          backgroundColor: Colors.blueGrey.shade800, 
          elevation: 2, 
          centerTitle: true, 
        ),
        body: SingleChildScrollView( 
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Center(
                child: Icon(
                  Icons.local_hospital,
                  size: 60, 
                  color: const Color.fromARGB(255, 148, 11, 18), 
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'NeoSaver',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800, 
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal, 
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'NeoSaver is dedicated to transforming emergency medical response in Bangladesh. We aim to connect individuals in critical situations with the nearest available and verified ambulance services swiftly and efficiently.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Real-time location tracking is at the heart of our service. Users can see the live location of nearby ambulances, providing crucial information and reducing anxiety during emergencies. This feature ensures transparency and allows for better coordination.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We prioritize the safety and reliability of our service. All ambulance providers on the NeoSaver platform undergo a verification process to ensure they meet our standards. This commitment to quality helps users access trusted emergency transport.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Our goal is simple: to save lives by making emergency medical assistance accessible quickly and reliably. In critical moments, every second counts, and NeoSaver is designed to make those seconds work for you.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal, 
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'For any inquiries or support, please feel free to contact us at roydhilon@gmail.com.', 
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}