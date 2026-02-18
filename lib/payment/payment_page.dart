import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'payment_controller.dart';
import '../widgets/billing_breakdown_widget.dart';

/// Payment page with Cash and bKash options.
class PaymentPage extends StatelessWidget {
  PaymentPage({super.key});

  final controller = Get.put(PaymentController());
  final TextEditingController _trxIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'পেমেন্ট',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Obx(() {
        if (controller.isPaymentConfirmed.value) {
          return _buildPaymentSuccessView();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Billing Breakdown
              BillingBreakdownWidget(fare: controller.fare),
              const SizedBox(height: 24),

              // Payment Method Selection Header
              Text(
                'পেমেন্ট পদ্ধতি নির্বাচন করুন',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 14),

              // Cash Option
              _buildPaymentMethodCard(
                title: 'ক্যাশ (Cash)',
                subtitle: 'রাইড শেষে সরাসরি ড্রাইভারকে ক্যাশ দিন',
                icon: Icons.money,
                iconColor: Colors.green.shade700,
                bgColor: Colors.green.shade50,
                borderColor: Colors.green.shade300,
                isSelected: controller.paymentMethod.value == 'cash',
                onTap: () => controller.selectPaymentMethod('cash'),
              ),
              const SizedBox(height: 12),

              // bKash Option
              _buildPaymentMethodCard(
                title: 'bKash',
                subtitle: 'bKash এ টাকা পাঠান এবং TRXID দিন',
                icon: Icons.phone_android,
                iconColor: Colors.pink.shade700,
                bgColor: Colors.pink.shade50,
                borderColor: Colors.pink.shade300,
                isSelected: controller.paymentMethod.value == 'bkash',
                onTap: () => controller.selectPaymentMethod('bkash'),
              ),
              const SizedBox(height: 20),

              // Cash details section
              if (controller.paymentMethod.value == 'cash') ...[
                _buildCashDetailsCard(),
              ],

              // bKash details section
              if (controller.paymentMethod.value == 'bkash') ...[
                _buildBkashDetailsCard(),
              ],

              const SizedBox(height: 24),

              // Confirm Payment Button
              _buildConfirmButton(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? iconColor.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected ? iconColor : Colors.grey, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? iconColor : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? iconColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'ক্যাশ পেমেন্ট নির্দেশনা',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
              '1', 'রাইড শেষ হওয়ার পর ড্রাইভারকে সরাসরি ক্যাশ দিন'),
          const SizedBox(height: 8),
          _buildInstructionStep(
              '2', 'মোট পরিমাণ: ৳${controller.grandTotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildInstructionStep('3', 'সার্ভিস চার্জ সহ পুরো টাকা দিন'),
        ],
      ),
    );
  }

  Widget _buildBkashDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.pink.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, size: 20, color: Colors.pink.shade700),
              const SizedBox(width: 8),
              Text(
                'bKash পেমেন্ট নির্দেশনা',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Driver's bKash number
          if (controller.driverBkashNumber.value.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_circle,
                      size: 36, color: Colors.pink.shade400),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ড্রাইভারের bKash নম্বর',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.driverBkashNumber.value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink.shade800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Copy button
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: controller.driverBkashNumber.value));
                      Get.snackbar(
                        '✅ কপি হয়েছে',
                        'bKash নম্বর কপি করা হয়েছে',
                        backgroundColor: Colors.green.shade100,
                        colorText: Colors.green.shade800,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    icon: Icon(Icons.copy, color: Colors.pink.shade600),
                    tooltip: 'কপি করুন',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ড্রাইভারের bKash নম্বর পাওয়া যায়নি। ড্রাইভারের সাথে যোগাযোগ করুন।',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Instructions
          _buildInstructionStep('1',
              'উপরের নম্বরে ৳${controller.grandTotal.toStringAsFixed(0)} পাঠান'),
          const SizedBox(height: 8),
          _buildInstructionStep('2', 'পেমেন্ট সম্পন্ন হলে TRXID নিচে লিখুন'),
          const SizedBox(height: 14),

          // TRXID Input
          TextField(
            controller: _trxIdController,
            decoration: InputDecoration(
              labelText: 'TRXID',
              hintText: 'bKash TRXID লিখুন (যেমন: 9K3H7F2L1M)',
              prefixIcon:
                  Icon(Icons.confirmation_number, color: Colors.pink.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink.shade400, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => controller.trxId.value = value,
          ),
          const SizedBox(height: 10),
          Text(
            '* TRXID ড্রাইভার কনফার্মেশন ও অ্যাডমিন প্যানেল ভেরিফিকেশনের জন্য ব্যবহৃত হবে',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String stepNumber, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final isBkash = controller.paymentMethod.value == 'bkash';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.isLoading.value
            ? null
            : () {
                if (isBkash) {
                  controller.submitBkashPayment(_trxIdController.text);
                } else {
                  controller.confirmCashPayment();
                }
              },
        icon: controller.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(isBkash ? Icons.send : Icons.check_circle, size: 22),
        label: Text(
          controller.isLoading.value
              ? 'প্রসেসিং...'
              : isBkash
                  ? 'bKash পেমেন্ট জমা দিন'
                  : 'ক্যাশ পেমেন্ট নিশ্চিত করুন',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isBkash ? Colors.pink.shade600 : Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 4,
          shadowColor: isBkash ? Colors.pink.shade200 : Colors.green.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSuccessView() {
    final isBkash = controller.paymentMethod.value == 'bkash';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'পেমেন্ট সফল!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              isBkash
                  ? 'আপনার bKash TRXID জমা দেওয়া হয়েছে।\nড্রাইভার ও অ্যাডমিন ভেরিফাই করবে।'
                  : 'ক্যাশ পেমেন্ট নিশ্চিত হয়েছে।\nরাইড শেষে ড্রাইভারকে টাকা দিন।',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // TRXID display for bKash
            if (isBkash && controller.trxId.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number,
                        size: 20, color: Colors.pink.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'TRXID: ${controller.trxId.value}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Billing summary
            BillingBreakdownWidget(fare: controller.fare),

            const SizedBox(height: 30),

            // Go Home button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.offAllNamed('/'),
                icon: const Icon(Icons.home, size: 22),
                label: const Text(
                  'হোম এ ফিরে যান',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
