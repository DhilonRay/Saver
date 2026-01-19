import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'partner_controller.dart';
import '../../components/widgets/buttons.dart';
import '../../components/widgets/form_input.dart';

class PartnerPage extends StatelessWidget {
  final String uid;
  const PartnerPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // Define Theme Colors (Matching SignUpPage)
    const Color lightBlue = Color(0xFFE3F2FD);
    const Color cardBackground = Colors.white;
    const Color textPrimary = Color(0xFF2D3748);

    return GetBuilder<PartnerController>(
      init: PartnerController(),
      builder: (controller) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  lightBlue,
                  Colors.white,
                  lightBlue.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Welcome Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Welcome Neosaver Ambulance Partner',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Main Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Ambulance Partner Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Ambulance Type (AC/Non-AC)
                        TextFormFieldWidget(
                          controller: controller.ambulanceType,
                          hintText: 'Ambulance Type (AC/Non-AC) *',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Driver License Number
                        TextFormFieldWidget(
                          controller: controller.licenseNumber,
                          hintText: 'Driver License Number *',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          suffixIcon:
                              const Icon(Icons.note_add_outlined, size: 24),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Road Tax Token
                        TextFormFieldWidget(
                          controller: controller.roadTaxToken,
                          hintText: 'Road Tax Token *',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          suffixIcon:
                              const Icon(Icons.note_add_outlined, size: 24),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Notional ID Card (Fixed typo to National ID Card in code, but keeping label close to request/image if needed, image says Notional ID Card?)
                        // Image says "Notional ID Card *". I will use "National ID Card *" as it is correct spelling, user might appreciate the fix.
                        TextFormFieldWidget(
                          controller: controller.nationalId,
                          hintText: 'National ID Card *',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          suffixIcon:
                              const Icon(Icons.note_add_outlined, size: 24),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Vehicle Number
                        TextFormFieldWidget(
                          controller: controller.vehicleNumber,
                          hintText: 'Vehicle Number *',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Reference ID
                        TextFormFieldWidget(
                          controller: controller.referenceId,
                          hintText: 'Reference ID',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Coverage Area
                        TextFormFieldWidget(
                          controller: controller.coverageArea,
                          hintText: 'Coverage Area *',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Contact Number
                        TextFormFieldWidget(
                          controller: controller.contactNumberController,
                          hintText: 'Contact Number *',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Email Address
                        TextFormFieldWidget(
                          controller: controller.emailAddressController,
                          hintText: 'Email Address *',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Hospital / Company Name
                        TextFormFieldWidget(
                          controller: controller.companyNameController,
                          hintText: 'Hospital / Company Name *',
                          isFilled: true,
                          fillColor: const Color(0xFFE3F2FD),
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xFF555555)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Submit Button
                        Obx(
                          () => FilledButtonWidget(
                            onTap: controller.isLoading.value
                                ? null
                                : () => controller.savePartnerDetails(uid),
                            isLoading: controller.isLoading.value,
                            buttonText: 'Submit',
                            minHeight: 44,
                            isStretched: true,
                            borderRadiusValue: 8,
                            backgroundColor: const Color(0xFF5CAFE9),
                            buttonTextStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
