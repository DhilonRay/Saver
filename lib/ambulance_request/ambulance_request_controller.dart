import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AmbulanceRequestController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reactive variables
  var isLoading = false.obs;
  var requests = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      isLoading.value = true;
      
      // Listen to ambulance requests
      _firestore
          .collection('orders')
          .where('type', isEqualTo: 'ambulance')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        requests.value = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading requests: $e');
      Get.snackbar('Error', 'Failed to load requests');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('orders').doc(requestId).update({
        'status': 'accepted',
        'acceptedBy': user.uid,
        'acceptedAt': Timestamp.now(),
      });

      Get.snackbar('Success', 'Request accepted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept request: $e');
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      await _firestore.collection('orders').doc(requestId).update({
        'status': 'declined',
        'declinedAt': Timestamp.now(),
      });

      Get.snackbar('Success', 'Request declined');
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline request: $e');
    }
  }
}
