import 'package:flutter_test/flutter_test.dart';
import 'package:saver/services/supabase_service.dart';

void main() {
  group('order review payload', () {
    test('preserves ratings and complaint in a schema-safe payload', () {
      final payload = SupabaseService.buildOrderReviewPayload(
        orderId: 'order-123',
        userId: 'user-456',
        partnerId: 'partner-789',
        companyName: 'NeoSaver',
        driverRating: 4,
        companyRating: 5,
        complaint: 'Driver arrived late',
        timestamp: DateTime.parse('2026-07-02T10:00:00Z'),
      );

      expect(payload['order_id'], 'order-123');
      expect(payload['user_id'], 'user-456');
      expect(payload['partner_id'], 'partner-789');
      expect(payload['rating'], 4.5);
      expect(payload['review'], contains('"driverRating":4'));
      expect(payload['review'], contains('"companyRating":5'));
      expect(payload['review'], contains('Driver arrived late'));
      expect(payload['review'], contains('NeoSaver'));
    });
  });
}
