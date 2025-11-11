import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/directions.dart' as directions;
import 'package:lottie/lottie.dart' as lottie hide Marker;

class AcceptMapsController extends GetxController {
  final Completer<GoogleMapController> _controller = Completer();

  // Custom marker icons
  BitmapDescriptor partnerLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  // Reactive variables
  var partnerPosition = Rx<LatLng?>(null);
  var userPosition = Rx<LatLng?>(null);
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isLoadingLocation = true.obs;
  var requestData = Rx<Map<String, dynamic>?>(null);

  // Live tracking variables
  var isLiveTracking = false.obs;
  StreamSubscription<Position>? _positionSubscription;

  // Timing and performance optimization
  Timer? _firestoreUpdateTimer;
  Timer? _cameraUpdateTimer;
  Position? _lastFirestorePosition;
  Position? _lastCameraPosition;
  static const Duration _firestoreUpdateInterval = Duration(seconds: 3); // Update every 3 seconds
  static const Duration _cameraUpdateInterval = Duration(seconds: 5); // Camera update every 5 seconds
  static const double _minDistanceForCameraUpdate = 20.0; // 20 meters minimum for camera update

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
    _getCurrentLocation();

    // Get request data from arguments
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      requestData.value = args;
      debugPrint('AcceptMaps: Received request data with ID: ${args['id']}');
      if (args['pickupLat'] != null && args['pickupLng'] != null) {
        userPosition.value = LatLng(args['pickupLat'], args['pickupLng']);
        // Create route polyline after setting user position
        _createRoutePolyline();
      }
    } else {
      debugPrint('AcceptMaps: No request data received in arguments');
    }
  }

  void _initializeDirections() {
    // Initialize Google Maps Directions API
    // Note: You'll need to add your API key here
    _directions = directions.GoogleMapsDirections(apiKey: 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o');
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
      partnerLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSuccessDialog('Permission Denied', 'Location permission is required');
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

      isLoadingLocation.value = false;
    } catch (e) {
      partnerPosition.value = defaultPosition;
      _updateMarkers();
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
        debugPrint('Creating route polyline from ${partnerPosition.value} to ${userPosition.value}');

        final origin = '${partnerPosition.value!.latitude},${partnerPosition.value!.longitude}';
        final destination = '${userPosition.value!.latitude},${userPosition.value!.longitude}';

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

          debugPrint('Route polyline created with ${polylinePoints.length} points');
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
    if (partnerPosition.value != null && userPosition.value != null && _controller.isCompleted) {
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

  Future<void> completeRide() async {
    try {
      if (requestData.value != null) {
        final requestId = requestData.value!['id'];
        debugPrint('AcceptMaps: Completing ride with request ID: $requestId');

        await FirebaseFirestore.instance
            .collection('orders')
            .doc(requestId)
            .update({
          'status': 'completed',
          'completedAt': Timestamp.now(),
        });

        Get.back(); // Go back to home partner page
        _showSuccessDialog('Success', 'Ride completed successfully');
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

      debugPrint('Live tracking: Updated position to ${position.latitude}, ${position.longitude}');
    });

    _showSuccessDialog('Live Tracking Started', 'Your location is now being tracked in real-time');
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
          Future.delayed(Duration(seconds: 2), () => _scheduleFirestoreUpdate(position));
        }
      }
    });
  }

  void _scheduleCameraUpdate(Position position) {
    // Only update camera if moved significant distance or enough time passed
    final shouldUpdateCamera = _lastCameraPosition == null ||
        _calculateDistance(_lastCameraPosition!, position) >= _minDistanceForCameraUpdate;

    if (shouldUpdateCamera) {
      // Cancel existing timer
      _cameraUpdateTimer?.cancel();

      // Schedule camera update
      _cameraUpdateTimer = Timer(_cameraUpdateInterval, () {
        if (isLiveTracking.value) {
          _animateCameraToPosition(LatLng(position.latitude, position.longitude));
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
        cos(pos1.latitude * (pi / 180)) * cos(pos2.latitude * (pi / 180)) *
        sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
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

  void _updatePartnerMarker() {
    if (partnerPosition.value != null) {
      // Create a new set with updated markers to trigger reactivity
      final updatedMarkers = Set<Marker>.from(markers);

      // Remove existing partner marker
      updatedMarkers.removeWhere((marker) => marker.markerId.value == 'partner_location');

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
        _showSuccessDialog('Ride Cancelled', 'The ride has been cancelled successfully');
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
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
}