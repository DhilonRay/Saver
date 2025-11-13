import 'dart:math';

class FareDetails {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeMultiplier;
  final double urgencyMultiplier;
  final double totalFare;
  final double distance;
  final double estimatedTime;
  final String urgency;
  final Map<String, double> breakdown;

  FareDetails({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeMultiplier,
    required this.urgencyMultiplier,
    required this.totalFare,
    required this.distance,
    required this.estimatedTime,
    required this.urgency,
    required this.breakdown,
  });

  Map<String, dynamic> toMap() {
    return {
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'surgeMultiplier': surgeMultiplier,
      'urgencyMultiplier': urgencyMultiplier,
      'totalFare': totalFare,
      'distance': distance,
      'estimatedTime': estimatedTime,
      'urgency': urgency,
      'breakdown': breakdown,
    };
  }

  factory FareDetails.fromMap(Map<String, dynamic> map) {
    return FareDetails(
      baseFare: (map['baseFare'] as num?)?.toDouble() ?? 0.0,
      distanceFare: (map['distanceFare'] as num?)?.toDouble() ?? 0.0,
      timeFare: (map['timeFare'] as num?)?.toDouble() ?? 0.0,
      surgeMultiplier: (map['surgeMultiplier'] as num?)?.toDouble() ?? 1.0,
      urgencyMultiplier: (map['urgencyMultiplier'] as num?)?.toDouble() ?? 1.0,
      totalFare: (map['totalFare'] as num?)?.toDouble() ?? 0.0,
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      estimatedTime: (map['estimatedTime'] as num?)?.toDouble() ?? 0.0,
      urgency: map['urgency'] as String? ?? 'normal',
      breakdown: Map<String, double>.from(map['breakdown'] ?? {}),
    );
  }
}

class FareCalculationService {
  // Default rates (can be overridden by partner-specific rates)
  static const double defaultBaseFare = 500.0; // Base fare in BDT
  static const double defaultPerKmRate = 50.0; // Per kilometer rate
  static const double defaultPerMinuteRate = 10.0; // Per minute rate
  static const double defaultServiceRate = 2500.0; // Fixed service rate

  // Fare validation limits
  static const double minimumFare = 500.0; // Minimum fare in BDT
  static const double maximumFare = 50000.0; // Maximum fare in BDT (50k BDT)
  static const double minimumDistanceKm =
      0.1; // Minimum distance for calculation
  static const double maximumDistanceKm = 500.0; // Maximum distance limit
  static const double minimumTimeMinutes = 1.0; // Minimum time for calculation
  static const double maximumTimeMinutes = 1440.0; // Maximum time (24 hours)

  // Surge pricing multipliers
  static const Map<String, double> surgeMultipliers = {
    'low': 1.0,
    'normal': 1.0,
    'high': 1.2,
    'peak': 1.5,
    'emergency': 2.0,
  };

  // Urgency multipliers
  static const Map<String, double> urgencyMultipliers = {
    'normal': 1.0,
    'urgent': 1.3,
    'emergency': 1.8,
  };

  /// Calculate fare for ambulance service
  static FareDetails calculateAmbulanceFare({
    required double distanceKm,
    required double estimatedTimeMinutes,
    required String urgency,
    required Map<String, int> partnerRates,
    String surgeLevel = 'normal',
    double additionalCharges = 0.0,
  }) {
    // Validate inputs
    validateFareInputs(
      distanceKm: distanceKm,
      estimatedTimeMinutes: estimatedTimeMinutes,
      urgency: urgency,
      partnerRates: partnerRates,
    );

    // Get partner rate or use default
    final serviceRate =
        partnerRates['serviceRate']?.toDouble() ?? defaultServiceRate;

    // For ambulance, we use a fixed service rate
    // But we can add distance-based charges for long distances
    double baseFare = serviceRate;
    double distanceFare = 0.0;

    // Add distance charges if distance is significant
    if (distanceKm > 10) {
      distanceFare = (distanceKm - 10) * defaultPerKmRate;
    }

    // Calculate time-based fare (for waiting time, etc.)
    final timeFare = estimatedTimeMinutes * defaultPerMinuteRate;

    // Apply surge multiplier
    final surgeMultiplier = surgeMultipliers[surgeLevel] ?? 1.0;

    // Apply urgency multiplier
    final urgencyMultiplier = urgencyMultipliers[urgency] ?? 1.0;

    // Calculate subtotal before multipliers
    final subtotal = baseFare + distanceFare + timeFare + additionalCharges;

    // Apply multipliers
    final totalFare = subtotal * surgeMultiplier * urgencyMultiplier;

    // Create breakdown
    final breakdown = {
      'Base Fare': baseFare,
      'Distance Charges': distanceFare,
      'Time Charges': timeFare,
      'Additional Charges': additionalCharges,
      'Subtotal': subtotal,
      'Surge Multiplier (${surgeLevel})': surgeMultiplier,
      'Urgency Multiplier (${urgency})': urgencyMultiplier,
      'Total': totalFare,
    };

    final fareDetails = FareDetails(
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      surgeMultiplier: surgeMultiplier,
      urgencyMultiplier: urgencyMultiplier,
      totalFare: totalFare,
      distance: distanceKm,
      estimatedTime: estimatedTimeMinutes,
      urgency: urgency,
      breakdown: breakdown,
    );

    // Validate and adjust fare if necessary
    return validateAndAdjustFare(fareDetails);
  }

  /// Calculate fare for ride service (taxi/cab)
  static FareDetails calculateRideFare({
    required double distanceKm,
    required double estimatedTimeMinutes,
    required Map<String, int> partnerRates,
    String surgeLevel = 'normal',
    double additionalCharges = 0.0,
  }) {
    // For ride services, use distance and time-based calculation
    final baseFare = defaultBaseFare;
    final distanceFare = distanceKm * defaultPerKmRate;
    final timeFare = estimatedTimeMinutes * defaultPerMinuteRate;

    // Apply surge multiplier
    final surgeMultiplier = surgeMultipliers[surgeLevel] ?? 1.0;

    // Calculate subtotal
    final subtotal = baseFare + distanceFare + timeFare + additionalCharges;

    // Apply surge multiplier
    final totalFare = subtotal * surgeMultiplier;

    // Create breakdown
    final breakdown = {
      'Base Fare': baseFare,
      'Distance Charges (${distanceKm.toStringAsFixed(1)}km)': distanceFare,
      'Time Charges (${estimatedTimeMinutes.toStringAsFixed(0)}min)': timeFare,
      'Additional Charges': additionalCharges,
      'Subtotal': subtotal,
      'Surge Multiplier (${surgeLevel})': surgeMultiplier,
      'Total': totalFare,
    };

    return FareDetails(
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      surgeMultiplier: surgeMultiplier,
      urgencyMultiplier: 1.0, // Not applicable for rides
      totalFare: totalFare,
      distance: distanceKm,
      estimatedTime: estimatedTimeMinutes,
      urgency: 'normal', // Not applicable for rides
      breakdown: breakdown,
    );
  }

  /// Estimate fare before booking (rough estimate)
  static FareDetails estimateFare({
    required double distanceKm,
    required String serviceType, // 'ambulance' or 'ride'
    required Map<String, int> partnerRates,
    String urgency = 'normal',
  }) {
    // Validate inputs
    validateFareInputs(
      distanceKm: distanceKm,
      estimatedTimeMinutes: 1.0, // Use minimum time for estimation
      urgency: urgency,
      partnerRates: partnerRates,
    );

    // Rough time estimation: assume 30km/h average speed
    final estimatedTimeMinutes = (distanceKm / 30.0) * 60.0;

    if (serviceType == 'ambulance') {
      return calculateAmbulanceFare(
        distanceKm: distanceKm,
        estimatedTimeMinutes: estimatedTimeMinutes,
        urgency: urgency,
        partnerRates: partnerRates,
      );
    } else {
      return calculateRideFare(
        distanceKm: distanceKm,
        estimatedTimeMinutes: estimatedTimeMinutes,
        partnerRates: partnerRates,
      );
    }
  }

  /// Get current surge level based on time and demand
  static String getCurrentSurgeLevel() {
    final now = DateTime.now();
    final hour = now.hour;

    // Peak hours: 7-9 AM and 5-8 PM
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 20)) {
      return 'peak';
    }
    // High demand: 6-7 AM and 4-5 PM
    else if ((hour >= 6 && hour <= 7) || (hour >= 16 && hour <= 17)) {
      return 'high';
    }
    // Normal hours
    else {
      return 'normal';
    }
  }

  /// Format fare amount as currency
  static String formatFare(double amount) {
    return '৳${amount.toStringAsFixed(0)}';
  }

  /// Validate fare amount and ensure it's within acceptable limits
  static FareDetails validateAndAdjustFare(FareDetails fareDetails) {
    double adjustedTotal = fareDetails.totalFare;

    // Ensure minimum fare
    if (adjustedTotal < minimumFare) {
      adjustedTotal = minimumFare;
    }

    // Ensure maximum fare
    if (adjustedTotal > maximumFare) {
      adjustedTotal = maximumFare;
    }

    // If total was adjusted, update the breakdown
    if (adjustedTotal != fareDetails.totalFare) {
      final adjustedBreakdown = Map<String, double>.from(fareDetails.breakdown);
      adjustedBreakdown['Total'] = adjustedTotal;
      adjustedBreakdown['Fare Adjustment'] =
          adjustedTotal - fareDetails.totalFare;

      return FareDetails(
        baseFare: fareDetails.baseFare,
        distanceFare: fareDetails.distanceFare,
        timeFare: fareDetails.timeFare,
        surgeMultiplier: fareDetails.surgeMultiplier,
        urgencyMultiplier: fareDetails.urgencyMultiplier,
        totalFare: adjustedTotal,
        distance: fareDetails.distance,
        estimatedTime: fareDetails.estimatedTime,
        urgency: fareDetails.urgency,
        breakdown: adjustedBreakdown,
      );
    }

    return fareDetails;
  }

  /// Validate input parameters for fare calculation
  static void validateFareInputs({
    required double distanceKm,
    required double estimatedTimeMinutes,
    required String urgency,
    required Map<String, int> partnerRates,
  }) {
    // Validate distance
    if (distanceKm < minimumDistanceKm || distanceKm > maximumDistanceKm) {
      throw ArgumentError(
          'Distance must be between $minimumDistanceKm and $maximumDistanceKm km');
    }

    // Validate time
    if (estimatedTimeMinutes < minimumTimeMinutes ||
        estimatedTimeMinutes > maximumTimeMinutes) {
      throw ArgumentError(
          'Estimated time must be between $minimumTimeMinutes and $maximumTimeMinutes minutes');
    }

    // Validate urgency
    if (!urgencyMultipliers.containsKey(urgency)) {
      throw ArgumentError('Invalid urgency level: $urgency');
    }

    // Validate partner rates
    if (partnerRates['serviceRate'] != null &&
        partnerRates['serviceRate']! < 0) {
      throw ArgumentError('Service rate cannot be negative');
    }
  }

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
