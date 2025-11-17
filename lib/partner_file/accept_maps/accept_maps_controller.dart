import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/directions.dart' as directions;
import 'package:lottie/lottie.dart' as lottie hide Marker;
import '../../services/notification_service.dart';

class AcceptMapsController extends GetxController {
  final Completer<GoogleMapController> _controller = Completer();

  // Custom marker icons
  BitmapDescriptor partnerLocationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor userLocationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  // Reactive variables
  var partnerPosition = Rx<LatLng?>(null);
  var userPosition = Rx<LatLng?>(null);
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isLoadingLocation = true.obs;
  var requestData = Rx<Map<String, dynamic>?>(null);
  var showSlidePanel = false.obs;

  // Service rate from home partner
  var serviceRate = 2500.obs;

  // ETA variables
  var estimatedTime = Rx<String>('Calculating...');
  var estimatedDistance = Rx<double>(0.0);
  var isCalculatingETA = false.obs;

  // Live tracking variables
  var isLiveTracking = false.obs;
  StreamSubscription<Position>? _positionSubscription;

  // Timing and performance optimization
  Timer? _firestoreUpdateTimer;
  Timer? _cameraUpdateTimer;
  Timer? _etaUpdateTimer;
  Position? _lastFirestorePosition;
  Position? _lastCameraPosition;
  static const Duration _firestoreUpdateInterval =
      Duration(seconds: 3); // Update every 3 seconds
  static const Duration _cameraUpdateInterval =
      Duration(seconds: 5); // Camera update every 5 seconds
  static const Duration _etaUpdateInterval =
      Duration(seconds: 10); // ETA update every 10 seconds
  static const double _minDistanceForCameraUpdate =
      20.0; // 20 meters minimum for camera update

  // Default position (Dhaka, Bangladesh) in case location fails
  static const LatLng defaultPosition = LatLng(23.8103, 90.4125);

  // Google Maps Directions API client
  late directions.GoogleMapsDirections _directions;

  // Helper function to format address display
  String formatAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address not provided';
    }

    // Check if it's coordinates format
    if (address.startsWith('Lat:') && address.contains('Lng:')) {
      return 'Location coordinates available';
    }

    return address;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeDirections();
    _loadCustomIcons();

    // Get request data from arguments first
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      requestData.value = args['request'];
      showSlidePanel.value = args['fromActivityTab'] == true || 
          args['request']?['status'] == 'in_transit' ||
          args['request']?['status'] == 'accepted' ||
          args['request']?['status'] == 'pickup' ||
          args['request']?['status'] == 'to_destination';
      serviceRate.value = args['request']?['totalAmount']?.toInt() ??
          args['serviceRate'] ??
          2500;
      debugPrint(
          'AcceptMaps: Received request data with ID: ${args['request']?['id']}');
      debugPrint(
          'AcceptMaps: Received serviceRate from arguments: ${serviceRate.value}');
      debugPrint(
          'AcceptMaps: Request status: ${args['request']?['status']}');
      debugPrint(
          'AcceptMaps: showSlidePanel set to: ${showSlidePanel.value}');
      if (args['request']?['pickupLat'] != null &&
          args['request']?['pickupLng'] != null) {
        userPosition.value =
            LatLng(args['request']['pickupLat'], args['request']['pickupLng']);
      }
    }

    // Get current location and then calculate ETA
    _getCurrentLocation();
  }

  void _initializeDirections() {
    // Initialize Google Maps Directions API
    // Note: You'll need to add your API key here
    _directions = directions.GoogleMapsDirections(
        apiKey: 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o');
  }

  Future<void> _loadCustomIcons() async {
    try {
      debugPrint('Loading custom icons for accept maps...');
      partnerLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/markers/ambulance.png',
      );
      userLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(50, 50)),
        'assets/markers/user.png',
      );
      debugPrint('Accept maps custom icons loaded successfully');
    } catch (e) {
      debugPrint('Failed to load accept maps custom icons: $e');
      partnerLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      userLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSuccessDialog(
              'Permission Denied', 'Location permission is required');
          isLoadingLocation.value = false;
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      partnerPosition.value = LatLng(position.latitude, position.longitude);

      // Update markers
      _updateMarkers();
      // Create route polyline if user position is available
      _createRoutePolyline();
      // Calculate ETA if both positions are available
      if (userPosition.value != null) {
        calculateETA();
      }

      isLoadingLocation.value = false;
    } catch (e) {
      partnerPosition.value = defaultPosition;
      _updateMarkers();
      // Try to calculate ETA even with default position if user position exists
      if (userPosition.value != null) {
        calculateETA();
      }
      isLoadingLocation.value = false;
    }
  }

  void _updateMarkers() {
    markers.clear();

    // Add partner location marker
    if (partnerPosition.value != null) {
      markers.add(
        Marker(
          markerId: MarkerId('partner_location'),
          position: partnerPosition.value!,
          infoWindow: InfoWindow(title: 'Your Ambulance'),
          icon: partnerLocationIcon,
        ),
      );
    }

    // Add user location marker
    if (userPosition.value != null) {
      markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: userPosition.value!,
          infoWindow: InfoWindow(title: 'Patient Location'),
          icon: userLocationIcon,
        ),
      );
    }
  }

  Future<void> _createRoutePolyline() async {
    if (partnerPosition.value != null && userPosition.value != null) {
      try {
        debugPrint(
            'Creating route polyline from ${partnerPosition.value} to ${userPosition.value}');

        final origin =
            '${partnerPosition.value!.latitude},${partnerPosition.value!.longitude}';
        final destination =
            '${userPosition.value!.latitude},${userPosition.value!.longitude}';

        final result = await _directions.directions(
          origin,
          destination,
          travelMode: directions.TravelMode.driving,
        );

        if (result.status == 'OK' && result.routes.isNotEmpty) {
          final route = result.routes.first;
          final polylinePoints = <LatLng>[];

          // Decode the polyline points
          for (var leg in route.legs) {
            for (var step in leg.steps) {
              final points = _decodePolyline(step.polyline.points);
              polylinePoints.addAll(points);
            }
          }

          // Create polyline
          final polyline = Polyline(
            polylineId: PolylineId('route'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          );

          polylines.clear();
          polylines.add(polyline);

          debugPrint(
              'Route polyline created with ${polylinePoints.length} points');
        } else {
          debugPrint('Failed to get directions: ${result.status}');
        }
      } catch (e) {
        debugPrint('Error creating route polyline: $e');
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;

      points.add(LatLng(latitude, longitude));
    }

    return points;
  }

  void onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }

    // If we have both positions, show both on map
    if (partnerPosition.value != null && userPosition.value != null) {
      _fitBounds();
    } else if (partnerPosition.value != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: partnerPosition.value!, zoom: 14),
        ),
      );
    }
  }

  Future<void> _fitBounds() async {
    if (partnerPosition.value != null &&
        userPosition.value != null &&
        _controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          partnerPosition.value!.latitude < userPosition.value!.latitude
              ? partnerPosition.value!.latitude
              : userPosition.value!.latitude,
          partnerPosition.value!.longitude < userPosition.value!.longitude
              ? partnerPosition.value!.longitude
              : userPosition.value!.longitude,
        ),
        northeast: LatLng(
          partnerPosition.value!.latitude > userPosition.value!.latitude
              ? partnerPosition.value!.latitude
              : userPosition.value!.latitude,
          partnerPosition.value!.longitude > userPosition.value!.longitude
              ? partnerPosition.value!.longitude
              : userPosition.value!.longitude,
        ),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
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

  // ETA Calculation
  Future<void> calculateETA() async {
    debugPrint('AcceptMaps: Starting ETA calculation...');
    if (partnerPosition.value == null || userPosition.value == null) {
      estimatedTime.value = 'অনুমানিক সময়';
      debugPrint('AcceptMaps: Cannot calculate ETA - missing positions');
      return;
    }

    try {
      isCalculatingETA.value = true;
      debugPrint(
          'AcceptMaps: Calculating ETA from ${partnerPosition.value} to ${userPosition.value}');

      final origin =
          '${partnerPosition.value!.latitude},${partnerPosition.value!.longitude}';
      final destination =
          '${userPosition.value!.latitude},${userPosition.value!.longitude}';

      final result = await _directions.directions(
        origin,
        destination,
        travelMode: directions.TravelMode.driving,
        units: directions.Unit.metric,
      );

      if (result.status == 'OK' && result.routes.isNotEmpty) {
        final route = result.routes.first;
        final leg = route.legs.first;

        // Get duration in minutes
        final durationInMinutes = (leg.duration.value / 60).round();
        final distanceInKm = (leg.distance.value / 1000);

        estimatedDistance.value = distanceInKm;
        estimatedTime.value = _formatDuration(durationInMinutes);

        debugPrint(
            'AcceptMaps: ETA calculated successfully - ${estimatedTime.value}, Distance: ${distanceInKm.toStringAsFixed(1)} km');
      } else {
        estimatedTime.value = 'গণনা করা যায়নি';
        debugPrint('AcceptMaps: ETA calculation failed: ${result.status}');
      }
    } catch (e) {
      estimatedTime.value = 'সময় গণনায় ত্রুটি';
      debugPrint('AcceptMaps: ETA calculation error: $e');
    } finally {
      isCalculatingETA.value = false;
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 1) {
      return '১ মিনিটের কম';
    } else if (minutes < 60) {
      return '$minutes মিনিট';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ঘণ্টা${hours > 1 ? '' : ''}';
      } else {
        return '$hours ঘণ্টা${hours > 1 ? '' : ''} $remainingMinutes মিনিট';
      }
    }
  }

  Future<void> completeRide({required double fareAmount}) async {
    try {
      if (requestData.value != null) {
        final requestId = requestData.value!['id'];
        final userId = requestData.value!['userId'];
        debugPrint(
            'AcceptMaps: Completing ride with request ID: $requestId and fare: $fareAmount');

        // Update order status and fare
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(requestId)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'fareAmount': fareAmount,
          'finalFare': fareAmount,
        });

        // Send notification to user with fare amount
        if (userId != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          final fcmToken = userDoc.data()?['fcmToken'];
          if (fcmToken != null) {
            await NotificationService.sendFCMNotification(
              token: fcmToken,
              title: 'রাইড সম্পন্ন',
              body: 'আপনার রাইড সম্পন্ন হয়েছে। মোট খরচ: ৳${fareAmount.toStringAsFixed(0)}',
              data: {
                'type': 'ride_completed',
                'orderId': requestId,
                'fareAmount': fareAmount.toString(),
              },
            );
            debugPrint('✅ Completion notification sent with fare: ৳$fareAmount');
          }
        }

        // Update partner status back to available
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('partners')
              .doc(user.uid)
              .update({
            'isOnline': true,
            'currentOrderId': null,
            'status': 'available',
          });
          debugPrint('Partner status updated to available');
        }

        // Stop live tracking if active
        if (isLiveTracking.value) {
          stopLiveTracking();
        }

        Get.back(); // Go back to home partner page
        _showSuccessDialog('রাইড সম্পন্ন',
            'রাইড সফলভাবে সম্পন্ন হয়েছে!\n\nমোট খরচ: ৳${fareAmount.toStringAsFixed(0)}');
      }
    } catch (e) {
      _showSuccessDialog('Error', 'Failed to complete ride: $e');
    }
  }

  // Live tracking functions
  void startLiveTracking() async {
    if (isLiveTracking.value) return;

    isLiveTracking.value = true;
    debugPrint('Starting live location tracking...');

    // Update order status to in_transit
    if (requestData.value != null) {
      final requestId = requestData.value!['id'];
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(requestId)
            .update({
          'status': 'in_transit',
        });
        debugPrint('Updated order status to in_transit');
        // Update local data
        requestData.value!['status'] = 'in_transit';
        requestData.refresh();
      } catch (e) {
        debugPrint('Failed to update order status: $e');
      }
    }

    // Start listening to position changes with optimized timing
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      final newPosition = LatLng(position.latitude, position.longitude);
      partnerPosition.value = newPosition;

      // Update marker position immediately for smooth UI
      _updatePartnerMarker();

      // Debounced Firestore update (every 3 seconds)
      _scheduleFirestoreUpdate(position);

      // Conditional camera update (every 5 seconds and minimum distance)
      _scheduleCameraUpdate(position);

      // Periodic ETA update (every 10 seconds)
      _scheduleETAUpdate();

      debugPrint(
          'Live tracking: Updated position to ${position.latitude}, ${position.longitude}');
    });

    _showSuccessDialog('Live Tracking Started',
        'Your location is now being tracked in real-time');
  }

  void _scheduleFirestoreUpdate(Position position) {
    // Check if position has changed significantly (at least 10 meters)
    if (_lastFirestorePosition != null &&
        _calculateDistance(_lastFirestorePosition!, position) < 10) {
      return; // Skip update if not moved enough
    }

    // Cancel existing timer
    _firestoreUpdateTimer?.cancel();

    // Schedule new update
    _firestoreUpdateTimer = Timer(_firestoreUpdateInterval, () async {
      if (requestData.value != null && isLiveTracking.value) {
        final requestId = requestData.value!['id'];
        try {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(requestId)
              .update({
            'partnerLiveLocation': {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': Timestamp.now(),
            },
          });
          _lastFirestorePosition = position;
          debugPrint('Firestore location updated');
        } catch (e) {
          debugPrint('Failed to update live location: $e');
          // Retry after delay if failed
          Future.delayed(
              Duration(seconds: 2), () => _scheduleFirestoreUpdate(position));
        }
      }
    });
  }

  void _scheduleCameraUpdate(Position position) {
    // Only update camera if moved significant distance or enough time passed
    final shouldUpdateCamera = _lastCameraPosition == null ||
        _calculateDistance(_lastCameraPosition!, position) >=
            _minDistanceForCameraUpdate;

    if (shouldUpdateCamera) {
      // Cancel existing timer
      _cameraUpdateTimer?.cancel();

      // Schedule camera update
      _cameraUpdateTimer = Timer(_cameraUpdateInterval, () {
        if (isLiveTracking.value) {
          _animateCameraToPosition(
              LatLng(position.latitude, position.longitude));
          _lastCameraPosition = position;
        }
      });
    }
  }

  double _calculateDistance(Position pos1, Position pos2) {
    const double earthRadius = 6371000; // meters
    final double dLat = (pos2.latitude - pos1.latitude) * (pi / 180);
    final double dLng = (pos2.longitude - pos1.longitude) * (pi / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(pos1.latitude * (pi / 180)) *
            cos(pos2.latitude * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _scheduleETAUpdate() {
    // Cancel existing timer
    _etaUpdateTimer?.cancel();

    // Schedule ETA update
    _etaUpdateTimer = Timer(_etaUpdateInterval, () {
      if (isLiveTracking.value) {
        calculateETA();
      }
    });
  }

  void stopLiveTracking() {
    if (!isLiveTracking.value) return;

    isLiveTracking.value = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;

    // Cancel any pending timers
    _firestoreUpdateTimer?.cancel();
    _firestoreUpdateTimer = null;
    _cameraUpdateTimer?.cancel();
    _cameraUpdateTimer = null;
    _etaUpdateTimer?.cancel();
    _etaUpdateTimer = null;

    debugPrint('Stopped live location tracking');
  }

  void _animateCameraToPosition(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 16.0, // Appropriate zoom level for following
        ),
      ),
    );
  }

  Future<void> _animateCameraToShowRoute() async {
    if (partnerPosition.value != null && userPosition.value != null) {
      try {
        final GoogleMapController controller = await _controller.future;
        
        // Calculate bounds to show both partner and destination
        final double southWestLat = min(
          partnerPosition.value!.latitude,
          userPosition.value!.latitude,
        );
        final double southWestLng = min(
          partnerPosition.value!.longitude,
          userPosition.value!.longitude,
        );
        final double northEastLat = max(
          partnerPosition.value!.latitude,
          userPosition.value!.latitude,
        );
        final double northEastLng = max(
          partnerPosition.value!.longitude,
          userPosition.value!.longitude,
        );

        final LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(southWestLat, southWestLng),
          northeast: LatLng(northEastLat, northEastLng),
        );

        // Animate camera to show the complete route
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100), // 100 pixels padding
        );
        
        debugPrint('✅ Camera animated to show destination route');
      } catch (e) {
        debugPrint('❌ Error animating camera to route: $e');
      }
    }
  }

  void _updatePartnerMarker() {
    if (partnerPosition.value != null) {
      // Create a new set with updated markers to trigger reactivity
      final updatedMarkers = Set<Marker>.from(markers);

      // Remove existing partner marker
      updatedMarkers
          .removeWhere((marker) => marker.markerId.value == 'partner_location');

      // Add updated partner marker
      updatedMarkers.add(
        Marker(
          markerId: MarkerId('partner_location'),
          position: partnerPosition.value!,
          infoWindow: InfoWindow(title: 'Your Ambulance (Live)'),
          icon: partnerLocationIcon,
        ),
      );

      // Reassign to trigger reactivity
      markers.assignAll(updatedMarkers);
    }
  }

  Future<void> cancelRide() async {
    try {
      if (requestData.value != null) {
        final requestId = requestData.value!['id'];
        debugPrint('AcceptMaps: Cancelling ride with request ID: $requestId');

        // Stop live tracking if active
        if (isLiveTracking.value) {
          stopLiveTracking();
        }

        await FirebaseFirestore.instance
            .collection('orders')
            .doc(requestId)
            .update({
          'status': 'cancelled',
          'cancelledAt': Timestamp.now(),
        });

        Get.back(); // Go back to home partner page
        _showSuccessDialog(
            'Ride Cancelled', 'The ride has been cancelled successfully');
      }
    } catch (e) {
      _showSuccessDialog('Error', 'Failed to cancel ride: $e');
    }
  }

  void _showSuccessDialog(String title, String message, {String? orderId}) {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            lottie.Lottie.asset('assets/success.json', width: 130, height: 130),
            SizedBox(height: 16),
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(message),
            if (orderId != null) Text('Order ID: $orderId'),
          ],
        ),
      ),
    );
    // Auto close after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Get.back();
    });
  }

  // Navigate back
  void goBack() {
    Get.back();
  }

  Future<void> updateOrderStatus(String status) async {
    if (requestData.value != null) {
      final requestId = requestData.value!['id'];
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(requestId)
            .update({'status': status});
        debugPrint('Updated order status to $status');
        // Update local data
        requestData.value!['status'] = status;
        requestData.refresh();
      } catch (e) {
        debugPrint('Failed to update order status: $e');
      }
    }
  }

  Future<void> generateAndSendPickupOTP() async {
    if (requestData.value == null) return;

    final requestId = requestData.value!['id'];
    final userId = requestData.value!['userId'];

    try {
      // Generate 4-digit OTP
      final otp = (1000 + Random().nextInt(9000)).toString();
      debugPrint('Generated OTP: $otp for order: $requestId');

      // Store OTP in order document
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .update({
        'pickupOTP': otp,
        'otpGeneratedAt': Timestamp.now(),
      });

      // Update local data with the generated OTP
      requestData.value!['pickupOTP'] = otp;
      requestData.value!['otpGeneratedAt'] = Timestamp.now();
      requestData.refresh();

      debugPrint('✅ OTP stored in Firestore and local data updated');

      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Send notification with OTP
        final success = await NotificationService.sendFCMNotification(
          token: fcmToken,
          title: 'Pickup OTP',
          body: 'Your ambulance has arrived. OTP for pickup confirmation: $otp',
          data: {
            'type': 'pickup_otp',
            'orderId': requestId,
            'otp': otp,
          },
        );

        if (success) {
          debugPrint('✅ Pickup OTP notification sent successfully');
        } else {
          debugPrint('❌ Failed to send pickup OTP notification');
        }
      } else {
        debugPrint('⚠️ User FCM token not found, cannot send OTP notification');
      }
    } catch (e) {
      debugPrint('❌ Error generating/sending pickup OTP: $e');
    }
  }

  Future<void> generateAndSendDestinationOTP() async {
    if (requestData.value == null) return;

    final requestId = requestData.value!['id'];
    final userId = requestData.value!['userId'];

    try {
      // Generate 4-digit OTP
      final otp = (1000 + Random().nextInt(9000)).toString();
      debugPrint('Generated destination OTP: $otp for order: $requestId');

      // Store OTP in order document
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .update({
        'destinationOTP': otp,
        'destinationOTPGeneratedAt': Timestamp.now(),
      });

      // Update local data with the generated OTP
      requestData.value!['destinationOTP'] = otp;
      requestData.value!['destinationOTPGeneratedAt'] = Timestamp.now();
      requestData.refresh();

      debugPrint('✅ Destination OTP stored in Firestore and local data updated');

      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Send notification with OTP
        final success = await NotificationService.sendFCMNotification(
          token: fcmToken,
          title: 'Destination OTP',
          body: 'Your ambulance has started heading to destination. OTP for arrival confirmation: $otp',
          data: {
            'type': 'destination_otp',
            'orderId': requestId,
            'otp': otp,
          },
        );

        if (success) {
          debugPrint('✅ Destination OTP notification sent successfully');
        } else {
          debugPrint('❌ Failed to send destination OTP notification');
        }
      } else {
        debugPrint('⚠️ User FCM token not found, cannot send destination OTP notification');
      }
    } catch (e) {
      debugPrint('❌ Error generating/sending destination OTP: $e');
    }
  }

  Future<bool> confirmPickupOTP(String enteredOTP) async {
    if (requestData.value == null) return false;

    final requestId = requestData.value!['id'];

    try {
      // Fetch the latest order data from Firestore to get the stored OTP
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .get();

      if (!orderDoc.exists) {
        debugPrint('❌ Order document not found');
        return false;
      }

      final orderData = orderDoc.data()!;
      final storedOTP = orderData['pickupOTP'];

      if (storedOTP == null) {
        debugPrint('❌ No OTP found in order document');
        return false;
      }

      debugPrint('Stored OTP: $storedOTP, Entered OTP: $enteredOTP');

      if (enteredOTP == storedOTP.toString()) {
        // Update order status to pickup (patient picked up)
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(requestId)
            .update({
          'status': 'pickup',
          'pickupConfirmedAt': Timestamp.now(),
        });

        // Update local data
        requestData.value!['status'] = 'pickup';
        requestData.value!['pickupConfirmedAt'] = Timestamp.now();
        requestData.refresh();

        debugPrint('✅ Pickup OTP confirmed, status updated to pickup');
        return true;
      } else {
        debugPrint('❌ Invalid OTP entered - does not match stored OTP');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error confirming pickup OTP: $e');
      return false;
    }
  }

  Future<void> goToDestination() async {
    if (requestData.value == null) return;

    final requestId = requestData.value!['id'];

    try {
      // Update order status to indicate going to destination
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .update({
        'status': 'to_destination',
        'destinationStartedAt': Timestamp.now(),
      });

      // Update local data
      requestData.value!['status'] = 'to_destination';
      requestData.refresh();

      // Generate and send destination OTP
      await generateAndSendDestinationOTP();

      // Update destination location for routing
      if (requestData.value!['destinationLat'] != null &&
          requestData.value!['destinationLng'] != null) {
        final destinationLatLng = LatLng(
          requestData.value!['destinationLat'],
          requestData.value!['destinationLng'],
        );

        // Update user position to destination for new polyline
        userPosition.value = destinationLatLng;

        // Clear existing polylines and create new route to destination
        polylines.clear();
        await _createRouteToDestination();

        // Update markers to show destination
        _updateDestinationMarker();

        // Animate camera to show both current location and destination
        await _animateCameraToShowRoute();

        debugPrint('✅ Going to destination, polyline updated');
      }
    } catch (e) {
      debugPrint('❌ Error going to destination: $e');
    }
  }

  Future<void> _createRouteToDestination() async {
    if (partnerPosition.value != null && userPosition.value != null) {
      try {
        debugPrint(
            'Creating route polyline to destination from ${partnerPosition.value} to ${userPosition.value}');

        final origin =
            '${partnerPosition.value!.latitude},${partnerPosition.value!.longitude}';
        final destination =
            '${userPosition.value!.latitude},${userPosition.value!.longitude}';

        final result = await _directions.directions(
          origin,
          destination,
          travelMode: directions.TravelMode.driving,
          units: directions.Unit.metric,
        );

        if (result.status == 'OK' && result.routes.isNotEmpty) {
          final route = result.routes.first;
          final leg = route.legs.first;
          final polylinePoints = <LatLng>[];

          // Decode the polyline points
          for (var legItem in route.legs) {
            for (var step in legItem.steps) {
              final points = _decodePolyline(step.polyline.points);
              polylinePoints.addAll(points);
            }
          }

          // Update ETA and distance to destination
          final duration = leg.duration.text;
          final distance = leg.distance.value.toDouble();
          estimatedTime.value = duration;
          estimatedDistance.value = distance / 1000; // Convert to km

          // Create polyline to destination
          final polyline = Polyline(
            polylineId: PolylineId('destination_route'),
            points: polylinePoints,
            color: Colors.green, // Different color for destination route
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          );

          polylines.add(polyline);
          debugPrint('✅ Destination route polyline created - ETA: $duration, Distance: ${estimatedDistance.value.toStringAsFixed(1)} km');
        }
      } catch (e) {
        debugPrint('❌ Error creating destination route: $e');
      }
    }
  }

  void _updateDestinationMarker() {
    if (userPosition.value != null) {
      // Create a new set with updated markers
      final updatedMarkers = Set<Marker>.from(markers);

      // Remove existing user marker
      updatedMarkers
          .removeWhere((marker) => marker.markerId.value == 'user_location');

      // Add destination marker
      updatedMarkers.add(
        Marker(
          markerId: MarkerId('destination_location'),
          position: userPosition.value!,
          infoWindow: InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Reassign to trigger reactivity
      markers.assignAll(updatedMarkers);
    }
  }
}
