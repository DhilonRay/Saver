import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:saver/get_started/get_started_page.dart';
import '../home_user/home_user.dart';
import '../partner_file/home_partner/home_partner.dart';
import '../services/notification_service.dart';
import '../fare_negotiation/fare_negotiation_page.dart';
import '../user_tracking/user_tracking_page.dart';
import '../partner_file/accept_maps/accept_maps.dart';

class SplashPageController {
  /// Navigate after the splash delay using Get navigation to avoid
  /// passing a BuildContext across an async gap.
  void navigateAfterSplash() {
    Future.delayed(const Duration(seconds: 3), () async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Priority Check: Active Order Persistence
          // We check for active orders where this user is involved
          final activeUserOrder = await FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: user.uid)
              .get();

          final activePartnerOrder = await FirebaseFirestore.instance
              .collection('orders')
              .where('acceptedBy', isEqualTo: user.uid)
              .get();

          // ─── USER PERSISTENCE ───
          if (activeUserOrder.docs.isNotEmpty) {
            // Find the most recent active order
            final docs = activeUserOrder.docs
                .where((d) => !['completed', 'cancelled', 'rejected']
                    .contains(d.data()['status']))
                .toList();

            if (docs.isNotEmpty) {
              docs.sort((a, b) => (b.data()['createdAt'] as Timestamp)
                  .compareTo(a.data()['createdAt'] as Timestamp));
              final orderDoc = docs.first;
              final orderData = orderDoc.data();
              final status = orderData['status'];

              if (status == 'sent' || status == 'counter') {
                final negotiation =
                    orderData['negotiation'] as Map<String, dynamic>? ?? {};
                Get.offAll(() => FareNegotiationPage(), arguments: {
                  'requestId': orderDoc.id,
                  'driverId':
                      orderData['driverId'] ?? negotiation['driverId'] ?? '',
                  'fare': (negotiation['counterFare'] as num?)?.toDouble() ??
                      (orderData['fare'] as num?)?.toDouble() ??
                      0.0,
                });
                _initializeFCMDelayed();
                return;
              } else if (['accepted', 'pickup', 'in_transit', 'to_destination']
                  .contains(status)) {
                orderData['id'] = orderDoc.id; // Ensure ID is present
                Get.offAll(() => const UserTrackingPage(),
                    arguments: orderData);
                _initializeFCMDelayed();
                return;
              }
            }
          }

          // ─── PARTNER PERSISTENCE (ACCEPTED RIDE) ───
          if (activePartnerOrder.docs.isNotEmpty) {
            final docs = activePartnerOrder.docs
                .where((d) =>
                    !['completed', 'cancelled'].contains(d.data()['status']))
                .toList();

            if (docs.isNotEmpty) {
              docs.sort((a, b) => (b.data()['createdAt'] as Timestamp)
                  .compareTo(a.data()['createdAt'] as Timestamp));
              final orderDoc = docs.first;
              final orderData = orderDoc.data();
              orderData['id'] = orderDoc.id; // Ensure ID is present

              Get.offAll(() => const AcceptMapsPage(), arguments: {
                'request': orderData,
                'serviceRate': (orderData['finalFare'] as num?)?.toInt() ??
                    (orderData['confirmedFare'] as num?)?.toInt() ??
                    2500,
              });
              _initializeFCMDelayed();
              return;
            }
          }

          // ─── STANDARD ROLE-BASED REDIRECT ───
          // Priority 1: Check Partners/Drivers Collection for home landing
          final partnerDoc = await FirebaseFirestore.instance
              .collection('partners')
              .doc(user.uid)
              .get();

          if (partnerDoc.exists) {
            Get.offAll(() => HomePartnerPage());
            _initializeFCMDelayed();
            return;
          }

          final driverDoc = await FirebaseFirestore.instance
              .collection('drivers')
              .doc(user.uid)
              .get();

          if (driverDoc.exists) {
            Get.offAll(() => HomePartnerPage());
            _initializeFCMDelayed();
            return;
          }

          // Priority 3: Check Users Collection (Default)
          Get.offAll(() => HomePage());
          _initializeFCMDelayed();
        } catch (e) {
          print('Error in splash redirection: $e');
          Get.offAll(() => HomePage());
        }
      } else {
        Get.offAll(() => const GetStartedPage());
      }
    });
  }

  void _initializeFCMDelayed() {
    Future.delayed(const Duration(seconds: 1), () {
      NotificationService.ensureFCMInitialized();
    });
  }
}
