import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:google_maps_webservice/directions.dart' as directions;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../about/about.dart';
import '../user_id/userid.dart';
import '../auth/log_in/login_screen.dart';
import '../chat_page/sos_chat_page.dart';
import '../partner_file/partner_orders/partners_orders_page.dart';
import '../user_order/user_order_page.dart';
import '../services/notification_service.dart';
import '../components/success_dialog.dart';
import '../user_tracking/user_tracking_page.dart';
import '../services/fares_service.dart';
import '../widgets/fares_widgets.dart';

class HomeController extends GetxController {
  final bool isNewSignup;

  HomeController({this.isNewSignup = false});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();

  // Custom marker icons
  BitmapDescriptor currentLocationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor destinationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  BitmapDescriptor personIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor ambulanceIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor hospitalIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  BitmapDescriptor selectedHospitalIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

  // Google Places API client
  late places.GoogleMapsPlaces _places;
  late directions.GoogleMapsDirections _directions;

  // Reactive variables
  var currentPosition = Rx<LatLng?>(null);
  var destinationPosition = Rx<LatLng?>(null);
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isLoadingLocation = true.obs;
  var isInitialLoading = true.obs;
  var mapError = ''.obs;

  // Partner live tracking
  var partnerLiveLocation = Rx<LatLng?>(null);
  var partnerLocationTrail = <LatLng>[].obs;
  var isTrackingPartner = false.obs;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  var currentTrackingOrderId = Rx<String?>(null);

  // Currently online ambulance providers cached as simple maps so UI can show a list
  var onlineAmbulances = <Map<String, dynamic>>[].obs;

  // Autocomplete variables
  var placeSuggestions = <Map<String, dynamic>>[].obs;
  var isLoadingSuggestions = false.obs;
  Timer? _debounceTimer;

  // Reactive query string mirroring the TextEditingController
  var destinationQuery = ''.obs;

  // Ambulance visibility control
  var showAmbulances = true.obs; // Show ambulances by default

  // User name
  var userName = 'NeoSaver'.obs;

  // Profile image
  var profileImageUrl = Rx<String?>(null);
  var isUploadingImage = false.obs;
  var uploadProgress = 0.0.obs; // Upload progress (0.0 to 1.0)

  // Maximum file size in bytes (2MB)
  static const int maxFileSizeBytes = 2 * 1024 * 1024; // 2MB

  // Partner rates cache
  var partnerRates =
      <String, Map<String, int>>{}.obs; // partnerId -> {serviceRate}

  // Search history variables
  var searchHistory = <String>[].obs;
  static const int _maxHistoryItems = 10;
  var hasStartedTyping =
      false.obs; // Track if user has started typing in current session

  // Acknowledged tracking orders (orders where user has clicked "Track" in dialog)
  var acknowledgedTrackingOrders = <String>{}.obs;
  static const String _acknowledgedOrdersKey = 'acknowledged_tracking_orders';

  // Timer for periodic location updates (10 seconds)
  Timer? _locationUpdateTimer;

  // Default position (Dhaka, Bangladesh) in case location fails
  static const LatLng defaultPosition = LatLng(23.8103, 90.4125);

  // Controllers
  final TextEditingController destinationController = TextEditingController();

  BitmapDescriptor _getDestinationIcon() {
    final query = destinationQuery.value.toLowerCase();

    // Check for ambulance-related searches
    if (query.contains('ambulance') ||
        query.contains('emergency') ||
        query.contains('emergency services')) {
      return ambulanceIcon;
    }

    // Check for hospital-related searches - use bigger icon for hospital destinations
    if (query.contains('hospital') ||
        query.contains('medical') ||
        query.contains('clinic') ||
        query.contains('health') ||
        query.contains('doctor') ||
        query.contains('nursing') ||
        query.contains('surgery') ||
        query.contains('treatment') ||
        query.contains('care') ||
        query.contains('diagnostic') ||
        query.contains('laboratory') ||
        query.contains('pharmacy')) {
      return selectedHospitalIcon; // Bigger icon for hospital destinations
    }

    // Default destination icon for all other places
    return destinationIcon;
  }

  Future<void> _addNearbyMarkers() async {
    if (currentPosition.value == null) return;

    try {
      debugPrint('🔍 Setting up real-time ambulance providers listener...');

      // Clear existing markers first
      markers.removeWhere(
          (marker) => marker.markerId.value.startsWith('ambulance_'));

      // Set up real-time listener for ambulance providers
      FirebaseFirestore.instance
          .collection('partners')
          .where('isOnline', isEqualTo: true) // Only show online partners
          .snapshots()
          .listen((partnersSnapshot) {
        debugPrint(
            '🚑 Real-time update: Found ${partnersSnapshot.docs.length} online ambulance providers');

        // Clear existing ambulance markers
        markers.removeWhere(
            (marker) => marker.markerId.value.startsWith('ambulance_'));

        // Build a simple list of online ambulances for UI (drawer quick-access)
        final List<Map<String, dynamic>> onlineList = [];

        // Only add ambulance markers if showAmbulances is true
        if (showAmbulances.value) {
          for (var doc in partnersSnapshot.docs) {
            final data = doc.data();
            final latitude = data['latitude'] as double?;
            final longitude = data['longitude'] as double?;
            final name = data['companyName'] as String? ?? 'Ambulance Provider';
            final phone = data['contact'] as String?;
            final address = data['coverageArea'] as String?;
            final ambulanceType = data['ambulanceType'] as String?;
            final isOnline = data['isOnline'] as bool? ?? false;

            // Only show online partners with valid location
            if (latitude != null && longitude != null && isOnline) {
              debugPrint(
                  '🚑 Adding online ambulance provider: $name at ($latitude, $longitude)');

              // Create a custom ambulance data object to pass to details
              final ambulanceData = {
                'id': doc.id,
                'name': name,
                'phone': phone ?? '+8801581822846',
                'address': address ?? 'Coverage area not specified',
                'ambulanceType': ambulanceType ?? 'General Ambulance',
                'latitude': latitude,
                'longitude': longitude,
                'ambulanceImageUrl': data['ambulanceImageUrl'] as String?,
                'profileImageUrl': data['profileImageUrl'] as String?,
                'isOnline': isOnline,
              };

              // Add a compact representation to the list visible in drawer (include image if present)
              onlineList.add({
                'id': doc.id,
                'name': name,
                'phone': phone ?? '+8801793399913',
                'address': address ?? 'Coverage area not specified',
                'ambulanceType': ambulanceType ?? 'General Ambulance',
                'ambulanceImageUrl': data['ambulanceImageUrl'] as String?,
                'profileImageUrl': data['profileImageUrl'] as String?,
                'latitude': latitude,
                'longitude': longitude,
                'isOnline': isOnline,
              });

              markers.add(
                Marker(
                  markerId: MarkerId('ambulance_${doc.id}'),
                  position: LatLng(latitude, longitude),
                  infoWindow: InfoWindow(
                    title: '$name (Online)',
                    snippet: '🚑 $ambulanceType • Tap for details',
                    onTap: () => _showAmbulanceProviderDetails(ambulanceData),
                  ),
                  icon: ambulanceIcon,
                  onTap: () => _showAmbulanceProviderDetails(ambulanceData),
                ),
              );
            }
          }

            // Update the reactive list so UI elements (drawer) can show it
            onlineAmbulances.assignAll(onlineList);
        }

        debugPrint('✅ Real-time ambulance providers updated successfully');
      });
    } catch (e) {
      debugPrint(
          '❌ Failed to set up real-time ambulance providers listener: $e');
    }
  }

  // Store selected place name for fallback
  String? _selectedPlaceName;

  Future<void> _loadCustomIcons() async {
    try {
      debugPrint('Loading custom PNG icons...');
      // Load PNG files (converted from SVG)
      personIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/markers/user.png',
      );
      ambulanceIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(32, 32)),
        'assets/markers/ambulance.png',
      );
      hospitalIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(32, 32)),
        'assets/markers/hospital.png',
      );
      selectedHospitalIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/markers/selectetd_hospital.png',
      );
      // Update current location icon to person
      currentLocationIcon = personIcon;

      debugPrint('Custom icons loaded successfully');
    } catch (e) {
      // If loading fails, use default icons
      debugPrint('Failed to load custom icons: $e');
      personIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      ambulanceIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      hospitalIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      selectedHospitalIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      currentLocationIcon = personIcon;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadCustomIcons();
    // Initialize Google Places API client
    _places = places.GoogleMapsPlaces(
        apiKey: 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o');
    _directions = directions.GoogleMapsDirections(
        apiKey: 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o');
    _getCurrentLocation();
    _loadUserName();
    _loadProfileImage();
    _loadAcknowledgedOrders();
    // Start periodic location updates every 10 seconds
    _startLocationUpdateTimer();

    // Show success dialog for new signups
    if (isNewSignup) {
      Future.delayed(const Duration(milliseconds: 500), () {
        SuccessDialog.show(
          title: 'Welcome to NeoSaver!',
          message:
              'Your account has been created successfully. You can now request ambulance services.',
        );
      });
    }
  }

  @override
  void onClose() {
    destinationController.dispose();
    _debounceTimer?.cancel();
    _locationUpdateTimer?.cancel(); // Cancel location update timer
    super.onClose();
  }

  /// Start periodic location updates every 10 seconds
  void _startLocationUpdateTimer() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateCurrentLocationSilently();
    });
    debugPrint('📍 Started location update timer (10 second interval)');
  }

  /// Update current location silently (without loading indicators)
  Future<void> _updateCurrentLocationSilently() async {
    try {
      // Only update if we have permission already
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPosition = LatLng(position.latitude, position.longitude);
      
      // Only update if position has changed significantly (more than 5 meters)
      if (currentPosition.value != null) {
        final distance = Geolocator.distanceBetween(
          currentPosition.value!.latitude,
          currentPosition.value!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        if (distance < 5) return; // Skip if moved less than 5 meters
      }

      currentPosition.value = newPosition;

      // Update marker
      markers.removeWhere((m) => m.markerId.value == 'currentLocation');
      markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: currentPosition.value!,
          infoWindow: InfoWindow(title: 'Your Location'),
          icon: currentLocationIcon,
        ),
      );

      debugPrint('📍 User location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Error updating user location: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          userName.value = userData?['name'] ?? user.displayName ?? 'NeoSaver';
        } else {
          userName.value = user.displayName ?? 'NeoSaver';
        }
        debugPrint('✅ Loaded user name: ${userName.value}');
      } else {
        userName.value = 'NeoSaver';
      }
    } catch (e) {
      debugPrint('❌ Error loading user name: $e');
      userName.value = _auth.currentUser?.displayName ?? 'NeoSaver';
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          profileImageUrl.value = userData?['profileImageUrl'];
        }
        debugPrint('✅ Loaded profile image URL: ${profileImageUrl.value}');
      }
    } catch (e) {
      debugPrint('❌ Error loading profile image: $e');
    }
  }

  Future<void> _loadAcknowledgedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final acknowledgedList =
          prefs.getStringList(_acknowledgedOrdersKey) ?? [];
      acknowledgedTrackingOrders.assignAll(acknowledgedList.toSet());
      debugPrint(
          '✅ Loaded acknowledged orders: ${acknowledgedTrackingOrders.length}');
    } catch (e) {
      debugPrint('❌ Error loading acknowledged orders: $e');
    }
  }

  Future<void> _saveAcknowledgedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _acknowledgedOrdersKey, acknowledgedTrackingOrders.toList());
      debugPrint(
          '✅ Saved acknowledged orders: ${acknowledgedTrackingOrders.length}');
    } catch (e) {
      debugPrint('❌ Error saving acknowledged orders: $e');
    }
  }

  void _addAcknowledgedOrder(String orderId) {
    acknowledgedTrackingOrders.add(orderId);
    _saveAcknowledgedOrders();
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      // Request location permissions
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
          infoWindow: InfoWindow(title: 'Your Location'),
          icon: currentLocationIcon,
        ),
      );

      // Add nearby markers
      _addNearbyMarkers();

      isLoadingLocation.value = false;
      // initial loading finished
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

      // Add nearby markers even with default location
      _addNearbyMarkers();

      isLoadingLocation.value = false;
      // initial loading finished (even on error)
      isInitialLoading.value = false;
    }
  }

  Future<void> setDestinationMarker() async {
    if (destinationController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a destination',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    try {
      // If we already have destination position from autocomplete, use it
      if (destinationPosition.value != null) {
        _addDestinationMarkerAndRoute();
        return;
      }

      // Check for common locations and hospital searches
      String query = destinationController.text.toLowerCase().trim();

      // Handle Khulna searches
      if (query.contains('khulna')) {
        if (query.contains('medical') ||
            query.contains('hospital') ||
            query.contains('clinic')) {
          // Search for hospitals in Khulna
          destinationController.text = 'hospitals in Khulna';
          destinationQuery.value = 'hospitals in Khulna';
        } else {
          destinationPosition.value =
              LatLng(22.8456, 89.5403); // Khulna coordinates
          _addDestinationMarkerAndRoute();
          return;
        }
      }

      // Handle Dhaka searches
      if (query.contains('dhaka')) {
        if (query.contains('medical') ||
            query.contains('hospital') ||
            query.contains('clinic')) {
          // Search for hospitals in Dhaka
          destinationController.text = 'hospitals in Dhaka';
          destinationQuery.value = 'hospitals in Dhaka';
        } else {
          destinationPosition.value =
              LatLng(23.8103, 90.4125); // Dhaka coordinates
          _addDestinationMarkerAndRoute();
          return;
        }
      }

      // For hospital searches, make the query more specific
      if (query.contains('medical') ||
          query.contains('hospital') ||
          query.contains('clinic')) {
        // Keep the query as is for Google Places to find hospitals
      }

      // Try fallback hospitals if it's a hospital search in Khulna/Dhaka
      if (_tryFallbackHospitals(query)) {
        return;
      }

      // Otherwise, use autocomplete to find the place
      places.PlacesAutocompleteResponse autoResponse =
          await _places.autocomplete(
        destinationController.text,
        language: 'en',
        components: [
          places.Component(places.Component.country, 'bd')
        ], // Restrict to Bangladesh
        types: [], // Allow all types but prioritize hospitals
      );

      if (autoResponse.isOkay && autoResponse.predictions.isNotEmpty) {
        // Get details for the first prediction
        var prediction = autoResponse.predictions.first;
        places.PlacesDetailsResponse detailResponse =
            await _places.getDetailsByPlaceId(
          prediction.placeId!,
          fields: ['name', 'formatted_address', 'geometry'],
        );

        if (detailResponse.isOkay && detailResponse.result.geometry != null) {
          destinationPosition.value = LatLng(
            detailResponse.result.geometry!.location.lat,
            detailResponse.result.geometry!.location.lng,
          );
          _addDestinationMarkerAndRoute();
        } else {
          Get.snackbar(
            'Error',
            'Could not get details for the destination',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Could not find the destination location',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to set destination: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> _addDestinationMarkerAndRoute() async {
    // Check if positions are available
    if (currentPosition.value == null || destinationPosition.value == null) {
      Get.snackbar(
        'Error',
        'Location information is not available. Please try again.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    // Clear existing destination marker
    markers.removeWhere((marker) => marker.markerId.value == 'destination');

    // Add destination marker
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destinationPosition.value!,
        infoWindow: InfoWindow(title: 'Destination'),
        icon: _getDestinationIcon(),
      ),
    );

    // Get directions from Google
    try {
      final directionsResponse = await _directions.directions(
        directions.Location(
            lat: currentPosition.value!.latitude,
            lng: currentPosition.value!.longitude),
        directions.Location(
            lat: destinationPosition.value!.latitude,
            lng: destinationPosition.value!.longitude),
        travelMode: directions.TravelMode.driving,
      );

      if (directionsResponse.isOkay && directionsResponse.routes.isNotEmpty) {
        final route = directionsResponse.routes.first;

        // Safely decode polyline
        List<LatLng> polylinePoints = [];
        try {
          // Cast to dynamic to handle potential null issues in API response
          final dynamic routeData = route;
          final dynamic overviewPolyline = routeData.overviewPolyline;
          if (overviewPolyline != null) {
            final dynamic points = overviewPolyline.points;
            if (points != null && points.isNotEmpty) {
              polylinePoints = _decodePolyline(points);
            }
          }
        } catch (e) {
          // If polyline decoding fails, continue without route line
          polylinePoints = [];
        }

        // Calculate route information safely
        String routeInfo = 'Route calculated successfully';
        try {
          // Cast to dynamic to handle potential null issues in API response
          final dynamic routeData = route;
          final dynamic legs = routeData.legs;
          if (legs != null && legs.isNotEmpty) {
            final dynamic leg = legs.first;
            String distance = 'Unknown distance';
            String duration = 'Unknown duration';

            try {
              final dynamic distanceObj = leg.distance;
              if (distanceObj != null) {
                final dynamic distanceText = distanceObj.text;
                if (distanceText != null) {
                  distance = distanceText.toString();
                }
              }
            } catch (e) {
              // distance might be null or have issues
            }

            try {
              final dynamic durationObj = leg.duration;
              if (durationObj != null) {
                final dynamic durationText = durationObj.text;
                if (durationText != null) {
                  duration = durationText.toString();
                }
              }
            } catch (e) {
              // duration might be null or have issues
            }

            routeInfo = 'Route: $distance, about $duration';
          }
        } catch (e) {
          routeInfo = 'Route calculated successfully';
        }

        // Show route information with distance and time
        SuccessDialog.show(
          title: 'Navigation Ready',
          message: routeInfo,
        );

        // Update polylines reactively. If the directions response did not
        // contain a usable polyline, fall back to a straight-line polyline
        // between the current position and the destination so the user sees
        // a visual route.
        polylines.clear();
        if (polylinePoints.isNotEmpty) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors
                  .blue.shade700, // Use a consistent blue color for routes
              width: 6,
              zIndex: 1,
              points: polylinePoints,
            ),
          );
        } else {
          // Fallback straight line route when Google didn't provide an overview_polyline
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.orange.shade700,
              width: 6,
              zIndex: 1,
              points: [currentPosition.value!, destinationPosition.value!],
            ),
          );
          Get.snackbar(
            'Route Warning',
            'Using approximate straight-line route because detailed directions were not available.',
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
          );
        }

        // Add start marker if not already present
        if (!markers.any((marker) => marker.markerId.value == 'start')) {
          markers.add(
            Marker(
              markerId: const MarkerId('start'),
              position: currentPosition.value!,
              infoWindow: InfoWindow(title: 'Your Location'),
              icon: currentLocationIcon,
            ),
          );
        }
      } else {
        // Fallback to straight line if directions fail
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.red,
            width: 6,
            zIndex: 1,
            points: [
              currentPosition.value!,
              destinationPosition.value!,
            ],
          ),
        );
        Get.snackbar(
          'Route Warning',
          'Using approximate route. Actual driving directions may vary.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }
    } catch (e) {
      // Fallback to straight line
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue.shade300,
          width: 3,
          points: [
            currentPosition.value!,
            destinationPosition.value!,
          ],
        ),
      );
    }

    // Animate camera if controller is ready. Use a safe await with timeout
    // and catch any platform exceptions to avoid app crashes when the map
    // channel is not available (emulator/device hiccup).
    if (_controller.isCompleted) {
      try {
        final mapController =
            await _controller.future.timeout(const Duration(seconds: 5));

        // Calculate bounds to show the entire route
        // Animate camera to fit both current location and destination.
        try {
          // Always ensure southwest is the min lat/lng and northeast is the max lat/lng
          final double minLat = currentPosition.value!.latitude <
                  destinationPosition.value!.latitude
              ? currentPosition.value!.latitude
              : destinationPosition.value!.latitude;
          final double maxLat = currentPosition.value!.latitude >
                  destinationPosition.value!.latitude
              ? currentPosition.value!.latitude
              : destinationPosition.value!.latitude;
          final double minLng = currentPosition.value!.longitude <
                  destinationPosition.value!.longitude
              ? currentPosition.value!.longitude
              : destinationPosition.value!.longitude;
          final double maxLng = currentPosition.value!.longitude >
                  destinationPosition.value!.longitude
              ? currentPosition.value!.longitude
              : destinationPosition.value!.longitude;
          final bounds = LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          );
          await mapController.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 80), // 80px padding
          );
        } catch (e) {
          debugPrint('animateCamera (fit bounds) failed: $e');
        }
      } catch (e) {
        debugPrint('Could not obtain map controller or animate camera: $e');
      }
    }
  }

  // Autocomplete methods
  void onDestinationTextChanged(String query) {
    // Keep reactive query in sync for UI observers
    destinationQuery.value = query;
    if (query.isEmpty) {
      // Reset typing flag when input becomes empty
      hasStartedTyping.value = false;
      placeSuggestions.clear();
      return;
    }

    // Mark that user has started typing
    if (!hasStartedTyping.value) {
      hasStartedTyping.value = true;
    }

    if (query.length < 3) {
      // Don't show suggestions for very short queries
      placeSuggestions.clear();
      return;
    }

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer for debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      searchPlaces(query);
    });
  }

  Future<void> searchPlaces(String query) async {
    try {
      isLoadingSuggestions.value = true;

      // Use Google Places Autocomplete API for suggestions
      places.PlacesAutocompleteResponse response = await _places.autocomplete(
        query,
        language: 'en',
        components: [
          places.Component(places.Component.country, 'bd')
        ], // Restrict to Bangladesh
      );

      if (response.isOkay && response.predictions.isNotEmpty) {
        // Convert predictions to simple map format for display
        placeSuggestions.value = response.predictions.take(6).map((prediction) {
          return {
            'placeId': prediction.placeId ?? '',
            'name': prediction.description ?? 'Unknown Place',
            'formattedAddress': prediction.description ?? '',
            'reference': prediction.reference ?? '',
          };
        }).toList();
      } else {
        placeSuggestions.clear();
      }
    } catch (e) {
      placeSuggestions.clear();
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  void selectPlace(Map<String, dynamic> place) {
    final placeId = place['placeId'] as String? ?? '';
    if (placeId.isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid destination selected',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final placeName = place['name'] as String? ?? 'Unknown Place';
    destinationController.text = placeName;
    destinationQuery.value = placeName;
    placeSuggestions.clear();

    // Reset typing flag since user selected a place
    hasStartedTyping.value = false;

    // Add to search history
    addToSearchHistory(placeName);

    // Store the selected place name for fallback
    _selectedPlaceName = placeName;

    // Get place details to get coordinates
    getPlaceDetails(placeId);
  }

  // Search History Methods
  void addToSearchHistory(String query) {
    if (query.isEmpty) return;

    // Remove if already exists to avoid duplicates
    searchHistory.remove(query);

    // Add to beginning of list
    searchHistory.insert(0, query);

    // Keep only max items
    if (searchHistory.length > _maxHistoryItems) {
      searchHistory.removeRange(_maxHistoryItems, searchHistory.length);
    }
  }

  void removeFromSearchHistory(String query) {
    searchHistory.remove(query);
  }

  void clearSearchHistory() {
    searchHistory.clear();
  }

  void selectHistoryItem(String historyItem) {
    destinationController.text = historyItem;
    destinationQuery.value = historyItem;
    // Reset typing flag since user selected from history
    hasStartedTyping.value = false;
  }

  Future<String?> getAmbulancePhoneNumber(String placeId) async {
    try {
      debugPrint('Getting phone number for ambulance: $placeId');
      places.PlacesDetailsResponse response = await _places.getDetailsByPlaceId(
        placeId,
        fields: ['formatted_phone_number', 'international_phone_number'],
      );

      if (response.isOkay) {
        // Try formatted phone number first, then international
        String? phoneNumber = response.result.formattedPhoneNumber;
        if (phoneNumber == null || phoneNumber.isEmpty) {
          phoneNumber = response.result.internationalPhoneNumber;
        }
        debugPrint('Got phone number: $phoneNumber');
        return phoneNumber;
      }
    } catch (e) {
      debugPrint('Error getting phone number: $e');
    }
    return null;
  }

  Future<void> getPlaceDetails(String placeId) async {
    // Attempt to get place details by placeId first. If the google_maps_webservice
    // library fails parsing the response (type cast/null exceptions), fall back
    // to a manual Places Details REST call and finally the Geocoding REST API.
    bool resolved = false;
    try {
      debugPrint(
          'getPlaceDetails: calling Places.getDetailsByPlaceId for $placeId');
      places.PlacesDetailsResponse response = await _places.getDetailsByPlaceId(
        placeId,
        fields: ['name', 'formatted_address', 'geometry'],
      );

      if (response.isOkay && response.result.geometry != null) {
        try {
          final lat = response.result.geometry!.location.lat;
          final lng = response.result.geometry!.location.lng;
          LatLng position = LatLng(lat, lng);
          destinationPosition.value = position;

          final resolvedAddress = response.result.formattedAddress;
          final resolvedName = response.result.name;
          String? displayText;
          if (resolvedAddress != null && resolvedAddress.isNotEmpty) {
            displayText = resolvedAddress;
          } else if (resolvedName.isNotEmpty) {
            displayText = resolvedName;
          }
          if (displayText != null) {
            destinationController.text = displayText;
            destinationQuery.value = displayText;
            _selectedPlaceName = displayText;
          }

          debugPrint(
              'getPlaceDetails: got geometry from Places API: $lat,$lng');

          // Add destination marker and route
          _addDestinationMarkerAndRoute();
          resolved = true;
        } catch (e, st) {
          // Log and fall through to fallback below
          debugPrint('getPlaceDetails: parsing geometry failed: $e');
          debugPrint('$st');
        }
      } else {
        debugPrint(
            'getPlaceDetails: Places result had no geometry or not OK (status: ${response.status})');
      }
    } catch (e, st) {
      // If calling getDetailsByPlaceId throws (for example a type cast from
      // null -> String inside the library), we'll try additional fallbacks.
      debugPrint('getPlaceDetails: getDetailsByPlaceId threw: $e');
      debugPrint('$st');
    }

    if (resolved) {
      return;
    }

    if (await _tryPlacesDetailsHttp(placeId)) {
      return;
    }

    // --- Fallback: Use Google Geocoding REST API with the selected place name ---
    final String addressForGeocoding =
        _selectedPlaceName ?? destinationController.text;
    if (addressForGeocoding.trim().isEmpty) {
      Get.snackbar(
        'Destination Not Found',
        'Could not get details for the selected destination. Try entering a different destination.',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        duration: Duration(seconds: 5),
      );
      return;
    }

    try {
      debugPrint(
          'getPlaceDetails: falling back to Geocoding for "$addressForGeocoding"');
      final apiKey = _places.apiKey ?? ''; // reuse the key from places client
      final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(addressForGeocoding)}&key=$apiKey');
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      final respBody = await response.transform(utf8.decoder).join();
      httpClient.close();

      final Map<String, dynamic> json =
          jsonDecode(respBody) as Map<String, dynamic>;
      final status = (json['status'] as String?) ?? '';
      if (status == 'OK' &&
          (json['results'] is List) &&
          (json['results'] as List).isNotEmpty) {
        final first = (json['results'] as List).first as Map<String, dynamic>;
        final geometry = first['geometry'] as Map<String, dynamic>?;
        final location = geometry?['location'] as Map<String, dynamic>?;
        final lat = location?['lat'];
        final lng = location?['lng'];
        debugPrint(
            'Geocoding result: lat=$lat, lng=$lng, address=${first['formatted_address'] ?? ''}');
        if (lat != null && lng != null) {
          destinationPosition.value =
              LatLng((lat as num).toDouble(), (lng as num).toDouble());
          Get.snackbar(
            'Geocoding',
            'Resolved: lat=$lat, lng=$lng',
            backgroundColor: Colors.blue.shade50,
            colorText: Colors.blue.shade900,
            duration: Duration(seconds: 4),
          );
          _addDestinationMarkerAndRoute();
          return;
        }
      }

      // If we reach here, fallback failed
      debugPrint(
          'getPlaceDetails: Geocoding fallback returned no results or no location');
      Get.snackbar(
        'Destination Not Found',
        'Could not get details for "${_selectedPlaceName ?? addressForGeocoding}". Try using the "Set Route" button or enter a different destination.',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        duration: Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('getPlaceDetails: Geocoding fallback failed: $e');
      Get.snackbar(
        'Error',
        'Failed to get destination details. Check your network or try another destination.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<bool> _tryPlacesDetailsHttp(String placeId) async {
    final apiKey = _places.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint(
          'getPlaceDetails: HTTP details fallback skipped because API key is missing');
      return false;
    }

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId&fields=name,formatted_address,geometry&key=$apiKey',
    );

    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        debugPrint(
            'getPlaceDetails: HTTP details returned status ${response.statusCode}');
        return false;
      }

      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;
      final status = json['status'] as String? ?? '';
      if (status != 'OK') {
        debugPrint(
            'getPlaceDetails: HTTP details returned non-OK status ($status)');
        return false;
      }

      final result = json['result'] as Map<String, dynamic>?;
      final geometry = result?['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = location?['lat'];
      final lng = location?['lng'];

      if (lat == null || lng == null) {
        debugPrint('getPlaceDetails: HTTP details missing location payload');
        return false;
      }

      destinationPosition.value =
          LatLng((lat as num).toDouble(), (lng as num).toDouble());

      final String? resolvedAddress = result?['formatted_address'] as String?;
      final String? resolvedName = result?['name'] as String?;
      final displayText = (resolvedAddress?.isNotEmpty == true)
          ? resolvedAddress
          : (resolvedName?.isNotEmpty == true ? resolvedName : null);

      if (displayText != null) {
        destinationController.text = displayText;
        destinationQuery.value = displayText;
        _selectedPlaceName = displayText;
      }

      debugPrint(
          'getPlaceDetails: resolved via HTTP details call for $placeId');
      _addDestinationMarkerAndRoute();
      return true;
    } catch (e, st) {
      debugPrint('getPlaceDetails: HTTP details fallback failed: $e');
      debugPrint('$st');
      return false;
    } finally {
      httpClient.close(force: true);
    }
  }

  bool _tryFallbackHospitals(String query) {
    // Fallback hospitals in Khulna
    if (query.contains('khulna') &&
        (query.contains('medical') || query.contains('hospital'))) {
      // Khulna Medical College Hospital
      destinationPosition.value = LatLng(22.8200, 89.5510);
      destinationController.text = 'Khulna Medical College Hospital';
      destinationQuery.value = 'Khulna Medical College Hospital';
      _addDestinationMarkerAndRoute();
      return true;
    }

    // Fallback hospitals in Dhaka
    if (query.contains('dhaka') &&
        (query.contains('medical') || query.contains('hospital'))) {
      // Dhaka Medical College Hospital
      destinationPosition.value = LatLng(23.7250, 90.4000);
      destinationController.text = 'Dhaka Medical College Hospital';
      destinationQuery.value = 'Dhaka Medical College Hospital';
      _addDestinationMarkerAndRoute();
      return true;
    }

    return false;
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

  void signOut() async {
    await _auth.signOut();
    Get.offAll(() => const LoginPage());
  }

  void navigateToAmbulanceServices() {
    // Show bottomsheet with available ambulances instantly
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_hospital,
                    color: Color(0xFF1976D2),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Available Ambulances',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),

            // Ambulance list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('partners')
                    .where('isOnline', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1976D2),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading ambulances: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final ambulances = snapshot.data?.docs ?? [];

                  if (ambulances.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_hospital_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No ambulances available right now',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ambulances.length,
                    itemBuilder: (context, index) {
                      final ambulance = ambulances[index];
                      final data = ambulance.data() as Map<String, dynamic>;
                      final name = data['companyName'] ?? 'Ambulance Provider';
                      final phone = data['contact'] ?? '+8801581822846';
                      final address =
                          data['coverageArea'] ?? 'Coverage area not specified';
                      final ambulanceType =
                          data['ambulanceType'] ?? 'General Ambulance';
                      final latitude = data['latitude'] as double?;
                      final longitude = data['longitude'] as double?;
                      final profileImageUrl = data['profileImageUrl'] as String?;
                      final ambulanceImageUrl = data['ambulanceImageUrl'] as String?;

                      return FutureBuilder<Map<String, int>>(
                        future: _fetchPartnerRates(ambulance.id),
                        builder: (context, rateSnapshot) {
                          // Rates no longer displayed in list - calculated during booking
                          // final rates = rateSnapshot.data ??
                          //     {
                          //       'serviceRate': 2500,
                          //     };

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _showAmbulanceBookingDialog(
                                ambulance.id,
                                name,
                                phone,
                                address,
                                ambulanceType,
                                latitude,
                                longitude,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                children: [
                                  // Ambulance Image Section
                                  if (ambulanceImageUrl != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            ambulanceImageUrl,
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              height: 120,
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.local_shipping,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                height: 120,
                                                color: Colors.grey.shade100,
                                                child: const Center(
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              );
                                            },
                                          ),
                                          // Ambulance type badge
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1976D2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                ambulanceType,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            // Driver Profile Image
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                                                border: Border.all(
                                                  color: const Color(0xFF1976D2),
                                                  width: 2,
                                                ),
                                                image: profileImageUrl != null
                                                    ? DecorationImage(
                                                        image: NetworkImage(profileImageUrl),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                              child: profileImageUrl == null
                                                  ? const Icon(
                                                      Icons.person,
                                                      color: Color(0xFF1976D2),
                                                      size: 28,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (ambulanceImageUrl == null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '🚑 $ambulanceType',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '📍 $address',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '📞 $phone',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF1976D2),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Show fare estimation if destination is set
                                        if (currentPosition.value != null &&
                                            destinationPosition.value != null) ...[
                                          FutureBuilder<Map<String, int>>(
                                            future:
                                                _fetchPartnerRates(ambulance.id),
                                            builder: (context, rateSnapshot) {
                                              if (rateSnapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const SizedBox(
                                                  height: 60,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                                );
                                              }

                                              final rates = rateSnapshot.data ??
                                                  {'serviceRate': 2500};
                                              final distance =
                                                  FareCalculationService
                                                      .calculateDistance(
                                                currentPosition.value!.latitude,
                                                currentPosition.value!.longitude,
                                                destinationPosition.value!.latitude,
                                                destinationPosition
                                                    .value!.longitude,
                                              );

                                              return FareEstimationWidget(
                                                distance: distance,
                                                serviceType: 'ambulance',
                                                partnerRates: rates,
                                                urgency: 'normal',
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  Future<Map<String, int>> _fetchPartnerRates(String partnerId) async {
    try {
      // Check cache first
      if (partnerRates.containsKey(partnerId)) {
        return partnerRates[partnerId]!;
      }

      // Fetch from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(partnerId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rates = {
          'serviceRate': (data['serviceRate'] as int?) ?? 2500,
        };

        // Cache the rates
        partnerRates[partnerId] = rates;

        debugPrint('✅ Fetched partner rates for $partnerId: $rates');
        return rates;
      } else {
        // Use default rates if partner not found
        final defaultRates = {
          'serviceRate': 2500,
        };
        partnerRates[partnerId] = defaultRates;
        debugPrint('ℹ️ Using default rates for partner $partnerId');
        return defaultRates;
      }
    } catch (e) {
      debugPrint('❌ Error fetching partner rates for $partnerId: $e');
      // Return default rates on error
      final defaultRates = {
        'serviceRate': 2500,
      };
      partnerRates[partnerId] = defaultRates;
      return defaultRates;
    }
  }

  void _bookSpecificAmbulance(Map<String, dynamic> ambulanceData) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Get.snackbar(
        'Authentication Required',
        'You need to be logged in to place an order.',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    final partnerId = ambulanceData['id'] as String?;
    final companyName =
        ambulanceData['name'] as String? ?? 'Ambulance Provider';

    if (partnerId == null) {
      Get.snackbar(
        'Error',
        'Invalid ambulance provider selected.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    // Check if destination is selected
    if (destinationPosition.value == null) {
      Get.dialog(
        AlertDialog(
          title: Text('Destination Required'),
          content:
              Text('Please select a destination before booking an ambulance.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Fetch partner rates first for fare calculation
    final rates = await _fetchPartnerRates(partnerId);

    String selectedUrgency = 'normal'; // normal, urgent, emergency
    String additionalNotes = '';

    // Calculate distance and fare estimate
    FareDetails? estimatedFare;
    double distanceInKm = 0.0;

    if (currentPosition.value != null && destinationPosition.value != null) {
      distanceInKm = FareCalculationService.calculateDistance(
        currentPosition.value!.latitude,
        currentPosition.value!.longitude,
        destinationPosition.value!.latitude,
        destinationPosition.value!.longitude,
      );

      // Estimate fare based on distance and base rates
      estimatedFare = FareCalculationService.estimateFare(
        distanceKm: distanceInKm,
        serviceType: 'ambulance',
        partnerRates: rates,
        urgency: selectedUrgency,
      );

      debugPrint('📊 Calculated fare for booking: ৳${estimatedFare.totalFare}');
    }

    final result = await showModalBottomSheet<bool?>(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        // rounded top corners like a typical bottom sheet
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (title)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Ambulance',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            companyName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.local_hospital,
                          color: Colors.blue.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Destination summary
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 20, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedPlaceName ?? destinationQuery.value,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (distanceInKm > 0)
                        Text(
                          '${distanceInKm.toStringAsFixed(1)} km',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Ambulance Rates Display - REMOVED: Now showing calculated fare estimates during booking
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF1976D2).withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(
                //         color: const Color(0xFF1976D2).withOpacity(0.3)),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text(
                //         '🚑 Ambulance Rates',
                //         style: TextStyle(
                //           fontSize: 16,
                //           fontWeight: FontWeight.bold,
                //           color: Color(0xFF1976D2),
                //         ),
                //       ),
                //       const SizedBox(height: 8),
                //       Center(
                //         child: Text(
                //           '💰 Starting from ৳${rates['serviceRate']}',
                //           style: TextStyle(
                //             fontSize: 18,
                //             fontWeight: FontWeight.bold,
                //             color: Color(0xFF1976D2),
                //           ),
                //         ),
                //       ),
                //       const SizedBox(height: 8),
                //       const Text(
                //         '* Rates may vary based on distance and urgency',
                //         style: TextStyle(
                //           fontSize: 12,
                //           color: Colors.grey,
                //           fontStyle: FontStyle.italic,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // Fare Details Section
                if (estimatedFare != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.blue.shade300, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon and title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: Colors.blue.shade800,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ভাড়ার বিবরণ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Distance and time info in a card-like container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Distance
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(Icons.straighten,
                                        size: 20, color: Colors.blue.shade600),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${estimatedFare.distance.toStringAsFixed(1)} km',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    Text(
                                      'দূরত্ব',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.grey.shade300,
                              ),
                              // Time
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 20, color: Colors.green.shade600),
                                    const SizedBox(height: 4),
                                    Text(
                                      '~${estimatedFare.estimatedTime.toStringAsFixed(0)} min',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                    Text(
                                      'সময়',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Fare breakdown in a cleaner list format
                        Text(
                          'চার্জের বিবরণ:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: estimatedFare.breakdown.entries
                                .where((entry) =>
                                    !entry.key
                                        .toLowerCase()
                                        .contains('subtotal') &&
                                    !entry.key
                                        .toLowerCase()
                                        .contains('surge') &&
                                    entry.value != 1.0)
                                .map((entry) {
                              final label = _friendlyFareKey(entry.key);
                              String valueText;
                              if (entry.key
                                      .toLowerCase()
                                      .contains('multiplier') ||
                                  entry.key.toLowerCase().contains('urgency')) {
                                final num rawNum = entry.value as num;
                                valueText = '×${rawNum.toStringAsFixed(1)}';
                              } else {
                                valueText = _formatFare(entry.value);
                              }
                              return _buildBreakdownRow(label, valueText,
                                  valueColor: entry.key
                                              .toLowerCase()
                                              .contains('multiplier') ||
                                          entry.key
                                              .toLowerCase()
                                              .contains('surge')
                                      ? Colors.orange.shade700
                                      : null,
                                  icon: entry.key
                                          .toLowerCase()
                                          .contains('distance')
                                      ? Icons.straighten
                                      : null);
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Divider(color: Colors.blue.shade300, thickness: 1),
                        const SizedBox(height: 8),

                        // Total amount in a highlighted box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.shade200, width: 1.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '💰 আনুমানিক ভাড়া',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              Text(
                                _formatFare(estimatedFare.totalFare),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          '* এটি আনুমানিক ভাড়া। চূড়ান্ত ভাড়া রাইড শেষে নির্ধারিত হবে।',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: null,
                  onChanged: (value) => additionalNotes = value,
                ),
                const SizedBox(height: 16),
                // Actions
                Column(
                  children: [
                    // Call Ambulance button (top)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _callAmbulance(ambulanceData['phone']),
                        icon: const Icon(Icons.call, size: 20),
                        label: const Text('Call Ambulance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade800,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.blue.shade100),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cancel and Book Now buttons (bottom row)
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.blue.shade300),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Get.back(result: true),
                            icon: const Icon(Icons.book_online, size: 20),
                            label: const Text('Confirm & Book'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 6,
                              shadowColor: Colors.green.shade200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      // Recompute fare with the final selected urgency so the backend records the
      // fare that the user actually saw at confirmation.
      FareDetails? finalFare;
      if (currentPosition.value != null && destinationPosition.value != null) {
        finalFare = FareCalculationService.estimateFare(
          distanceKm: distanceInKm,
          serviceType: 'ambulance',
          partnerRates: rates,
          urgency: selectedUrgency,
        );
      }

      String? orderId = await _createDirectAmbulanceRequest(
        partnerId: partnerId,
        companyName: companyName,
        urgency: selectedUrgency,
        notes: additionalNotes,
        fareDetails: finalFare, // Pass the recalculated fare
      );
      if (orderId == null) {
        // If order creation failed, show error (but success dialog is already handled)
        debugPrint('❌ Order creation failed');
      }
    }
  }

  Future<String> _getAmbulanceAddress(Map<String, dynamic> data) async {
    String address = data['address'] ?? '';

    if (address.isNotEmpty &&
        address != 'Coverage area not specified' &&
        address != '321') {
      return address;
    }

    // Reverse geocode
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        data['latitude'] as double,
        data['longitude'] as double,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      debugPrint('Error reverse geocoding ambulance address: $e');
    }

    return 'Address not available';
  }

  void _showAmbulanceProviderDetails(Map<String, dynamic> ambulanceData) {
    // Show ambulance provider details in a beautifully simple bottom sheet
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Simple drag handle
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 15, 20, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show ambulance image banner if available
                    if (ambulanceData['ambulanceImageUrl'] != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              ambulanceData['ambulanceImageUrl'],
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 160,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.local_shipping,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 160,
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                            ),

                            // Slight gradient overlay to keep text readable if needed
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.15)],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                    // Clean Header
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            image: ambulanceData['profileImageUrl'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        ambulanceData['profileImageUrl']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: ambulanceData['profileImageUrl'] == null
                              ? Icon(
                                  Icons.local_hospital,
                                  color: Colors.blue.shade600,
                                  size: 26,
                                )
                              : null,
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ambulanceData['name'] ?? 'Ambulance Provider',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Available Now',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Essential Information
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Address
                          FutureBuilder<String>(
                            future: _getAmbulanceAddress(ambulanceData),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            color: Colors.blue.shade600,
                                            size: 18),
                                        SizedBox(width: 10),
                                        Text('Loading address...',
                                            style: TextStyle(
                                                color: Colors.grey.shade600)),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                  ],
                                );
                              }

                              final address =
                                  snapshot.data ?? 'Address not available';
                              if (address == 'Address not available') {
                                return SizedBox.shrink();
                              }

                              return Column(
                                children: [
                                  _buildSimpleInfoRow(
                                    Icons.location_on,
                                    Colors.blue.shade600,
                                    'Address',
                                    address,
                                    maxLines: 2,
                                  ),
                                  SizedBox(height: 12),
                                ],
                              );
                            },
                          ),

                          // Ambulance Type
                          if (ambulanceData['ambulanceType'] != null)
                            _buildSimpleInfoRow(
                              Icons.directions_car,
                              Colors.orange.shade600,
                              'Type',
                              ambulanceData['ambulanceType'],
                            ),

                          if (ambulanceData['ambulanceType'] != null)
                            SizedBox(height: 12),

                          // Phone
                          _buildSimpleInfoRow(
                            Icons.phone,
                            Colors.green.shade600,
                            'Phone',
                            ambulanceData['phone'] ?? '+8801581822846',
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Fare Estimation (if applicable)
                    if (currentPosition.value != null &&
                        destinationPosition.value != null) ...[
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: FutureBuilder<Map<String, int>>(
                          future: _fetchPartnerRates(ambulanceData['id']),
                          builder: (context, rateSnapshot) {
                            if (rateSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.amber.shade600),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Calculating fare...',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              );
                            }

                            final rates =
                                rateSnapshot.data ?? {'serviceRate': 2500};
                            final distance =
                                FareCalculationService.calculateDistance(
                              currentPosition.value!.latitude,
                              currentPosition.value!.longitude,
                              destinationPosition.value!.latitude,
                              destinationPosition.value!.longitude,
                            );

                            return FareEstimationWidget(
                              distance: distance,
                              serviceType: 'ambulance',
                              partnerRates: rates,
                              urgency: 'normal',
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        // Call Button - Left side
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final String numberToCall =
                                  ambulanceData['phone'] ?? '+8801581822846';
                              final Uri launchUri = Uri(
                                scheme: 'tel',
                                path: numberToCall,
                              );
                              try {
                                await launchUrl(launchUri);
                                SuccessDialog.show(
                                  title: 'Call Ambulance',
                                  message:
                                      'Calling ${ambulanceData['name']}...',
                                );
                              } catch (e) {
                                Get.snackbar(
                                  'Error',
                                  'Unable to make call. Please dial $numberToCall manually.',
                                  backgroundColor: Colors.red.shade100,
                                  colorText: Colors.red.shade800,
                                );
                              }
                              Get.back();
                            },
                            icon: Icon(Icons.call, size: 18),
                            label: Text('Call'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade300),
                              foregroundColor: Colors.green.shade700,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 10),
                        // Book Now - Right side (Primary Action)
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.back();
                              _bookSpecificAmbulance(ambulanceData);
                            },
                            icon: Icon(Icons.book_online, size: 18),
                            label: Text('Book Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Show emergency call popup with options to copy number or call directly
  Future<void> callCenter() async {
    const String phoneNumber = '+8801793399913';
    const String displayNumber = '+880 1793-399913';
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emergency Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emergency,
                  color: Colors.red.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Emergency Call',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                'For emergency ambulance service, contact the NeoSaver emergency helpline.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              
              // Phone Number Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone,
                      color: Colors.red.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      displayNumber,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  // Copy Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phoneNumber));
                        Get.back();
                        Get.snackbar(
                          'Copied!',
                          'Emergency number copied to clipboard',
                          backgroundColor: Colors.green.shade100,
                          colorText: Colors.green.shade800,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                          icon: Icon(Icons.check_circle, color: Colors.green.shade700),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Call Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        _makeEmergencyCall(phoneNumber);
                      },
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Cancel Button
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Make the actual emergency call
  Future<void> _makeEmergencyCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      // Request phone call permission
      var status = await Permission.phone.request();
      if (status.isGranted) {
        if (await canLaunchUrl(uri)) {
          bool launched = await launchUrl(uri);
          if (!launched) {
            Get.snackbar(
              'Cannot Call',
              'Unable to open the phone dialer on this device.',
              backgroundColor: Colors.red.shade100,
              colorText: Colors.red.shade800,
            );
          }
        } else {
          Get.snackbar(
            'Cannot Call',
            'Unable to open the phone dialer on this device.',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        }
      } else if (status.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Required',
          'Phone call permission is permanently denied. Please enable it in app settings.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: Duration(seconds: 5),
        );
        // Open app settings
        await openAppSettings();
      } else {
        Get.snackbar(
          'Permission Denied',
          'Phone call permission is required to make calls.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }
    } catch (e) {
      debugPrint('Failed to launch dialer: $e');
      Get.snackbar(
        'Error',
        'Failed to start call. Please manually dial $phoneNumber',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Public wrapper so UI code can open ambulance details (calls the private
  /// bottom-sheet implementation already present in this controller).
  void viewAmbulanceDetails(Map<String, dynamic> ambulanceData) {
    _showAmbulanceProviderDetails(ambulanceData);
  }

  // Simplified info row helper
  Widget _buildSimpleInfoRow(
      IconData icon, Color iconColor, String label, String value,
      {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String?> _createDirectAmbulanceRequest({
    required String partnerId,
    required String companyName,
    required String urgency,
    required String notes,
    FareDetails? fareDetails,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Get.snackbar(
        'Error',
        'User not authenticated',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return null;
    }

    try {
      // Fetch user details from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data() ?? {};

      // Check if user already has a pending ambulance request to this specific partner
      final existingRequests = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('partnerId', isEqualTo: partnerId)
          .where('type', isEqualTo: 'ambulance')
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequests.docs.isNotEmpty) {
        Get.snackbar(
          'Request Already Pending',
          'You already have a pending ambulance request to this partner. Please wait for them to accept or decline before submitting a new request.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: const Duration(seconds: 5),
        );
        return null;
      }

      // Get current location for pickup address
      String pickupAddress = 'Location not available';
      if (currentPosition.value != null) {
        try {
          // Try reverse geocoding to get human-readable address
          List<geocoding.Placemark> placemarks =
              await geocoding.placemarkFromCoordinates(
            currentPosition.value!.latitude,
            currentPosition.value!.longitude,
          );

          if (placemarks.isNotEmpty) {
            geocoding.Placemark place = placemarks.first;
            // Build a readable address from placemark data
            List<String> addressParts = [];
            if (place.street != null && place.street!.isNotEmpty) {
              addressParts.add(place.street!);
            }
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              addressParts.add(place.subLocality!);
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              addressParts.add(place.locality!);
            }
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              addressParts.add(place.administrativeArea!);
            }
            if (place.country != null && place.country!.isNotEmpty) {
              addressParts.add(place.country!);
            }

            pickupAddress = addressParts.join(', ');
            debugPrint('Reverse geocoding successful: $pickupAddress');
          } else {
            // Fallback to coordinates if reverse geocoding fails
            pickupAddress =
                'Lat: ${currentPosition.value!.latitude.toStringAsFixed(6)}, Lng: ${currentPosition.value!.longitude.toStringAsFixed(6)}';
            debugPrint(
                'Reverse geocoding returned no results, using coordinates');
          }
        } catch (e) {
          // Fallback to coordinates if reverse geocoding fails
          pickupAddress =
              'Lat: ${currentPosition.value!.latitude.toStringAsFixed(6)}, Lng: ${currentPosition.value!.longitude.toStringAsFixed(6)}';
          debugPrint('Reverse geocoding failed: $e, using coordinates');
        }
      }

      final docRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': userId,
        'partnerId': partnerId,
        'companyName': companyName,
        'urgency': urgency,
        'notes': notes,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'ambulance',
        'userLocation': {
          'latitude': currentPosition.value?.latitude,
          'longitude': currentPosition.value?.longitude,
        },
        // Include user details
        'patientName': userData['name'] ?? 'Name not provided',
        'phone': userData['phone'] ?? 'Phone not provided',
        'email': userData['email'] ??
            _auth.currentUser?.email ??
            'Email not provided',
        'pickupAddress': pickupAddress,
        'pickupLat': currentPosition.value?.latitude,
        'pickupLng': currentPosition.value?.longitude,
        // Include destination information
        'destinationAddress': _selectedPlaceName ?? destinationQuery.value,
        'destinationLat': destinationPosition.value?.latitude,
        'destinationLng': destinationPosition.value?.longitude,
        'fareDetails': fareDetails?.toMap(),
        'totalAmount': fareDetails?.totalFare ?? 0.0,
      });

      debugPrint('✅ Order created successfully with ID: ${docRef.id}');

      // Show success dialog immediately after order creation
      SuccessDialog.show(
        title: 'Order Created',
        message: 'Your ambulance request has been submitted successfully.',
      );

      // Send notification to ambulance partner (don't fail the request if this fails)
      final requestData = {
        'orderId': docRef.id,
        'partnerId': partnerId,
        'companyName': companyName,
        'urgency': urgency,
        'notes': notes,
        'status': 'pending',
        'type': 'ambulance',
        'userLocation': {
          'latitude': currentPosition.value?.latitude,
          'longitude': currentPosition.value?.longitude,
        },
        'patientName': userData['name'] ?? 'Name not provided',
        'phone': userData['phone'] ?? 'Phone not provided',
        'email': userData['email'] ??
            _auth.currentUser?.email ??
            'Email not provided',
        'pickupAddress': pickupAddress,
        'pickupLat': currentPosition.value?.latitude,
        'pickupLng': currentPosition.value?.longitude,
        // Include destination information
        'destinationAddress': _selectedPlaceName ?? destinationQuery.value,
        'destinationLat': destinationPosition.value?.latitude,
        'destinationLng': destinationPosition.value?.longitude,
      };

      try {
        await NotificationService.sendAmbulanceNotificationDirect(
          partnerId: partnerId,
          requestData: requestData,
        );
        debugPrint('✅ Ambulance notification sent to partner: $partnerId');

        // Add notification for user about request creation
        await _addUserNotification(
          title: '🚑 অ্যাম্বুলেন্স অনুরোধ পাঠানো হয়েছে',
          message: 'আপনার অ্যাম্বুলেন্স অনুরোধ সফলভাবে পাঠানো হয়েছে। পার্টনার খুব শীঘ্রই আপনার সাথে যোগাযোগ করবে।',
          type: 'ambulance',
          data: {
            'type': 'ambulance_request',
            'requestId': docRef.id,
            'partnerId': partnerId,
            'status': 'sent',
          },
        );

        // Send FCM push notification
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await NotificationService.sendUserNotification(
            userId: currentUser.uid,
            title: '🚑 অ্যাম্বুলেন্স অনুরোধ পাঠানো হয়েছে',
            message: 'আপনার অ্যাম্বুলেন্স অনুরোধ সফলভাবে পাঠানো হয়েছে।',
            data: {
              'type': 'ambulance_request',
              'requestId': docRef.id,
              'status': 'sent',
            },
          );
        }
      } catch (notificationError) {
        debugPrint(
            '❌ Failed to send ambulance notification: $notificationError');
        // Don't fail the entire request if notification fails
      }

      // Listen for status updates
      listenForRequestUpdates(docRef.id);

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Failed to create ambulance request: $e');
      Get.snackbar(
        'Error',
        'Failed to send request: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return null;
    }
  }

  void listenForRequestUpdates(String orderId) {
    // Cancel any existing subscription
    _orderSubscription?.cancel();

    // Set current tracking order ID
    currentTrackingOrderId.value = orderId;

    // Listen for order updates
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        final status = data?['orderStatus'] ?? data?['status'];

        // Handle status updates
        if (status == 'accepted') {
          isTrackingPartner.value = true;
          // Don't show OTP in success dialog - it will be shown when ambulance arrives at pickup
          SuccessDialog.show(
            title: 'Order Accepted',
            message:
                'Your ambulance has been assigned and is on the way. You will receive a pickup OTP when the ambulance arrives.',
            onTap: () => navigateToTrackingPage(),
            autoCloseDuration: const Duration(seconds: 8),
          );

          // Add notification for user
          _addUserNotification(
            title: '✅ অ্যাম্বুলেন্স নিশ্চিত হয়েছে',
            message: 'আপনার অ্যাম্বুলেন্স অ্যাসাইন হয়েছে এবং আপনার দিকে আসছে। অ্যাম্বুলেন্স পৌঁছালে পিকআপ OTP পাবেন।',
            type: 'ambulance',
            data: {
              'type': 'status_update',
              'requestId': orderId,
              'status': 'accepted',
            },
          );

          // Send FCM push notification
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            NotificationService.sendUserNotification(
              userId: user.uid,
              title: '✅ অ্যাম্বুলেন্স নিশ্চিত হয়েছে',
              message: 'আপনার অ্যাম্বুলেন্স অ্যাসাইন হয়েছে এবং আপনার দিকে আসছে।',
              data: {
                'type': 'status_update',
                'requestId': orderId,
                'status': 'accepted',
              },
            );
          }
        } else if (status == 'in_transit') {
          isTrackingPartner.value = true;
          // Show OTP when ambulance is in transit (arrived at pickup)
          final pickupOTP = data?['pickupOTP'];
          if (pickupOTP != null && pickupOTP != 'N/A') {
            SuccessDialog.show(
              title: 'Ambulance Arrived',
              message:
                  'Your ambulance has arrived at the pickup location. OTP: $pickupOTP. Please show this OTP to the driver.',
              onTap: () => navigateToTrackingPage(),
              autoCloseDuration: const Duration(seconds: 10),
            );

            // Add notification for user
            _addUserNotification(
              title: '🚑 অ্যাম্বুলেন্স পৌঁছেছে',
              message: 'আপনার অ্যাম্বুলেন্স পিকআপ লোকেশনে পৌঁছেছে। OTP: $pickupOTP। ড্রাইভারকে এই OTP দেখান।',
              type: 'ambulance',
              data: {
                'type': 'otp_received',
                'requestId': orderId,
                'status': 'in_transit',
                'pickupOTP': pickupOTP,
              },
            );

            // Send FCM push notification
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              NotificationService.sendUserNotification(
                userId: user.uid,
                title: '🚑 অ্যাম্বুলেন্স পৌঁছেছে',
                message: 'আপনার অ্যাম্বুলেন্স পিকআপ লোকেশনে পৌঁছেছে। OTP: $pickupOTP',
                data: {
                  'type': 'otp_received',
                  'requestId': orderId,
                  'pickupOTP': pickupOTP,
                },
              );
            }
          }
        } else if (status == 'pickup') {
          isTrackingPartner.value = true;
          // Ambulance has picked up patient and is going to destination
          SuccessDialog.show(
            title: 'Patient Picked Up',
            message:
                'Your ambulance has picked up the patient and is heading to the destination.',
            onTap: () => navigateToTrackingPage(),
            autoCloseDuration: const Duration(seconds: 5),
          );

          // Add notification for user
          _addUserNotification(
            title: '🏥 রোগী তুলে নেয়া হয়েছে',
            message: 'অ্যাম্বুলেন্স রোগী তুলে নিয়েছে এবং গন্তব্যের দিকে যাচ্ছে।',
            type: 'ambulance',
            data: {
              'type': 'status_update',
              'requestId': orderId,
              'status': 'pickup',
            },
          );

          // Send FCM push notification
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            NotificationService.sendUserNotification(
              userId: user.uid,
              title: '🏥 রোগী তুলে নেয়া হয়েছে',
              message: 'অ্যাম্বুলেন্স রোগী তুলে নিয়েছে এবং গন্তব্যের দিকে যাচ্ছে।',
              data: {
                'type': 'status_update',
                'requestId': orderId,
                'status': 'pickup',
              },
            );
          }
        } else if (status == 'to_destination') {
          isTrackingPartner.value = true;
          // Ambulance is going to destination - show destination OTP
          final destinationOTP = data?['destinationOTP'];
          if (destinationOTP != null && destinationOTP != 'N/A') {
            SuccessDialog.show(
              title: 'Heading to Destination',
              message:
                  'Your ambulance is now heading to the destination. Arrival OTP: $destinationOTP. Please show this OTP to the driver when you arrive.',
              onTap: () => navigateToTrackingPage(),
              autoCloseDuration: const Duration(seconds: 8),
            );

            // Add notification for user
            _addUserNotification(
              title: '🎯 গন্তব্যের দিকে যাচ্ছে',
              message: 'আপনার অ্যাম্বুলেন্স এখন গন্তব্যের দিকে যাচ্ছে। পৌঁছানোর OTP: $destinationOTP। পৌঁছালে ড্রাইভারকে এই OTP দেখান।',
              type: 'ambulance',
              data: {
                'type': 'otp_received',
                'requestId': orderId,
                'status': 'to_destination',
                'destinationOTP': destinationOTP,
              },
            );

            // Send FCM push notification
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              NotificationService.sendUserNotification(
                userId: user.uid,
                title: '🎯 গন্তব্যের দিকে যাচ্ছে',
                message: 'আপনার অ্যাম্বুলেন্স এখন গন্তব্যের দিকে যাচ্ছে। OTP: $destinationOTP',
                data: {
                  'type': 'otp_received',
                  'requestId': orderId,
                  'destinationOTP': destinationOTP,
                },
              );
            }
          } else {
            SuccessDialog.show(
              title: 'Heading to Destination',
              message:
                  'Your ambulance is now heading to the destination.',
              onTap: () => navigateToTrackingPage(),
              autoCloseDuration: const Duration(seconds: 5),
            );

            // Add notification for user
            _addUserNotification(
              title: '🎯 গন্তব্যের দিকে যাচ্ছে',
              message: 'আপনার অ্যাম্বুলেন্স এখন গন্তব্যের দিকে যাচ্ছে।',
              type: 'ambulance',
              data: {
                'type': 'status_update',
                'requestId': orderId,
                'status': 'to_destination',
              },
            );
          }
        } else if (status == 'completed') {
          isTrackingPartner.value = false;
          currentTrackingOrderId.value = null;
          partnerLiveLocation.value = null;
          partnerLocationTrail.clear();

          // Clear partner markers and polylines
          markers
              .removeWhere((marker) => marker.markerId.value == 'partner_live');
          polylines.removeWhere(
              (polyline) => polyline.polylineId.value == 'partner_trail');

          // Clear destination when order is completed
          destinationPosition.value = null;
          destinationController.clear();
          destinationQuery.value = '';
          placeSuggestions.clear();
          _selectedPlaceName = null;
          
          // Clear all polylines and destination markers
          polylines.clear();
          markers.removeWhere((marker) => marker.markerId.value == 'destination');
          markers.removeWhere((marker) => marker.markerId.value == 'start');

          SuccessDialog.show(
            title: 'Service Completed',
            message: 'Your ambulance service has been completed.',
          );

          // Add notification for user
          _addUserNotification(
            title: '🎉 সেবা সম্পন্ন হয়েছে',
            message: 'আপনার অ্যাম্বুলেন্স সেবা সম্পন্ন হয়েছে। আমাদের সেবা ব্যবহার করার জন্য ধন্যবাদ।',
            type: 'ambulance',
            data: {
              'type': 'service_completed',
              'requestId': orderId,
              'status': 'completed',
            },
          );

          // Send FCM push notification
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            NotificationService.sendUserNotification(
              userId: user.uid,
              title: '🎉 সেবা সম্পন্ন হয়েছে',
              message: 'আপনার অ্যাম্বুলেন্স সেবা সম্পন্ন হয়েছে।',
              data: {
                'type': 'service_completed',
                'requestId': orderId,
                'status': 'completed',
              },
            );
          }
        } else if (status == 'declined') {
          // Show cancellation dialog
          Get.dialog(
            AlertDialog(
              title: Text('অর্ডার বাতিল'),
              content: Text('আপনার অ্যাম্বুলেন্স রিকুয়েস্ট বাতিল করা হয়েছে।'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('ঠিক আছে'),
                ),
              ],
            ),
          );

          // Add notification for user
          _addUserNotification(
            title: '❌ অর্ডার বাতিল',
            message: 'দুঃখিত, আপনার অ্যাম্বুলেন্স রিকুয়েস্ট বাতিল করা হয়েছে। দয়া করে আবার চেষ্টা করুন।',
            type: 'ambulance',
            data: {
              'type': 'order_declined',
              'requestId': orderId,
              'status': 'declined',
            },
          );

          // Send FCM push notification
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            NotificationService.sendUserNotification(
              userId: user.uid,
              title: '❌ অর্ডার বাতিল',
              message: 'দুঃখিত, আপনার অ্যাম্বুলেন্স রিকুয়েস্ট বাতিল করা হয়েছে।',
              data: {
                'type': 'order_declined',
                'requestId': orderId,
                'status': 'declined',
              },
            );
          }

          // Stop tracking
          isTrackingPartner.value = false;
          currentTrackingOrderId.value = null;
          partnerLiveLocation.value = null;
          partnerLocationTrail.clear();
          
          // Clear destination when order is declined
          destinationPosition.value = null;
          destinationController.clear();
          destinationQuery.value = '';
          placeSuggestions.clear();
          _selectedPlaceName = null;
          
          // Clear all markers and polylines
          markers
              .removeWhere((marker) => marker.markerId.value == 'partner_live');
          polylines.removeWhere(
              (polyline) => polyline.polylineId.value == 'partner_trail');
          polylines.clear();
          markers.removeWhere((marker) => marker.markerId.value == 'destination');
          markers.removeWhere((marker) => marker.markerId.value == 'start');
        }

        // Handle live location updates
        final liveLocation =
            data?['partnerLiveLocation'] as Map<String, dynamic>?;
        if (liveLocation != null && isTrackingPartner.value) {
          final lat = liveLocation['latitude'] as double?;
          final lng = liveLocation['longitude'] as double?;

          if (lat != null && lng != null) {
            final newLocation = LatLng(lat, lng);

            // Update partner live location
            partnerLiveLocation.value = newLocation;

            // Add to location trail
            if (partnerLocationTrail.isEmpty ||
                partnerLocationTrail.last != newLocation) {
              partnerLocationTrail.add(newLocation);

              // Keep only last 50 points to avoid performance issues
              if (partnerLocationTrail.length > 50) {
                partnerLocationTrail.removeAt(0);
              }
            }

            // Update partner marker
            markers.removeWhere(
                (marker) => marker.markerId.value == 'partner_live');
            markers.add(
              Marker(
                markerId: const MarkerId('partner_live'),
                position: newLocation,
                infoWindow: const InfoWindow(title: '🚑 Ambulance (Live)'),
                icon: ambulanceIcon,
              ),
            );

            // Update partner trail polyline
            polylines.removeWhere(
                (polyline) => polyline.polylineId.value == 'partner_trail');
            if (partnerLocationTrail.length > 1) {
              polylines.add(
                Polyline(
                  polylineId: const PolylineId('partner_trail'),
                  color: Colors.green.shade600,
                  width: 4,
                  points: partnerLocationTrail,
                  zIndex: 2,
                ),
              );
            }
          }
        }
      }
    });
  }

  void navigateToPartnersOrders() {
    Get.to(() => PartnersOrdersPage());
  }

  void navigateToUserOrders() {
    Get.to(() => UserOrdersPage());
  }

  void navigateToUserId() {
    Get.to(() => UserIdPage());
  }

  void navigateToAboutUs() {
    Get.to(() => AboutUsPage());
  }

  void navigateToSOSChat() {
    Get.to(() => const SOSChatPage());
  }

  void navigateToTrackingPage() async {
    final orderId = currentTrackingOrderId.value;
    if (orderId != null && isTrackingPartner.value) {
      // Check if this order has been acknowledged before
      if (acknowledgedTrackingOrders.contains(orderId)) {
        // Already acknowledged, go directly to tracking
        navigateToUserTracking(orderId);
      } else {
        // Not acknowledged yet, show the tracking dialog first
        _showTrackingDialog(
          'Ambulance is on the way!',
          'Your ambulance has been dispatched and is heading to your location. Track its live location.',
          orderId,
        );
      }
    } else {
      // No active tracking, navigate to orders page or show message
      Get.snackbar(
        'No Active Tracking',
        'You don\'t have any active ambulance tracking at the moment.',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      // Or navigate to orders page
      navigateToUserOrders();
    }
  }

  void navigateToUserTracking(String orderId) async {
    try {
      // Fetch the complete order data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        final orderData = {'id': orderId, ...doc.data()!};
        Get.to(() => const UserTrackingPage(), arguments: orderData);
      } else {
        Get.snackbar(
          'Error',
          'Order data not found',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      debugPrint('Error fetching order data: $e');
      Get.snackbar(
        'Error',
        'Failed to load tracking data',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void _showTrackingDialog(String title, String message, String orderId) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button at top right
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: Colors.grey.shade500),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: Colors.blue.shade700,
                  size: 40,
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'পরে দেখব',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _addAcknowledgedOrder(orderId);
                        navigateToUserTracking(orderId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'ট্র্যাক করুন',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showAmbulanceBookingDialog(
    String partnerId,
    String companyName,
    String phone,
    String address,
    String ambulanceType,
    double? latitude,
    double? longitude,
  ) async {
    // Fetch partner rates first
    final rates = await _fetchPartnerRates(partnerId);

    String selectedUrgency = 'normal'; // normal, urgent, emergency
    String additionalNotes = '';

    // Calculate distance and fare estimate if destination is available
    FareDetails? estimatedFare;
    double distanceInKm = 0.0;

    if (currentPosition.value != null && destinationPosition.value != null) {
      distanceInKm = FareCalculationService.calculateDistance(
        currentPosition.value!.latitude,
        currentPosition.value!.longitude,
        destinationPosition.value!.latitude,
        destinationPosition.value!.longitude,
      );

      // Estimate fare based on distance and base rates
      estimatedFare = FareCalculationService.estimateFare(
        distanceKm: distanceInKm,
        serviceType: 'ambulance',
        partnerRates: rates,
        urgency: selectedUrgency,
      );
    }

    final result = await Get.dialog(
      AlertDialog(
        title: Text('Book Ambulance - $companyName'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ambulance Rates Display - REMOVED: Now showing calculated fare estimates below
                // const SizedBox(height: 16),

                // Fare Estimate Display (always show, even without destination)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            estimatedFare != null
                                ? 'Final Price Estimate'
                                : 'Base Rates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (estimatedFare != null) ...[
                        // Distance and time info
                        Row(
                          children: [
                            Icon(Icons.straighten,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${distanceInKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '~${estimatedFare!.estimatedTime.toStringAsFixed(0)} min',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Final Price - Make this more prominent
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '💰 Total Amount to Pay',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              Text(
                                '৳${estimatedFare!.totalFare.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          '* This is the exact price you will pay for this service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        // Show base rates when no destination is set
                        const Text(
                          'Base Service Rate:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            '৳${rates['serviceRate']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '* Set destination to see exact fare estimate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Select urgency level:'),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedUrgency,
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    DropdownMenuItem(
                        value: 'emergency', child: Text('Emergency')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedUrgency = value;
                        // Recalculate fare when urgency changes
                        if (distanceInKm > 0) {
                          estimatedFare = FareCalculationService.estimateFare(
                            distanceKm: distanceInKm,
                            serviceType: 'ambulance',
                            partnerRates: rates,
                            urgency: selectedUrgency,
                          );
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => additionalNotes = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Recalculate final fare just before confirmation
              FareDetails? finalFare;
              if (currentPosition.value != null &&
                  destinationPosition.value != null) {
                finalFare = FareCalculationService.estimateFare(
                  distanceKm: distanceInKm,
                  serviceType: 'ambulance',
                  partnerRates: rates,
                  urgency: selectedUrgency,
                );
              }

              Get.back(result: {
                'urgency': selectedUrgency,
                'notes': additionalNotes,
                'estimatedFare': finalFare,
              });
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Extract booking details
      final bookingDetails = result as Map<String, dynamic>;
      final urgency = bookingDetails['urgency'] as String;
      final notes = bookingDetails['notes'] as String;
      final fareDetails = bookingDetails['estimatedFare'] as FareDetails?;

      // Create ambulance request directly
      String? orderIdResult = await _createDirectAmbulanceRequest(
        partnerId: partnerId,
        companyName: companyName,
        urgency: urgency,
        notes: notes,
        fareDetails: fareDetails,
      );

      if (orderIdResult != null) {
        SuccessDialog.show(
          title: 'Booking Confirmed!',
          message: 'Your ambulance booking has been confirmed successfully.',
        );
      }
    }
  }

  void clearMarkers() {
    markers.clear();
    polylines.clear();
    destinationPosition.value = null;
    destinationController.clear();
    destinationQuery.value = '';
    placeSuggestions.clear();
    _selectedPlaceName = null;
    
    // Re-add current location marker if available
    if (currentPosition.value != null) {
      markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: currentPosition.value!,
          infoWindow: InfoWindow(title: 'Your Location'),
          icon: currentLocationIcon,
        ),
      );
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

  // Method to set destination from coordinates and show route (for ambulance requests)
  Future<void> setDestinationFromCoordinates(
      double latitude, double longitude) async {
    try {
      destinationPosition.value = LatLng(latitude, longitude);
      await _addDestinationMarkerAndRoute();

      // Move camera to show both current location and destination
      if (_controller.isCompleted && currentPosition.value != null) {
        final GoogleMapController controller = await _controller.future;
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            latitude < currentPosition.value!.latitude
                ? latitude
                : currentPosition.value!.latitude,
            longitude < currentPosition.value!.longitude
                ? longitude
                : currentPosition.value!.longitude,
          ),
          northeast: LatLng(
            latitude > currentPosition.value!.latitude
                ? latitude
                : currentPosition.value!.latitude,
            longitude > currentPosition.value!.longitude
                ? longitude
                : currentPosition.value!.longitude,
          ),
        );
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to set destination: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // FCM Push Notification Methods

  /// Sends push notification to a specific driver using their FCM token
  /// This method directly sends notification to individual driver
  Future<void> sendNotificationToDriver({
    required String driverId,
    required String fcmToken,
    required Map<String, dynamic> requestData,
  }) async {
    try {
      // You can get this server key from Firebase Console > Project Settings > Cloud Messaging
      // For production, this should be stored securely on backend server
      const String serverKey =
          'YOUR_FCM_SERVER_KEY_HERE'; // Replace with actual server key

      // Get current user info
      final currentUser = _auth.currentUser;
      final userId = currentUser?.uid ?? '';

      // Get user data from Firestore
      DocumentSnapshot? userDoc;
      String userName = 'User';
      String userPhone = '';
      String userAddress = '';

      if (userId.isNotEmpty) {
        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          userName = userData?['name'] ?? currentUser?.displayName ?? 'User';
          userPhone = userData?['phone'] ?? currentUser?.phoneNumber ?? '';
          userAddress = userData?['address'] ?? '';
        }
      }

      // Prepare notification data
      final Map<String, dynamic> notificationData = {
        'title': 'নতুন রাইড রিকুয়েস্ট',
        'body': '$userName আপনার কাছে একটি রাইড রিকুয়েস্ট পাঠিয়েছেন',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'sound': 'default',
      };

      // Prepare data payload that will be sent with notification
      final Map<String, dynamic> dataPayload = {
        'type': 'ride_request',
        'requestId': requestData['requestId'] ?? '',
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'userAddress': userAddress,
        'pickupLocation': jsonEncode(requestData['pickupLocation'] ?? {}),
        'destinationLocation':
            jsonEncode(requestData['destinationLocation'] ?? {}),
        'pickupAddress': requestData['pickupAddress'] ?? '',
        'destinationAddress': requestData['destinationAddress'] ?? '',
        'fare': requestData['fare'] ?? '',
        'distance': requestData['distance'] ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'urgency': requestData['urgency'] ?? 'normal',
      };

      // Prepare FCM message
      final Map<String, dynamic> message = {
        'to': fcmToken,
        'notification': notificationData,
        'data': dataPayload,
        'priority': 'high',
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'ride_requests',
            'sound': 'default',
            'priority': 'high',
          }
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
              'badge': 1,
            }
          }
        }
      };

      // Send FCM notification
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Push notification sent successfully to driver: $driverId');
        print('📱 FCM Response: ${response.body}');

        /*    // Show success message to user
        Get.snackbar(
          'সফল',
          'ড্রাইভারের কাছে আপনার রিকুয়েস্ট পাঠানো হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3),
        ); */
      } else {
        print('❌ Failed to send push notification: ${response.statusCode}');
        print('📱 FCM Error Response: ${response.body}');

        /*  Get.snackbar(
          'ত্রুটি',
          'নোটিফিকেশন পাঠাতে সমস্যা হয়েছে',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        ); */
      }
    } catch (e) {
      print('❌ Error sending push notification: $e');
      /*   Get.snackbar(
        'ত্রুটি',
        'নোটিফিকেশন পাঠাতে সমস্যা হয়েছে: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      ); */
    }
  }

  /// Sends notification to multiple drivers based on proximity
  Future<void> sendNotificationToNearbyDrivers({
    required LatLng userLocation,
    required Map<String, dynamic> requestData,
    double radiusInKm = 5.0,
  }) async {
    try {
      print('🔍 Looking for nearby drivers within ${radiusInKm}km radius...');

      // Query nearby drivers from Firestore
      final driversSnapshot = await FirebaseFirestore.instance
          .collection('partners')
          .where('role', isEqualTo: 'driver')
          .where('isOnline', isEqualTo: true)
          .get();

      int notificationsSent = 0;

      for (var driverDoc in driversSnapshot.docs) {
        final driverData = driverDoc.data();
        final driverLocation = driverData['currentLocation'];
        final fcmToken = driverData['fcmToken'];

        if (driverLocation != null && fcmToken != null && fcmToken.isNotEmpty) {
          final driverLat = driverLocation['latitude'] as double?;
          final driverLng = driverLocation['longitude'] as double?;

          if (driverLat != null && driverLng != null) {
            // Calculate distance between user and driver
            final distance = Geolocator.distanceBetween(
                  userLocation.latitude,
                  userLocation.longitude,
                  driverLat,
                  driverLng,
                ) /
                1000; // Convert to kilometers

            // Send notification if driver is within radius
            if (distance <= radiusInKm) {
              print(
                  '📍 Found nearby driver: ${driverDoc.id} at ${distance.toStringAsFixed(2)}km');

              await sendNotificationToDriver(
                driverId: driverDoc.id,
                fcmToken: fcmToken,
                requestData: requestData,
              );

              notificationsSent++;
            }
          }
        }
      }

      if (notificationsSent > 0) {
        print('✅ Sent notifications to $notificationsSent nearby drivers');
        /*  Get.snackbar(
          'সফল',
          '$notificationsSent জন ড্রাইভারের কাছে রিকুয়েস্ট পাঠানো হয়েছে',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 4),
        ); */
      } else {
        print('⚠️ No nearby drivers found');
        Get.snackbar(
          'তথ্য',
          'আশেপাশে কোন অনলাইন ড্রাইভার পাওয়া যায়নি',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('❌ Error sending notifications to nearby drivers: $e');
      Get.snackbar(
        'ত্রুটি',
        'আশেপাশের ড্রাইভারদের খুঁজে পেতে সমস্যা হয়েছে',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Example method to send ride request to a specific driver
  Future<void> sendRideRequestToDriver({
    required String driverId,
    String? destinationAddress,
    String? notes,
    String urgency = 'normal',
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        /*   Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন'); */
        return;
      }

      // Get driver's FCM token from Firestore
      final driverDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(driverId)
          .get();

      if (!driverDoc.exists) {
        /*  Get.snackbar('ত্রুটি', 'ড্রাইভার পাওয়া যায়নি'); */
        return;
      }

      final driverData = driverDoc.data();
      final fcmToken = driverData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        /* Get.snackbar('ত্রুটি', 'ড্রাইভারের নোটিফিকেশন টোকেন পাওয়া যায়নি'); */
        return;
      }

      // Create ride request data
      final requestData = {
        'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
        'driverId': driverId,
        'pickupLocation': {
          'latitude': currentPosition.value?.latitude,
          'longitude': currentPosition.value?.longitude,
        },
        'destinationLocation': {
          'latitude': destinationPosition.value?.latitude,
          'longitude': destinationPosition.value?.longitude,
        },
        'pickupAddress':
            'Current Location', // You can get actual address using geocoding
        'destinationAddress': destinationAddress ?? 'Selected Destination',
        'notes': notes ?? '',
        'urgency': urgency,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      };

      // Save request to Firestore
      final requestId = requestData['requestId'] as String;
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(requestId)
          .set({
        ...requestData,
        'userId': currentUser.uid,
        'createdAt': Timestamp.now(),
      });

      // Send push notification to driver
      await sendNotificationToDriver(
        driverId: driverId,
        fcmToken: fcmToken,
        requestData: requestData,
      );
    } catch (e) {
      print('❌ Error sending ride request: $e');
      Get.snackbar(
        'ত্রুটি',
        'রাইড রিকুয়েস্ট পাঠাতে সমস্যা হয়েছে: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Example method to send request to nearby drivers
  Future<void> sendRideRequestToNearbyDrivers({
    String? destinationAddress,
    String? notes,
    String urgency = 'normal',
    double radiusInKm = 5.0,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন');
        return;
      }

      if (currentPosition.value == null) {
        Get.snackbar('ত্রুটি', 'আপনার বর্তমান অবস্থান পাওয়া যায়নি');
        return;
      }

      // Create ride request data
      final requestData = {
        'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
        'pickupLocation': {
          'latitude': currentPosition.value!.latitude,
          'longitude': currentPosition.value!.longitude,
        },
        'destinationLocation': {
          'latitude': destinationPosition.value?.latitude,
          'longitude': destinationPosition.value?.longitude,
        },
        'pickupAddress':
            'Current Location', // You can get actual address using geocoding
        'destinationAddress': destinationAddress ?? 'Selected Destination',
        'notes': notes ?? '',
        'urgency': urgency,
        'timestamp': Timestamp.now(),
        'status': 'pending',
      };

      // Save request to Firestore
      final requestId2 = requestData['requestId'] as String;
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(requestId2)
          .set({
        ...requestData,
        'userId': currentUser.uid,
        'createdAt': Timestamp.now(),
      });

      // Send notifications to nearby drivers
      await sendNotificationToNearbyDrivers(
        userLocation: currentPosition.value!,
        requestData: requestData,
        radiusInKm: radiusInKm,
      );
    } catch (e) {
      print('❌ Error sending ride request to nearby drivers: $e');
    }
  }

  // Profile Image Methods

  // Check if file size is within 2MB limit
  Future<bool> _checkFileSizeLimit(File file) async {
    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) {
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      Get.snackbar(
        'File Too Large',
        'Image size ($fileSizeMB MB) exceeds 2MB limit. Please choose a smaller image or take a new photo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
    return true;
  }

  Future<void> pickAndUploadProfileImage() async {
    try {
      // Request photo library permissions (different for iOS/Android)
      PermissionStatus status;

      if (GetPlatform.isIOS) {
        // iOS: Request photos permission
        status = await Permission.photos.request();
      } else {
        // Android: Request storage permission (works for most Android versions)
        status = await Permission.storage.request();
        // If storage is denied, try photos permission for Android 13+
        if (status.isDenied || status.isPermanentlyDenied) {
          status = await Permission.photos.request();
        }
      }

      if (status.isDenied) {
        Get.snackbar(
          'Permission Required',
          'Photo library access is required to select images. Please grant permission when prompted.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Required',
          'Photo library access is permanently denied. Please enable it in app settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () {
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200, // Further reduced for ultra-fast upload
        maxHeight: 200, // Further reduced for ultra-fast upload
        imageQuality: 50, // Further reduced for ultra-fast upload
      );

      if (image != null) {
        debugPrint('📁 Image selected from gallery: ${image.path}');
        
        // Check file size before processing
        final imageFile = File(image.path);
        if (!await _checkFileSizeLimit(imageFile)) {
          return;
        }
        
        // Always compress image for ultra-fast upload
        final compressedImage = await _ultraFastCompress(imageFile);
        
        // Check again after compression
        if (!await _checkFileSizeLimit(compressedImage)) {
          return;
        }
        
        await uploadProfileImage(compressedImage);
      } else {
        debugPrint('❌ No image selected from gallery');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickAndUploadProfileImageFromCamera() async {
    try {
      // Request camera permission first
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Required',
          'Camera access is required to take photos. Please grant permission in settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 200, // Further reduced for ultra-fast upload
        maxHeight: 200, // Further reduced for ultra-fast upload
        imageQuality: 50, // Further reduced for ultra-fast upload
      );

      if (image != null) {
        debugPrint('📸 Image captured from camera: ${image.path}');
        
        // Check file size before processing
        final imageFile = File(image.path);
        if (!await _checkFileSizeLimit(imageFile)) {
          return;
        }
        
        // Always compress image for ultra-fast upload
        final compressedImage = await _ultraFastCompress(imageFile);
        
        // Check again after compression
        if (!await _checkFileSizeLimit(compressedImage)) {
          return;
        }
        
        await uploadProfileImage(compressedImage);
      } else {
        debugPrint('❌ No image captured from camera');
      }
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
      Get.snackbar(
        'Error',
        'Failed to take photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      isUploadingImage.value = true;
      uploadProgress.value = 0.0; // Reset progress

      // Show immediate feedback
      Get.snackbar(
        'Uploading...',
        'Please wait while we upload your profile image',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        showProgressIndicator: true,
      );

      // Check network connectivity first
      final isConnected = await _isConnected();
      if (!isConnected) {
        Get.snackbar(
          'No Internet',
          'Please check your internet connection and try again.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      // Create a unique filename
      final fileName =
          'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}/$fileName');

      debugPrint('📤 Starting profile image upload: $fileName');

      // Upload the file with optimized settings
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': user.uid,
          },
        ),
      );

      // Monitor upload progress with optimized updates
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        // Only update progress if it's significant change (>1%) to reduce UI updates
        if ((progress - uploadProgress.value).abs() > 0.01) {
          uploadProgress.value = progress;
          debugPrint(
              '📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }
      });

      final snapshot = await uploadTask
          .whenComplete(() => debugPrint('✅ Upload task completed'));

      // Check if upload was successful
      if (snapshot.state == TaskState.success) {
        uploadProgress.value = 1.0; // Complete progress

        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint(
            '🔗 Download URL obtained: ${downloadUrl.substring(0, 50)}...');

        // Update Firestore with the new image URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'profileImageUrl': downloadUrl,
        });

        // Update local state
        profileImageUrl.value = downloadUrl;

        debugPrint('✅ Profile image updated successfully');
        SuccessDialog.show(
          title: 'Profile Updated',
          message: 'Your profile image has been updated successfully!',
        );
      } else {
        throw 'Upload failed with state: ${snapshot.state}';
      }
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');

      // Provide more specific error messages
      String errorMessage = 'Failed to upload profile image. Please try again.';
      if (e.toString().contains('network') ||
          e.toString().contains('unavailable')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
        // Offer retry option for network errors
        Get.snackbar(
          'Upload Failed',
          'Network error occurred. Tap to retry.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          onTap: (snack) {
            debugPrint('🔄 User tapped retry for network error');
            _retryUpload(imageFile);
          },
        );
        return; // Don't show the default error snackbar
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMessage =
            'Permission denied. Please grant storage permissions and try again.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Upload was cancelled.';
        return; // Don't show error snackbar for cancelled uploads
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isUploadingImage.value = false;
      uploadProgress.value = 0.0; // Reset progress
    }
  }

  void showProfileImageOptions() {
    debugPrint('🔄 Opening profile image options bottom sheet');
    Get.bottomSheet(
      Container(
        height: profileImageUrl.value != null
            ? 280
            : 240, // Dynamic height based on content
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // 2 Column Grid Layout
                Row(
                  children: [
                    // Camera Option
                    Expanded(
                      child: _buildOptionCard(
                        icon: Icons.camera_alt,
                        title: 'Take Photo',
                        color: Colors.blue,
                        onTap: () {
                          debugPrint('📷 Camera option selected');
                          Get.back();
                          pickAndUploadProfileImageFromCamera();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Gallery Option
                    Expanded(
                      child: _buildOptionCard(
                        icon: Icons.photo_library,
                        title: 'Gallery',
                        color: Colors.green,
                        onTap: () {
                          debugPrint('🖼️ Gallery option selected');
                          Get.back();
                          pickAndUploadProfileImage();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Remove Option (full width if exists)
                if (profileImageUrl.value != null)
                  _buildOptionCard(
                    icon: Icons.delete,
                    title: 'Remove Picture',
                    color: Colors.red,
                    onTap: () {
                      debugPrint('🗑️ Remove option selected');
                      Get.back();
                      removeProfileImage();
                    },
                    fullWidth: true,
                  ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    debugPrint('❌ Cancel pressed');
                    Get.back();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: false, // Set to false since we have fixed height
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
    ).then((value) => debugPrint('📱 Bottom sheet closed'));
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> removeProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileImageUrl': FieldValue.delete(),
      });

      // Update local state
      profileImageUrl.value = null;

      SuccessDialog.show(
        title: 'Profile Updated',
        message: 'Your profile image has been removed successfully!',
      );
    } catch (e) {
      debugPrint('❌ Error removing profile image: $e');
      Get.snackbar(
        'Error',
        'Failed to remove profile image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Helper method to check network connectivity
  Future<bool> _isConnected() async {
    try {
      // Simple connectivity check by trying to reach a reliable host
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Ultra-fast compression for all images
  Future<File> _ultraFastCompress(File imageFile) async {
    try {
      debugPrint('⚡ Starting ultra-fast compression');

      // Always compress with aggressive settings for speed
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 180, // Optimized size for speed vs quality
        minHeight: 180,
        quality: 45, // Aggressive compression for speed
        rotate: 0, // Skip rotation for speed
      );

      if (compressedBytes != null) {
        // Create a temporary file with compressed data
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/ultra_fast_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(compressedBytes);

        final originalSize = await imageFile.length();
        final compressedSize = await tempFile.length();
        final compressionRatio =
            ((originalSize - compressedSize) / originalSize * 100);
        debugPrint(
            '✅ Ultra-fast compression: ${compressionRatio.toStringAsFixed(1)}% size reduction');

        return tempFile;
      }

      return imageFile; // Return original if compression fails
    } catch (e) {
      debugPrint('❌ Error in ultra-fast compression: $e');
      return imageFile; // Return original on error
    }
  }

  // Retry upload with exponential backoff
  Future<void> _retryUpload(File imageFile,
      {int retryCount = 0, int maxRetries = 3}) async {
    const baseDelay = Duration(seconds: 1);

    try {
      await uploadProfileImage(imageFile);
    } catch (e) {
      if (retryCount < maxRetries &&
          (e.toString().contains('network') ||
              e.toString().contains('unavailable'))) {
        final delay = baseDelay * (1 << retryCount); // Exponential backoff
        debugPrint(
            '🔄 Retrying upload in ${delay.inSeconds} seconds (attempt ${retryCount + 1}/${maxRetries})');

        await Future.delayed(delay);
        return _retryUpload(imageFile,
            retryCount: retryCount + 1, maxRetries: maxRetries);
      } else {
        rethrow; // Re-throw if max retries reached or non-network error
      }
    }
  }

  // Helper methods for fare display
  String _formatFare(dynamic value) {
    try {
      double val;
      if (value is num) {
        val = value.toDouble();
      } else if (value is String) {
        val = double.tryParse(value) ?? 0.0;
      } else {
        return value?.toString() ?? '';
      }

      final fmt =
          NumberFormat.currency(locale: 'bn_BD', symbol: '৳', decimalDigits: 0);
      return fmt.format(val);
    } catch (e) {
      return value?.toString() ?? '';
    }
  }

  // Convert internal fare breakdown keys to simple Bengali labels for normal users
  String _friendlyFareKey(String key) {
    final k = key.toLowerCase();

    if (k.contains('distance')) return 'দূরত্বভিত্তিক চার্জ';
    if (k.contains('time')) return 'সময়ভিত্তিক চার্জ';
    if (k.contains('base')) return 'বেস ভাড়া';
    if (k.contains('surge') || k.contains('multiplier')) return 'সার্জ (গুণক)';
    if (k.contains('urgency')) return 'জরুরি গুণক';
    if (k.contains('additional') || k.contains('extra'))
      return 'অতিরিক্ত চার্জ';
    if (k.contains('subtotal')) return 'সাবটোটাল';
    if (k.contains('total')) return 'মোট';

    // Fallback - return key as-is, but capitalized nicely
    return key[0].toUpperCase() + key.substring(1);
  }

  // Helper to build a labeled row for fare breakdown with consistent styling
  Widget _buildBreakdownRow(String label, String value,
      {Color? valueColor, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to call ambulance
  void _callAmbulance(String? phoneNumber) {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      launchUrl(launchUri);
    } else {
      Get.snackbar(
        'Error',
        'Phone number not available',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // Add notification for user
  Future<void> _addUserNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data ?? {},
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add(notificationData);

      debugPrint('✅ User notification added: $title');
    } catch (e) {
      debugPrint('❌ Failed to add user notification: $e');
    }
  }
}
