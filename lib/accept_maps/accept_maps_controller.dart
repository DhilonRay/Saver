import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/directions.dart' as directions;

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
      userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
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
          Get.snackbar(
            'Permission Denied',
            'Location permission is required',
            backgroundColor: Colors.orange[600],
            colorText: Colors.white,
          );
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

        final result = await _directions.directionsWithLocation(
          directions.Location(lat: partnerPosition.value!.latitude, lng: partnerPosition.value!.longitude),
          directions.Location(lat: userPosition.value!.latitude, lng: userPosition.value!.longitude),
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
        Get.snackbar(
          'Success',
          'Ride completed successfully',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete ride: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void goBack() {
    Get.back();
  }
}