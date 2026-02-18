import 'package:flutter/material.dart';

/// Reusable billing breakdown widget showing:
/// Fare → Service Charge (5%) → Grand Total
/// Used in FareNegotiationPage and PaymentPage.
class BillingBreakdownWidget extends StatelessWidget {
  final double fare;
  final double serviceChargePercent;
  final bool showDivider;

  const BillingBreakdownWidget({
    super.key,
    required this.fare,
    this.serviceChargePercent = 5.0,
    this.showDivider = true,
  });

  double get serviceCharge => fare * (serviceChargePercent / 100);
  double get grandTotal => fare + serviceCharge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.blue.shade800,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'বিলিং বিবরণ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fare row
          _buildRow(
            label: 'ভাড়া (Fare)',
            value: '৳${fare.toStringAsFixed(0)}',
            icon: Icons.local_taxi,
            iconColor: Colors.blue.shade600,
          ),
          const SizedBox(height: 10),

          // Service Charge row
          _buildRow(
            label:
                'সার্ভিস চার্জ (${serviceChargePercent.toStringAsFixed(0)}%)',
            value: '৳${serviceCharge.toStringAsFixed(0)}',
            icon: Icons.percent,
            iconColor: Colors.orange.shade600,
          ),

          if (showDivider) ...[
            const SizedBox(height: 14),
            Divider(color: Colors.blue.shade300, thickness: 1.2),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 14),

          // Grand Total row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade900.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200, width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        size: 20, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'সর্বমোট (Grand Total)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                Text(
                  '৳${grandTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
