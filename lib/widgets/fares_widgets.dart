import 'package:flutter/material.dart';
import '../services/fares_service.dart';

class FareBreakdownWidget extends StatelessWidget {
  final FareDetails fareDetails;
  final bool showTotalOnly;
  final EdgeInsetsGeometry? padding;

  const FareBreakdownWidget({
    Key? key,
    required this.fareDetails,
    this.showTotalOnly = false,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showTotalOnly) {
      return _buildTotalOnly();
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.receipt, color: const Color(0xFF1976D2), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Fare Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fare details
          ..._buildFareItems(),

          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                FareCalculationService.formatFare(fareDetails.totalFare),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),

          // Additional info
          if (fareDetails.surgeMultiplier > 1.0 ||
              fareDetails.urgencyMultiplier > 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _getMultiplierText(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalOnly() {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Fare',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            FareCalculationService.formatFare(fareDetails.totalFare),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFareItems() {
    final items = <Widget>[];

    fareDetails.breakdown.forEach((key, value) {
      // Skip subtotal and total as they're shown separately
      if (key == 'Subtotal' || key == 'Total') return;

      // Skip zero values for cleaner display
      if (value == 0.0) return;

      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isMultiplier(key)
                        ? Colors.orange.shade700
                        : Colors.black87,
                  ),
                ),
              ),
              Text(
                _isMultiplier(key)
                    ? '${value.toStringAsFixed(1)}x'
                    : FareCalculationService.formatFare(value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      _isMultiplier(key) ? FontWeight.w500 : FontWeight.normal,
                  color: _isMultiplier(key)
                      ? Colors.orange.shade700
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    });

    return items;
  }

  bool _isMultiplier(String key) {
    return key.contains('Multiplier');
  }

  String _getMultiplierText() {
    final texts = <String>[];

    if (fareDetails.surgeMultiplier > 1.0) {
      texts.add('Surge pricing applied');
    }

    if (fareDetails.urgencyMultiplier > 1.0) {
      texts.add('${fareDetails.urgency} service charges');
    }

    return texts.join(' • ');
  }
}

class FareEstimationWidget extends StatelessWidget {
  final double distance;
  final String serviceType;
  final Map<String, int> partnerRates;
  final String urgency;

  const FareEstimationWidget({
    Key? key,
    required this.distance,
    required this.serviceType,
    required this.partnerRates,
    this.urgency = 'normal',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fareEstimate = FareCalculationService.estimateFare(
      distanceKm: distance,
      serviceType: serviceType,
      partnerRates: partnerRates,
      urgency: urgency,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Fare Estimate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Distance and time info
          Row(
            children: [
              Icon(Icons.straighten, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${distance.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '~${fareEstimate.estimatedTime.toStringAsFixed(0)} min',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Estimated fare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                FareCalculationService.formatFare(fareEstimate.totalFare),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            '* Final fare may vary based on actual route and conditions',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class FareSummaryCard extends StatelessWidget {
  final FareDetails fareDetails;
  final VoidCallback? onViewBreakdown;

  const FareSummaryCard({
    Key? key,
    required this.fareDetails,
    this.onViewBreakdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Service Charge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  FareCalculationService.formatFare(fareDetails.totalFare),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
            if (fareDetails.distance > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distance: ${fareDetails.distance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '~${fareDetails.estimatedTime.toStringAsFixed(0)} min',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            if (onViewBreakdown != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onViewBreakdown,
                    child: const Text('View Fare Breakdown'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

class IndoorOutdoorRatesWidget extends StatelessWidget {
  final Map<String, int> partnerRates;
  final bool showBreakdown;
  final EdgeInsetsGeometry? padding;

  const IndoorOutdoorRatesWidget({
    Key? key,
    required this.partnerRates,
    this.showBreakdown = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final startingRate = partnerRates['serviceRate'] ?? 2500;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.location_city,
                  color: const Color(0xFF1976D2), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Service Rates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Simplified Rate Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                children: [
                  Text(
                    '💰 Starting from',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '৳${startingRate.toString()}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (showBreakdown) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Additional Charges',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Distance charges: ৳50/km (after base distance)\n• Time charges: ৳10/minute\n• Emergency surcharge: +20-50%\n• Surge pricing: +20-100% during peak hours',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
