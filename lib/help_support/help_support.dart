import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'help_support_controller.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  // Enhanced medical-themed color palette
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HelpSupportController>(
      init: HelpSupportController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Help & Support',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: primaryBlue,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryBlue),
              onPressed: () => Get.back(),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lightBlue, Colors.white],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_center,
                          size: 60,
                          color: primaryBlue,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'How can we help you?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Find answers or get in touch',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Quick Help Section
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: primaryBlue, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Quick Help',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // FAQ cards
                  _faqCard(
                    icon: Icons.shopping_cart,
                    title: 'How to place an order?',
                    answer: 'Open the app, choose a service and fill required details. Tap Confirm to send an order.'
                  ),
                  _faqCard(
                    icon: Icons.cancel,
                    title: 'Can I cancel an order?',
                    answer: 'Yes — orders can be cancelled while they are pending. Contact support if you face issues.'
                  ),
                  _faqCard(
                    icon: Icons.payment,
                    title: 'Payment options',
                    answer: 'We support cash and mobile payment methods depending on your partner settings.'
                  ),

                  const SizedBox(height: 30),

                  // Contact Us Section
                  Row(
                    children: [
                      Icon(Icons.contact_support, color: primaryBlue, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _contactButton(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          contact: 'nobita105176@gmail.com',
                          context: context,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _contactButton(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          contact: '+01581822846',
                          context: context,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Send a message Section
                  Row(
                    children: [
                      Icon(Icons.message, color: primaryBlue, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Send a Message',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: controller.nameController,
                          decoration: InputDecoration(
                            labelText: 'Your name',
                            prefixIcon: Icon(Icons.person, color: primaryBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryBlue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accentBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: lightBlue.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: primaryBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryBlue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accentBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: lightBlue.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: controller.messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Message',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.message, color: primaryBlue),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryBlue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accentBlue, width: 2),
                            ),
                            filled: true,
                            fillColor: lightBlue.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Obx(() {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              onPressed: controller.loading.value ? null : controller.submit,
                              child: controller.loading.value
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Send Message',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'We usually respond within 24-48 hours',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _faqCard({required IconData icon, required String title, required String answer}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryBlue, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    answer,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required String contact,
    required BuildContext context,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryBlue),
        ),
      ),
      onPressed: () => _showContactDialog(context, contact),
    );
  }

  void _showContactDialog(BuildContext context, String contact) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Contact Info',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: Text(
          contact,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: contact));
              Get.back();
              Get.snackbar(
                'Copied',
                'Contact copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: primaryBlue,
                colorText: Colors.white,
              );
            },
            child: Text('Copy', style: TextStyle(color: primaryBlue)),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close', style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
  }
}
