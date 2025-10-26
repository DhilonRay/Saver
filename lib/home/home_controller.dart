import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:google_maps_webservice/directions.dart' as directions;
import 'package:url_launcher/url_launcher.dart';
import '../about/about.dart';
import '../user_id/userid.dart';
import '../auth/log_in/login_screen.dart';
import '../chat_page/sos_chat_page.dart';
import '../partner_orders/partners_orders_page.dart';
import '../user_order/user_order_page.dart';

class HomeController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();
  
  // Custom marker icons
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  BitmapDescriptor personIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor ambulanceIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor hospitalIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  BitmapDescriptor selectedHospitalIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  
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
  
  // Autocomplete variables
  var placeSuggestions = <Map<String, dynamic>>[].obs;
  var isLoadingSuggestions = false.obs;
  Timer? _debounceTimer;

  // Reactive query string mirroring the TextEditingController
  var destinationQuery = ''.obs;

  // Ambulance visibility control
  var showAmbulances = false.obs;

  // Search history variables
  var searchHistory = <String>[].obs;
  static const int _maxHistoryItems = 10;
  var hasStartedTyping = false.obs; // Track if user has started typing in current session

  // Default position (Dhaka, Bangladesh) in case location fails
  static const LatLng defaultPosition = LatLng(23.8103, 90.4125);

  // Controllers
  final TextEditingController destinationController = TextEditingController();
  
  BitmapDescriptor _getDestinationIcon() {
    final query = destinationQuery.value.toLowerCase();

    // Check for ambulance-related searches
    if (query.contains('ambulance') || query.contains('emergency') || query.contains('emergency services')) {
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
      debugPrint('🔍 Loading ambulance providers from database...');

      // Clear existing markers first
      markers.removeWhere((marker) => marker.markerId.value.startsWith('ambulance_'));

      // Fetch ambulance providers from Firestore
      final partnersSnapshot = await FirebaseFirestore.instance
          .collection('partners')
          .get();

      debugPrint('🚑 Found ${partnersSnapshot.docs.length} ambulance providers in database');

      // Only add ambulance markers if showAmbulances is true
      if (showAmbulances.value) {
        for (var doc in partnersSnapshot.docs) {
          final data = doc.data();
          final latitude = data['latitude'] as double?;
          final longitude = data['longitude'] as double?;
          final name = data['name'] as String? ?? 'Ambulance Provider';
          final phone = data['phone'] as String?;
          final address = data['address'] as String?;
          final ambulanceType = data['ambulanceType'] as String?;

          if (latitude != null && longitude != null) {
            debugPrint('🚑 Adding ambulance provider: $name at ($latitude, $longitude)');

            // Create a custom ambulance data object to pass to details
            final ambulanceData = {
              'id': doc.id,
              'name': name,
              'phone': phone ?? '+8801581822846',
              'address': address ?? 'Address not available',
              'ambulanceType': ambulanceType ?? 'General Ambulance',
              'latitude': latitude,
              'longitude': longitude,
            };

            markers.add(
              Marker(
                markerId: MarkerId('ambulance_${doc.id}'),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: name,
                  snippet: address ?? 'Ambulance Service',
                  onTap: () => _showAmbulanceProviderDetails(ambulanceData),
                ),
                icon: ambulanceIcon,
                onTap: () => _showAmbulanceProviderDetails(ambulanceData),
              ),
            );
          }
        }
      }

      debugPrint('✅ Ambulance providers loaded successfully');
    } catch (e) {
      debugPrint('❌ Failed to load ambulance providers: $e');
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
      personIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      ambulanceIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      hospitalIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      selectedHospitalIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      currentLocationIcon = personIcon;
    }
  }



  @override
  void onInit() {
    super.onInit();
    _loadCustomIcons();
    // Initialize Google Places API client
    _places = places.GoogleMapsPlaces(apiKey: 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o');
    _directions = directions.GoogleMapsDirections(apiKey: 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o');
    _getCurrentLocation();
  }

  @override
  void onClose() {
    destinationController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
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
        if (query.contains('medical') || query.contains('hospital') || query.contains('clinic')) {
          // Search for hospitals in Khulna
        destinationController.text = 'hospitals in Khulna';
        destinationQuery.value = 'hospitals in Khulna';
        } else {
          destinationPosition.value = LatLng(22.8456, 89.5403); // Khulna coordinates
          _addDestinationMarkerAndRoute();
          return;
        }
      }
      
      // Handle Dhaka searches
      if (query.contains('dhaka')) {
        if (query.contains('medical') || query.contains('hospital') || query.contains('clinic')) {
          // Search for hospitals in Dhaka
        destinationController.text = 'hospitals in Dhaka';
        destinationQuery.value = 'hospitals in Dhaka';
        } else {
          destinationPosition.value = LatLng(23.8103, 90.4125); // Dhaka coordinates
          _addDestinationMarkerAndRoute();
          return;
        }
      }

      // For hospital searches, make the query more specific
      if (query.contains('medical') || query.contains('hospital') || query.contains('clinic')) {
        // Keep the query as is for Google Places to find hospitals
      }

      // Try fallback hospitals if it's a hospital search in Khulna/Dhaka
      if (_tryFallbackHospitals(query)) {
        return;
      }

      // Otherwise, use autocomplete to find the place
      places.PlacesAutocompleteResponse autoResponse = await _places.autocomplete(
        destinationController.text,
        language: 'en',
        components: [places.Component(places.Component.country, 'bd')], // Restrict to Bangladesh
        types: [], // Allow all types but prioritize hospitals
      );

      if (autoResponse.isOkay && autoResponse.predictions.isNotEmpty) {
        // Get details for the first prediction
        var prediction = autoResponse.predictions.first;
        places.PlacesDetailsResponse detailResponse = await _places.getDetailsByPlaceId(
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
        directions.Location(lat: currentPosition.value!.latitude, lng: currentPosition.value!.longitude),
        directions.Location(lat: destinationPosition.value!.latitude, lng: destinationPosition.value!.longitude),
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
        Get.snackbar(
          'Navigation Ready',
          routeInfo,
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade800,
          duration: Duration(seconds: 4),
          icon: Icon(Icons.directions, color: Colors.blue.shade800),
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
              color: Colors.blue.shade700, // Use a consistent blue color for routes
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
        final mapController = await _controller.future.timeout(const Duration(seconds: 5));

        // Calculate bounds to show the entire route
        // Animate camera to fit both current location and destination.
        try {
          // Always ensure southwest is the min lat/lng and northeast is the max lat/lng
          final double minLat = currentPosition.value!.latitude < destinationPosition.value!.latitude
              ? currentPosition.value!.latitude
              : destinationPosition.value!.latitude;
          final double maxLat = currentPosition.value!.latitude > destinationPosition.value!.latitude
              ? currentPosition.value!.latitude
              : destinationPosition.value!.latitude;
          final double minLng = currentPosition.value!.longitude < destinationPosition.value!.longitude
              ? currentPosition.value!.longitude
              : destinationPosition.value!.longitude;
          final double maxLng = currentPosition.value!.longitude > destinationPosition.value!.longitude
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
        components: [places.Component(places.Component.country, 'bd')], // Restrict to Bangladesh
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
      debugPrint('getPlaceDetails: calling Places.getDetailsByPlaceId for $placeId');
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

          debugPrint('getPlaceDetails: got geometry from Places API: $lat,$lng');

          // Add destination marker and route
          _addDestinationMarkerAndRoute();
          return;
        } catch (e, st) {
          // Log and fall through to fallback below
          debugPrint('getPlaceDetails: parsing geometry failed: $e');
          debugPrint('$st');
        }
      } else {
        debugPrint('getPlaceDetails: Places result had no geometry or not OK (status: ${response.status})');
      }
    } catch (e, st) {
      // If calling getDetailsByPlaceId throws (for example a type cast from
      // null -> String inside the library), we'll try the REST geocoding
      // fallback below. Log the stack trace for diagnosis.
      debugPrint('getPlaceDetails: getDetailsByPlaceId threw: $e');
      debugPrint('$st');
    }

    // --- Fallback: Use Google Geocoding REST API with the selected place name ---
    final String addressForGeocoding = _selectedPlaceName ?? destinationController.text;
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
      debugPrint('getPlaceDetails: falling back to Geocoding for "$addressForGeocoding"');
      final apiKey = _places.apiKey ?? ''; // reuse the key from places client
      final uri = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(addressForGeocoding)}&key=$apiKey');
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      final respBody = await response.transform(utf8.decoder).join();
      httpClient.close();

      final Map<String, dynamic> json = jsonDecode(respBody) as Map<String, dynamic>;
      final status = (json['status'] as String?) ?? '';
      if (status == 'OK' && (json['results'] is List) && (json['results'] as List).isNotEmpty) {
        final first = (json['results'] as List).first as Map<String, dynamic>;
        final geometry = first['geometry'] as Map<String, dynamic>?;
        final location = geometry?['location'] as Map<String, dynamic>?;
        final lat = location?['lat'];
        final lng = location?['lng'];
        debugPrint('Geocoding result: lat=$lat, lng=$lng, address=${first['formatted_address'] ?? ''}');
        if (lat != null && lng != null) {
          destinationPosition.value = LatLng((lat as num).toDouble(), (lng as num).toDouble());
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
      debugPrint('getPlaceDetails: Geocoding fallback returned no results or no location');
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
    if (query.contains('khulna') && (query.contains('medical') || query.contains('hospital'))) {
      // Khulna Medical College Hospital
      destinationPosition.value = LatLng(22.8200, 89.5510);
  destinationController.text = 'Khulna Medical College Hospital';
  destinationQuery.value = 'Khulna Medical College Hospital';
      _addDestinationMarkerAndRoute();
      return true;
    }
    
    // Fallback hospitals in Dhaka
    if (query.contains('dhaka') && (query.contains('medical') || query.contains('hospital'))) {
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
    // Toggle ambulance visibility instead of navigating to new page
    showAmbulances.value = !showAmbulances.value;
    _addNearbyMarkers(); // Reload markers with new ambulance visibility
  }

  void _showAmbulanceProviderDetails(Map<String, dynamic> ambulanceData) {
    // Show ambulance provider details in a bottom sheet
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.red, size: 30),
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
              SizedBox(height: 12),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.phone, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Number:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      ambulanceData['phone'] ?? '+8801581822846',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final String numberToCall = ambulanceData['phone'] ?? '+8801581822846';
                      final Uri launchUri = Uri(
                        scheme: 'tel',
                        path: numberToCall,
                      );
                      try {
                        await launchUrl(launchUri);
                        Get.snackbar(
                          'Call Ambulance',
                          'Calling ${ambulanceData['name']}...',
                          backgroundColor: Colors.green.shade100,
                          colorText: Colors.green.shade800,
                        );
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'Unable to make call. Please dial $numberToCall manually.',
                          backgroundColor: Colors.red.shade100,
                          colorText: Colors.red.shade800,
                        );
                      }
                      Get.back(); // Close bottom sheet
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
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to ambulance location
                      final lat = ambulanceData['latitude'] as double?;
                      final lng = ambulanceData['longitude'] as double?;
                      if (lat != null && lng != null) {
                        // Set destination and navigate
                        destinationPosition.value = LatLng(lat, lng);
                        _addDestinationMarkerAndRoute();
                        Get.back(); // Close bottom sheet
                        Get.snackbar(
                          'Navigation',
                          'Navigating to ${ambulanceData['name']}...',
                          backgroundColor: Colors.blue.shade100,
                          colorText: Colors.blue.shade800,
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
      isScrollControlled: true,
    );
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
}