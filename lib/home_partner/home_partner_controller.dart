import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../about/about.dart';
import '../partner_orders/partners_orders_page.dart';
import '../chat_page/sos_chat_page.dart';
import '../auth/log_in/login_screen.dart';
import '../accept_maps/accept_maps.dart';

class HomePartnerController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();

  // Custom marker icons
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  // Reactive variables
  var currentPosition = Rx<LatLng?>(null);
  var markers = <Marker>{}.obs;
  var isLoadingLocation = true.obs;
  var isInitialLoading = true.obs;
  var mapError = ''.obs;

  // Partner data
  var partnerName = Rx<String?>('Loading...');

  // Ambulance requests
  var pendingRequests = <Map<String, dynamic>>[].obs;
  var showRequestBottomSheet = false.obs;
  var shownRequestIds = <String>{}.obs; // Track requests that have already been shown
  StreamSubscription<QuerySnapshot>? _requestsSubscription;

  // Helper function to format address display
  String _formatAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address not provided - contact patient';
    }
    
    // Check if it's coordinates format
    if (address.startsWith('Lat:') && address.contains('Lng:')) {
      return 'Location coordinates available - contact patient for details';
    }
    
    return address;
  }

  // Default position (Dhaka, Bangladesh) in case location fails
  static const LatLng defaultPosition = LatLng(23.8103, 90.4125);

  Future<void> _loadCustomIcons() async {
    try {
      debugPrint('Loading custom PNG icons for partner...');
      currentLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/markers/ambulance.png',
      );
      userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      debugPrint('Partner custom icons loaded successfully');
    } catch (e) {
      debugPrint('Failed to load partner custom icons: $e');
      currentLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadCustomIcons();
    _loadPartnerData();
    _getCurrentLocation();
    _listenForRequests();
  }

  @override
  void onClose() {
    _requestsSubscription?.cancel();
    shownRequestIds.clear(); // Clear shown requests when controller closes
    super.onClose();
  }

  /// Reset shown requests (useful when driver logs out and logs back in)
  void resetShownRequests() {
    shownRequestIds.clear();
    showRequestBottomSheet.value = false;
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permission is required to show your location on the map',
            backgroundColor: Colors.orange[600],
            colorText: Colors.white,
          );
          isLoadingLocation.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Denied',
          'Location permission is permanently denied. Please enable it in settings.',
          backgroundColor: Colors.red[600],
          colorText: Colors.white,
        );
        isLoadingLocation.value = false;
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition.value = LatLng(position.latitude, position.longitude);

      // Update markers reactively
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: currentPosition.value!,
          infoWindow: InfoWindow(title: 'Your Ambulance Location'),
          icon: currentLocationIcon,
        ),
      );

      // Update partner location in Firestore
      await _updatePartnerLocation();

      isLoadingLocation.value = false;
      isInitialLoading.value = false;
    } catch (e) {
      // Use default position if location fails
      currentPosition.value = defaultPosition;
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: currentPosition.value!,
          infoWindow: InfoWindow(title: 'Default Location (Dhaka)'),
          icon: currentLocationIcon,
        ),
      );

      isLoadingLocation.value = false;
      isInitialLoading.value = false;
    }
  }

  Future<void> _updatePartnerLocation() async {
    try {
      final user = _auth.currentUser;
      if (user != null && currentPosition.value != null) {
        await FirebaseFirestore.instance.collection('partners').doc(user.uid).update({
          'latitude': currentPosition.value!.latitude,
          'longitude': currentPosition.value!.longitude,
          'lastUpdated': Timestamp.now(),
          'isOnline': true,
        });
      }
    } catch (e) {
      debugPrint('Failed to update partner location: $e');
    }
  }

  Future<void> _loadPartnerData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get partner name from users collection where the full name is stored
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          partnerName.value = userData?['name'] ?? 'Partner';
        } else {
          partnerName.value = 'Partner';
        }
      }
    } catch (e) {
      debugPrint('Failed to load partner data: $e');
      partnerName.value = 'Partner';
    }
  }

  void _listenForRequests() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _requestsSubscription = FirebaseFirestore.instance
          .collection('orders')
          .where('type', isEqualTo: 'ambulance')
          .where('status', isEqualTo: 'pending')
          .where('partnerId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        pendingRequests.value = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();

        // Show bottom sheet if there are pending requests that haven't been shown yet
        final newRequests = pendingRequests.where((request) => !shownRequestIds.contains(request['id'])).toList();
        
        if (newRequests.isNotEmpty && !showRequestBottomSheet.value) {
          final firstNewRequest = newRequests.first;
          shownRequestIds.add(firstNewRequest['id']); // Mark as shown
          showRequestBottomSheet.value = true;
          debugPrint('🔔 Showing bottom sheet for new request: ${firstNewRequest['id']}');
          _showRequestBottomSheet(firstNewRequest);
        }
      });
    } catch (e) {
      debugPrint('Failed to listen for requests: $e');
    }
  }

  void _showRequestBottomSheet(Map<String, dynamic> request) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New Ambulance Request',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Location: ${_formatAddress(request['pickupAddress'])}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Patient: ${request['patientName'] ?? 'Name not provided'}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Phone: ${request['phone'] ?? 'Phone not provided - check user email'}',
              style: TextStyle(fontSize: 16),
            ),
            if (request['email'] != null && request['email'].toString().isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Email: ${request['email']}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => acceptRequest(request['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Accept'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => declineRequest(request['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isDismissible: false,
    );
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get the request data before updating status (since it will be filtered out)
      final request = pendingRequests.firstWhere((req) => req['id'] == requestId);

      await FirebaseFirestore.instance.collection('orders').doc(requestId).update({
        'status': 'accepted',
        'acceptedBy': user.uid,
        'acceptedAt': Timestamp.now(),
      });

      Get.back(); // Close bottom sheet
      showRequestBottomSheet.value = false;
      debugPrint('✅ Request accepted: $requestId');

      // Navigate to accept maps page with request data
      Get.to(() => AcceptMapsPage(), arguments: request);

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept request: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(requestId).update({
        'status': 'declined',
        'declinedAt': Timestamp.now(),
      });

      Get.back(); // Close bottom sheet
      showRequestBottomSheet.value = false;
      debugPrint('❌ Request declined: $requestId');

      Get.snackbar(
        'Success',
        'Request declined',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to decline request: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // Navigation methods
  void navigateToPartnersOrders() {
    Get.to(() => PartnersOrdersPage());
  }

  void navigateToAboutUs() {
    Get.to(() => AboutUsPage());
  }

  void navigateToSOSChat() {
    Get.to(() => const SOSChatPage());
  }

  Future<void> signOut() async {
    try {
      // Update online status to false
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('partners').doc(user.uid).update({
          'isOnline': false,
        });
      }

      await _auth.signOut();
      Get.offAll(() => LoginPage());
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: $e');
    }
  }

  void onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }

    // If we have current position, animate to it
    if (currentPosition.value != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentPosition.value!, zoom: 14),
        ),
      );
    }
  }

  // Zoom methods
  Future<void> zoomIn() async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.zoomIn());
    }
  }

  Future<void> zoomOut() async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.zoomOut());
    }
  }

  // Method to show route to user location (for accepted requests)
  Future<void> showRouteToUser(double latitude, double longitude) async {
    try {
      final userLatLng = LatLng(latitude, longitude);

      // Add user location marker
      markers.add(
        Marker(
          markerId: MarkerId('user_location_$latitude$longitude'),
          position: userLatLng,
          infoWindow: InfoWindow(title: 'Patient Location'),
          icon: userLocationIcon,
        ),
      );

      // Move camera to show both partner location and user location
      if (_controller.isCompleted && currentPosition.value != null) {
        final GoogleMapController controller = await _controller.future;
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            latitude < currentPosition.value!.latitude ? latitude : currentPosition.value!.latitude,
            longitude < currentPosition.value!.longitude ? longitude : currentPosition.value!.longitude,
          ),
          northeast: LatLng(
            latitude > currentPosition.value!.latitude ? latitude : currentPosition.value!.latitude,
            longitude > currentPosition.value!.longitude ? longitude : currentPosition.value!.longitude,
          ),
        );
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      }

      Get.snackbar(
        'Route Updated',
        'Patient location has been marked on the map',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to show route to user: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
