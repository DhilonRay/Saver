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

class UserTrackingController extends GetxController {
  final Completer<GoogleMapController> _controller = Completer();

  // Custom marker icons
  BitmapDescriptor userLocationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  BitmapDescriptor ambulanceLocationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

  // Reactive variables
  var userPosition = Rx<LatLng?>(null);
  var ambulancePosition = Rx<LatLng?>(null);
  var ambulanceLocationTrail = <LatLng>[].obs;
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isLoadingLocation = true.obs;
  var orderData = Rx<Map<String, dynamic>?>(null);
  var orderId = Rx<String?>('null');

  // Route polyline variables
  var routePoints = <LatLng>[].obs;

  // ETA variables
  var estimatedTime = Rx<String>('অনুমানিক সময়');
  var estimatedDistance = Rx<double>(0.0);
  var isCalculatingETA = false.obs;

  // Live tracking variables
  var isLiveTracking = false.obs;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  // Timing and performance optimization
  Timer? _etaUpdateTimer;
  static const Duration _etaUpdateInterval = Duration(seconds: 10);

  // Default position (Dhaka, Bangladesh)
  static const LatLng defaultPosition = LatLng(23.8103, 90.4125);

  // Google Maps Directions API client
  late directions.GoogleMapsDirections _directions;

  void _initializeDirections() {
    _directions = directions.GoogleMapsDirections(
        apiKey: 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o');
  }

  @override
  void onInit() {
    super.onInit();
    _initializeDirections();
    _loadCustomIcons();
    _getCurrentLocation();

    // Get order data from arguments
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      orderData.value = args;
      orderId.value = args['id'];
      debugPrint('UserTracking: Received order data with ID: ${args['id']}');

      // Process existing live location data immediately
      _processExistingOrderData(args);

      // Start listening for order updates
      listenForOrderUpdates(args['id']);

      // Force initial data calculation after a short delay to ensure positions are loaded
      Future.delayed(const Duration(milliseconds: 1000), () {
        _forceInitialDataCalculation();
      });
    } else {
      debugPrint('UserTracking: No order data received in arguments');
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Force refresh all data when page becomes ready
    _refreshAllTrackingData();
  }

  void _refreshAllTrackingData() {
    debugPrint('UserTracking: Refreshing all tracking data');

    // Update markers and polylines
    _updateMarkers();
    _updatePolylines();

    // Calculate ETA if positions are available
    if (ambulancePosition.value != null && userPosition.value != null) {
      calculateETA();
    }

    // Schedule periodic updates
    _scheduleETAUpdate();
  }

  void _processExistingOrderData(Map<String, dynamic> orderData) {
    debugPrint('UserTracking: Processing existing order data');

    final status = orderData['orderStatus'] ?? orderData['status'];

    // Process live location if available
    if (status != 'completed') {
      final liveLocation = orderData['partnerLiveLocation'] as Map<String, dynamic>?;
      if (liveLocation != null) {
        final lat = liveLocation['latitude'] as double?;
        final lng = liveLocation['longitude'] as double?;

        if (lat != null && lng != null) {
          final location = LatLng(lat, lng);
          ambulancePosition.value = location;

          // Add initial point to trail
          if (ambulanceLocationTrail.isEmpty) {
            ambulanceLocationTrail.add(location);
          }

          debugPrint('UserTracking: Processed existing ambulance location: $location');
        }
      } else if (status == 'accepted') {
        // If no live location but status is accepted, check for partnerLocation
        final partnerLocation = orderData['partnerLocation'] as Map<String, dynamic>?;
        if (partnerLocation != null) {
          final lat = partnerLocation['latitude'] as double?;
          final lng = partnerLocation['longitude'] as double?;

          if (lat != null && lng != null) {
            final location = LatLng(lat, lng);
            ambulancePosition.value = location;

            // Add initial point to trail
            if (ambulanceLocationTrail.isEmpty) {
              ambulanceLocationTrail.add(location);
            }

            debugPrint('UserTracking: Processed partner location for accepted order: $location');
          }
        }
      }
    }
  }

  void _forceInitialDataCalculation() {
    debugPrint('UserTracking: Forcing initial data calculation');

    // Update markers and polylines first
    _updateMarkers();
    _updatePolylines();

    // Calculate ETA if we have both positions
    if (ambulancePosition.value != null && userPosition.value != null) {
      debugPrint('UserTracking: Calculating initial ETA');
      calculateETA();
    } else {
      debugPrint('UserTracking: Missing positions for ETA calculation - Ambulance: ${ambulancePosition.value}, User: ${userPosition.value}');
    }

    // Start periodic ETA updates
    _scheduleETAUpdate();
  }

  Future<void> _loadCustomIcons() async {
    try {
      debugPrint('Loading custom icons for user tracking...');

      // User location icon (red)
      
      userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

      // Ambulance location icon (blue)
      ambulanceLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/markers/ambulance.png',
      );

      debugPrint('User tracking custom icons loaded successfully');
    } catch (e) {
      debugPrint('Failed to load user tracking custom icons: $e');
      ambulanceLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorDialog('Permission Denied', 'Location permission is required for tracking');
          isLoadingLocation.value = false;
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      userPosition.value = LatLng(position.latitude, position.longitude);

      // Update markers
      _updateMarkers();

      isLoadingLocation.value = false;
    } catch (e) {
      userPosition.value = defaultPosition;
      _updateMarkers();
      isLoadingLocation.value = false;
      debugPrint('Error getting user location: $e');
    }
  }

  void _updateMarkers() {
    markers.clear();

    // Add user location marker
    if (userPosition.value != null) {
      markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: userPosition.value!,
          infoWindow: InfoWindow(title: 'আপনার অবস্থান'),
          icon: userLocationIcon,
        ),
      );
    }

    // Add ambulance location marker
    if (ambulancePosition.value != null) {
      markers.add(
        Marker(
          markerId: MarkerId('ambulance_location'),
          position: ambulancePosition.value!,
          infoWindow: InfoWindow(title: '🚑 অ্যাম্বুলেন্স (লাইভ)'),
          icon: ambulanceLocationIcon,
        ),
      );
    }
  }

  void listenForOrderUpdates(String orderId) {
    debugPrint('UserTracking: Starting to listen for order updates: $orderId');

    // Cancel any existing subscription
    _orderSubscription?.cancel();

    // Listen for order updates
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        final status = data?['orderStatus'] ?? data?['status'];

        debugPrint('UserTracking: Order status update: $status');

        // Handle status changes
        if (status == 'completed') {
          // Clear ambulance location and trail when service is completed
          ambulancePosition.value = null;
          ambulanceLocationTrail.clear();
          routePoints.clear();
          _updateMarkers();
          _updatePolylines();
          debugPrint('UserTracking: Service completed - cleared ambulance location');
        }

        // Handle live location updates (only if not completed)
        if (status != 'completed') {
          final liveLocation = data?['partnerLiveLocation'] as Map<String, dynamic>?;
          if (liveLocation != null) {
            final lat = liveLocation['latitude'] as double?;
            final lng = liveLocation['longitude'] as double?;

            if (lat != null && lng != null) {
              final newLocation = LatLng(lat, lng);

              // Update ambulance live location
              ambulancePosition.value = newLocation;

              // Add to location trail
              if (ambulanceLocationTrail.isEmpty || ambulanceLocationTrail.last != newLocation) {
                ambulanceLocationTrail.add(newLocation);

                // Keep only last 50 points to avoid performance issues
                if (ambulanceLocationTrail.length > 50) {
                  ambulanceLocationTrail.removeAt(0);
                }
              }

              // Update markers and polylines
              _updateMarkers();
              _updatePolylines();

              // Calculate ETA immediately for the first time or when route is empty
              if (routePoints.isEmpty && userPosition.value != null) {
                debugPrint('UserTracking: Calculating initial ETA for route display');
                calculateETA();
              }

              // Calculate ETA periodically
              _scheduleETAUpdate();

              debugPrint('UserTracking: Ambulance location updated: $newLocation');
            }
          } else {
            // No live location data, but still update markers and polylines
            _updateMarkers();
            _updatePolylines();
          }
        }

        // Update order data (preserve the ID)
        final currentId = orderData.value?['id'] ?? orderId;
        orderData.value = {'id': currentId, ...?data};
      }
    });
  }

  void _updatePolylines() {
    polylines.clear();

    // Add ambulance trail polyline
    if (ambulanceLocationTrail.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ambulance_trail'),
          color: Colors.blue.shade600,
          width: 4,
          points: ambulanceLocationTrail,
          zIndex: 2,
        ),
      );
    }

    // Add route from ambulance to user if both positions available
    if (routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_user'),
          color: Colors.blue.shade700,
          width: 6,
          points: routePoints,
          zIndex: 1,
        ),
      );
    } else if (ambulancePosition.value != null && userPosition.value != null) {
      // Fallback to straight line if no route calculated
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_user'),
          color: Colors.blue.shade700,
          width: 6,
          points: [ambulancePosition.value!, userPosition.value!],
          zIndex: 1,
        ),
      );
    }
  }

  void onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }

    // If we have positions, show them on map
    if (userPosition.value != null || ambulancePosition.value != null) {
      _fitBounds();
    }
  }

  Future<void> _fitBounds() async {
    if (!_controller.isCompleted) return;

    final GoogleMapController controller = await _controller.future;

    List<LatLng> positions = [];
    if (userPosition.value != null) positions.add(userPosition.value!);
    if (ambulancePosition.value != null) positions.add(ambulancePosition.value!);

    // Include route points in bounds calculation
    positions.addAll(routePoints);

    if (positions.isNotEmpty) {
      if (positions.length == 1) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: positions.first, zoom: 14),
          ),
        );
      } else {
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            positions.map((p) => p.latitude).reduce(min),
            positions.map((p) => p.longitude).reduce(min),
          ),
          northeast: LatLng(
            positions.map((p) => p.latitude).reduce(max),
            positions.map((p) => p.longitude).reduce(max),
          ),
        );
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      }
    }
  }

  // ETA Calculation
  Future<void> calculateETA() async {
    if (ambulancePosition.value == null || userPosition.value == null) {
      estimatedTime.value = 'অনুমানিক সময়';
      return;
    }

    try {
      isCalculatingETA.value = true;
      debugPrint('UserTracking: Calculating ETA from ambulance to user');

      final origin = '${ambulancePosition.value!.latitude},${ambulancePosition.value!.longitude}';
      final destination = '${userPosition.value!.latitude},${userPosition.value!.longitude}';

      final result = await _directions.directions(
        origin,
        destination,
        travelMode: directions.TravelMode.driving,
        units: directions.Unit.metric,
      );

      if (result.status == 'OK' && result.routes.isNotEmpty) {
        final route = result.routes.first;
        final leg = route.legs.first;

        // Extract and decode route polyline points
        final encodedPolyline = route.overviewPolyline.points;
        routePoints.value = _decodePolyline(encodedPolyline);

        // Get duration in minutes
        final durationInMinutes = (leg.duration.value / 60).round();
        final distanceInKm = (leg.distance.value / 1000);

        estimatedDistance.value = distanceInKm;
        estimatedTime.value = _formatDuration(durationInMinutes);

        // Update polylines with new route
        _updatePolylines();

        // Fit bounds to show the entire route
        _fitBounds();

        debugPrint('UserTracking: ETA calculated - ${estimatedTime.value}, Distance: ${distanceInKm.toStringAsFixed(1)} km');
      } else {
        estimatedTime.value = 'গণনা করা যায়নি';
        debugPrint('UserTracking: ETA calculation failed: ${result.status}');
      }
    } catch (e) {
      estimatedTime.value = 'সময় গণনায় ত্রুটি';
      debugPrint('UserTracking: ETA calculation error: $e');
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
        return '$hours ঘণ্টা';
      } else {
        return '$hours ঘণ্টা $remainingMinutes মিনিট';
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
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

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
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

  void startLiveTracking() {
    isLiveTracking.value = true;
    debugPrint('UserTracking: Started live tracking');
  }

  void stopLiveTracking() {
    isLiveTracking.value = false;
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _etaUpdateTimer?.cancel();
    _etaUpdateTimer = null;
    debugPrint('UserTracking: Stopped live tracking');
  }

  void _showErrorDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void zoomIn() async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.zoomIn());
    }
  }

  void zoomOut() async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.zoomOut());
    }
  }

  void goBack() {
    stopLiveTracking();
    Get.back();
  }

  @override
  void onClose() {
    stopLiveTracking();
    super.onClose();
  }
}