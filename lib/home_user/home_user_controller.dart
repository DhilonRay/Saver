import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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
import '../about/about.dart';
import '../user_id/userid.dart';
import '../auth/log_in/login_screen.dart';
import '../chat_page/sos_chat_page.dart';
import '../partner_file/partner_orders/partners_orders_page.dart';
import '../user_order/user_order_page.dart';
import '../services/notification_service.dart';
import '../components/success_dialog.dart';

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

  // Partner rates cache
  var partnerRates = <String, Map<String, int>>{}
      .obs; // partnerId -> {indoorCityRate, outdoorCityRate}

  // Search history variables
  var searchHistory = <String>[].obs;
  static const int _maxHistoryItems = 10;
  var hasStartedTyping =
      false.obs; // Track if user has started typing in current session

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
                'isOnline': isOnline,
              };

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
    super.onClose();
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
    // to the Geocoding REST API which parses more permissively here.
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

          debugPrint(
              'getPlaceDetails: got geometry from Places API: $lat,$lng');

          // Add destination marker and route
          _addDestinationMarkerAndRoute();
          return;
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
      // null -> String inside the library), we'll try the REST geocoding
      // fallback below. Log the stack trace for diagnosis.
      debugPrint('getPlaceDetails: getDetailsByPlaceId threw: $e');
      debugPrint('$st');
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

                      return FutureBuilder<Map<String, int>>(
                        future: _fetchPartnerRates(ambulance.id),
                        builder: (context, rateSnapshot) {
                          final rates = rateSnapshot.data ??
                              {
                                'indoorCityRate': 2500,
                                'outdoorCityRate': 10000
                              };

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
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1976D2)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.local_hospital,
                                            color: Color(0xFF1976D2),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '🚑 $ambulanceType',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '📍 $address',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
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
                                    // Rates Display
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1976D2)
                                            .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: const Color(0xFF1976D2)
                                                .withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Indoor: ৳${rates['indoorCityRate']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1976D2),
                                            ),
                                          ),
                                          Text(
                                            'Outdoor: ৳${rates['outdoorCityRate']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1976D2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
          'indoorCityRate': (data['indoorCityRate'] as int?) ?? 2500,
          'outdoorCityRate': (data['outdoorCityRate'] as int?) ?? 10000,
        };

        // Cache the rates
        partnerRates[partnerId] = rates;

        debugPrint('✅ Fetched partner rates for $partnerId: $rates');
        return rates;
      } else {
        // Use default rates if partner not found
        final defaultRates = {
          'indoorCityRate': 2500,
          'outdoorCityRate': 10000,
        };
        partnerRates[partnerId] = defaultRates;
        debugPrint('ℹ️ Using default rates for partner $partnerId');
        return defaultRates;
      }
    } catch (e) {
      debugPrint('❌ Error fetching partner rates for $partnerId: $e');
      // Return default rates on error
      final defaultRates = {
        'indoorCityRate': 2500,
        'outdoorCityRate': 10000,
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

    // Fetch partner rates first
    final rates = await _fetchPartnerRates(partnerId);

    String selectedUrgency = 'normal'; // normal, urgent, emergency
    String additionalNotes = '';

    final result = await Get.dialog(
      AlertDialog(
        title: Text('Book Ambulance - $companyName'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ambulance Rates Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF1976D2).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🚑 Ambulance Rates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Indoor City:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '৳${rates['indoorCityRate']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Outdoor City:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '৳${rates['outdoorCityRate']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '* Rates may vary based on distance and urgency',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
                      setState(() => selectedUrgency = value);
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
            onPressed: () => Get.back(result: true),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );

    if (result == true) {
      String? orderId = await _createDirectAmbulanceRequest(
        partnerId: partnerId,
        companyName: companyName,
        urgency: selectedUrgency,
        notes: additionalNotes,
      );
      if (orderId == null) {
        // If order creation failed, show error (but success dialog is already handled)
        debugPrint('❌ Order creation failed');
      }
    }
  }

  void _showAmbulanceProviderDetails(Map<String, dynamic> ambulanceData) {
    final partnerId = ambulanceData['id'] as String?;

    // Show ambulance provider details in a very simple bottom sheet
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.local_hospital, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ambulanceData['name'] ?? 'Ambulance Provider',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              // Availability Status
              Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 12),
                  SizedBox(width: 8),
                  Text(
                    'Online & Available',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              if (ambulanceData['address'] != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ambulanceData['address'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
              if (ambulanceData['ambulanceType'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Type: ${ambulanceData['ambulanceType']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text(
                    ambulanceData['phone'] ?? '+8801581822846',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Rates
              if (partnerId != null) ...[
                FutureBuilder<Map<String, int>>(
                  future: _fetchPartnerRates(partnerId),
                  builder: (context, rateSnapshot) {
                    if (rateSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Row(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(width: 8),
                          Text('Loading rates...'),
                        ],
                      );
                    }

                    final rates = rateSnapshot.data ??
                        {'indoorCityRate': 2500, 'outdoorCityRate': 10000};

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Rates',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Indoor City: ৳${rates['indoorCityRate']}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Outdoor City: ৳${rates['outdoorCityRate']}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '* Final rate may vary based on distance and urgency',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20),
              ],

              // Primary Action Button - Book Now (full width, prominent)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    _bookSpecificAmbulance(ambulanceData);
                  },
                  icon: Icon(Icons.book_online),
                  label: Text('Book Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Secondary Actions - Call and Directions side by side
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
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
                            message: 'Calling ${ambulanceData['name']}...',
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
                      icon: Icon(Icons.call),
                      label: Text('Call Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final lat = ambulanceData['latitude'] as double?;
                        final lng = ambulanceData['longitude'] as double?;
                        if (lat != null && lng != null) {
                          destinationPosition.value = LatLng(lat, lng);
                          _addDestinationMarkerAndRoute();
                          Get.back();
                          SuccessDialog.show(
                            title: 'Navigation',
                            message:
                                'Navigating to ${ambulanceData['name']}...',
                          );
                        }
                      },
                      icon: Icon(Icons.directions),
                      label: Text('Directions'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<String?> _createDirectAmbulanceRequest({
    required String partnerId,
    required String companyName,
    required String urgency,
    required String notes,
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
      };

      try {
        await NotificationService.sendAmbulanceNotificationDirect(
          partnerId: partnerId,
          requestData: requestData,
        );
        debugPrint('✅ Ambulance notification sent to partner: $partnerId');
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
          SuccessDialog.show(
            title: 'Request Accepted',
            message: 'An ambulance is on the way! Track its live location.',
          );
        } else if (status == 'in_transit') {
          isTrackingPartner.value = true;
          SuccessDialog.show(
            title: 'Patient Picked Up',
            message:
                'The ambulance has picked up the patient and is now moving. Track its live location.',
          );
        } else if (status == 'completed') {
          isTrackingPartner.value = false;
          partnerLiveLocation.value = null;
          partnerLocationTrail.clear();

          // Clear partner markers and polylines
          markers
              .removeWhere((marker) => marker.markerId.value == 'partner_live');
          polylines.removeWhere(
              (polyline) => polyline.polylineId.value == 'partner_trail');

          SuccessDialog.show(
            title: 'Service Completed',
            message: 'Your ambulance service has been completed.',
          );
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

    final result = await Get.dialog(
      AlertDialog(
        title: Text('Book Ambulance - $companyName'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ambulance Rates Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF1976D2).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🚑 Ambulance Rates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Indoor City:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '৳${rates['indoorCityRate']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Outdoor City:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '৳${rates['outdoorCityRate']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '* Rates may vary based on distance and urgency',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
                      setState(() => selectedUrgency = value);
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
            onPressed: () => Get.back(result: true),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );

    if (result == true) {
      String? orderId = await _createDirectAmbulanceRequest(
        partnerId: partnerId,
        companyName: companyName,
        urgency: selectedUrgency,
        notes: additionalNotes,
      );
      // Success dialog is now shown inside _createDirectAmbulanceRequest
      if (orderId == null) {
        // If order creation failed, show error (but success dialog is already handled)
        debugPrint('❌ Order creation failed');
      }
    }
  }

  void clearMarkers() {
    markers.clear();
    polylines.clear();
    destinationPosition.value = null;
    destinationController.clear();
    placeSuggestions.clear();
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
        // Always compress image for ultra-fast upload
        final compressedImage = await _ultraFastCompress(File(image.path));
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
        // Always compress image for ultra-fast upload
        final compressedImage = await _ultraFastCompress(File(image.path));
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
}
