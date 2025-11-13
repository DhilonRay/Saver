import 'dart:convert';
import 'package:http/http.dart' as http;
import 'fares_service.dart';

class PaymentService {
  // Payment configuration
  static const String _paymentGatewayUrl =
      'https://api.paymentgateway.com'; // Replace with actual gateway
  static const String _apiKey =
      'your_payment_api_key'; // Replace with actual key
  static const String _merchantId =
      'your_merchant_id'; // Replace with actual merchant ID

  // Supported payment methods
  static const List<String> supportedMethods = [
    'card',
    'bkash',
    'nagad',
    'rocket',
    'bank_transfer'
  ];

  /// Process payment for ambulance service
  static Future<PaymentResult> processAmbulancePayment({
    required String orderId,
    required FareDetails fareDetails,
    required PaymentMethod paymentMethod,
    required String userId,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      // Validate payment amount
      if (fareDetails.totalFare <= 0) {
        throw PaymentException(
            'Invalid payment amount: ${fareDetails.totalFare}');
      }

      // Validate payment method
      if (!supportedMethods.contains(paymentMethod.type)) {
        throw PaymentException(
            'Unsupported payment method: ${paymentMethod.type}');
      }

      // Prepare payment data
      final paymentData = {
        'orderId': orderId,
        'amount': fareDetails.totalFare,
        'currency': 'BDT',
        'paymentMethod': paymentMethod.type,
        'userId': userId,
        'description': 'Ambulance Service Payment',
        'fareBreakdown': fareDetails.breakdown,
        'metadata': {
          'serviceType': 'ambulance',
          'distance': fareDetails.distance,
          'urgency': fareDetails.urgency,
          'estimatedTime': fareDetails.estimatedTime,
        },
        ...paymentMethod.toMap(),
        ...paymentDetails,
      };

      // Process payment based on method
      switch (paymentMethod.type) {
        case 'card':
          return await _processCardPayment(paymentData);
        case 'bkash':
        case 'nagad':
        case 'rocket':
          return await _processMobilePayment(paymentData);
        case 'bank_transfer':
          return await _processBankTransfer(paymentData);
        default:
          throw PaymentException(
              'Payment method not implemented: ${paymentMethod.type}');
      }
    } catch (e) {
      throw PaymentException('Payment processing failed: $e');
    }
  }

  /// Process card payment
  static Future<PaymentResult> _processCardPayment(
      Map<String, dynamic> paymentData) async {
    // Simulate card payment processing
    // In production, integrate with actual payment gateway like SSLCommerz, Stripe, etc.

    final response = await http.post(
      Uri.parse('$_paymentGatewayUrl/card-payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'X-Merchant-ID': _merchantId,
      },
      body: jsonEncode(paymentData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return PaymentResult.fromMap(responseData);
    } else {
      throw PaymentException('Card payment failed: ${response.statusCode}');
    }
  }

  /// Process mobile wallet payment (bKash, Nagad, Rocket)
  static Future<PaymentResult> _processMobilePayment(
      Map<String, dynamic> paymentData) async {
    // Simulate mobile payment processing
    // In production, integrate with respective mobile wallet APIs

    final response = await http.post(
      Uri.parse('$_paymentGatewayUrl/mobile-payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(paymentData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return PaymentResult.fromMap(responseData);
    } else {
      throw PaymentException('Mobile payment failed: ${response.statusCode}');
    }
  }

  /// Process bank transfer
  static Future<PaymentResult> _processBankTransfer(
      Map<String, dynamic> paymentData) async {
    // For bank transfers, we typically generate payment instructions
    // and mark as pending until confirmation

    final bankDetails = {
      'accountName': 'Ambulance Service Provider',
      'accountNumber': '1234567890123',
      'bankName': 'Example Bank',
      'branch': 'Dhaka Main Branch',
      'routingNumber': '123456789',
    };

    return PaymentResult(
      transactionId: 'BT_${DateTime.now().millisecondsSinceEpoch}',
      status: 'pending',
      amount: paymentData['amount'],
      currency: paymentData['currency'],
      paymentMethod: paymentData['paymentMethod'],
      bankDetails: bankDetails,
      instructions:
          'Please transfer the amount to the provided bank account and upload payment proof.',
    );
  }

  /// Verify payment status
  static Future<PaymentStatus> verifyPayment(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_paymentGatewayUrl/payment-status/$transactionId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentStatus.fromMap(data);
      } else {
        throw PaymentException(
            'Failed to verify payment: ${response.statusCode}');
      }
    } catch (e) {
      throw PaymentException('Payment verification failed: $e');
    }
  }

  /// Refund payment
  static Future<RefundResult> refundPayment({
    required String transactionId,
    required double amount,
    required String reason,
  }) async {
    try {
      final refundData = {
        'transactionId': transactionId,
        'amount': amount,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_paymentGatewayUrl/refund'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(refundData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RefundResult.fromMap(data);
      } else {
        throw PaymentException('Refund failed: ${response.statusCode}');
      }
    } catch (e) {
      throw PaymentException('Refund processing failed: $e');
    }
  }

  /// Calculate payment fees (if any)
  static double calculatePaymentFee(String paymentMethod, double amount) {
    // Different payment methods may have different fees
    switch (paymentMethod) {
      case 'card':
        return amount * 0.02; // 2% fee
      case 'bkash':
      case 'nagad':
      case 'rocket':
        return amount * 0.015; // 1.5% fee
      case 'bank_transfer':
        return 50.0; // Fixed fee
      default:
        return 0.0;
    }
  }
}

/// Payment method data class
class PaymentMethod {
  final String type;
  final Map<String, dynamic> details;

  PaymentMethod({
    required this.type,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'details': details,
    };
  }

  factory PaymentMethod.card({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String cardholderName,
  }) {
    return PaymentMethod(
      type: 'card',
      details: {
        'cardNumber': cardNumber,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'cvv': cvv,
        'cardholderName': cardholderName,
      },
    );
  }

  factory PaymentMethod.mobileWallet({
    required String walletType, // bkash, nagad, rocket
    required String phoneNumber,
  }) {
    return PaymentMethod(
      type: walletType,
      details: {
        'phoneNumber': phoneNumber,
      },
    );
  }

  factory PaymentMethod.bankTransfer() {
    return PaymentMethod(
      type: 'bank_transfer',
      details: {},
    );
  }
}

/// Payment result data class
class PaymentResult {
  final String transactionId;
  final String status; // success, failed, pending
  final double amount;
  final String currency;
  final String paymentMethod;
  final DateTime timestamp;
  final Map<String, dynamic>? bankDetails;
  final String? instructions;
  final String? failureReason;

  PaymentResult({
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    DateTime? timestamp,
    this.bankDetails,
    this.instructions,
    this.failureReason,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'status': status,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp.toIso8601String(),
      'bankDetails': bankDetails,
      'instructions': instructions,
      'failureReason': failureReason,
    };
  }

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    return PaymentResult(
      transactionId: map['transactionId'],
      status: map['status'],
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'],
      paymentMethod: map['paymentMethod'],
      timestamp: DateTime.parse(map['timestamp']),
      bankDetails: map['bankDetails'],
      instructions: map['instructions'],
      failureReason: map['failureReason'],
    );
  }
}

/// Payment status data class
class PaymentStatus {
  final String transactionId;
  final String status;
  final DateTime lastUpdated;

  PaymentStatus({
    required this.transactionId,
    required this.status,
    required this.lastUpdated,
  });

  factory PaymentStatus.fromMap(Map<String, dynamic> map) {
    return PaymentStatus(
      transactionId: map['transactionId'],
      status: map['status'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}

/// Refund result data class
class RefundResult {
  final String refundId;
  final String transactionId;
  final double amount;
  final String status;
  final DateTime timestamp;

  RefundResult({
    required this.refundId,
    required this.transactionId,
    required this.amount,
    required this.status,
    required this.timestamp,
  });

  factory RefundResult.fromMap(Map<String, dynamic> map) {
    return RefundResult(
      refundId: map['refundId'],
      transactionId: map['transactionId'],
      amount: (map['amount'] as num).toDouble(),
      status: map['status'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

/// Custom payment exception
class PaymentException implements Exception {
  final String message;

  PaymentException(this.message);

  @override
  String toString() => 'PaymentException: $message';
}
