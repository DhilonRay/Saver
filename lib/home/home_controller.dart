import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:google_maps_webservice/directions.dart' as directions;
import '../about/about.dart';
import '../user_id/userid.dart';
import '../log_in/login_screen.dart';
import '../chat_page/sos_chat_page.dart';
import '../ambulance_service/ambulance_services_page.dart';
import '../partner_orders/partners_orders_page.dart';
import '../user_order/user_order_page.dart';

class HomeController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();
  
  // Google Places API client
  late places.GoogleMapsPlaces _places;
  late directions.GoogleMapsDirections _directions;

  // Reactive variables
  var currentPosition = Rx<LatLng?>(null);
  var destinationPosition = Rx<LatLng?>(null);
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isLoadingLocation = true.obs;
  var mapError = ''.obs;
  
  // Autocomplete variables
  var placeSuggestions = <places.PlacesSearchResult>[].obs;
  var isLoadingSuggestions = false.obs;
  Timer? _debounceTimer;

  // Default position (Dhaka, Bangladesh) in case location fails
  static const LatLng defaultPosition = LatLng(23.8103, 90.4125);

  // Controllers
  final TextEditingController destinationController = TextEditingController();
  
  // Store selected place name for fallback
  String? _selectedPlaceName;

  @override
  void onInit() {
    super.onInit();
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      isLoadingLocation.value = false;
    } catch (e) {
      
      // Use default position if location fails
      currentPosition.value = defaultPosition;
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: currentPosition.value!,
          infoWindow: InfoWindow(title: 'Default Location (Dhaka)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      isLoadingLocation.value = false;
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
    // Clear existing destination marker
    markers.removeWhere((marker) => marker.markerId.value == 'destination');
    
    // Add destination marker
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destinationPosition.value!,
        infoWindow: InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Get directions from Google
    try {    
      final directionsResponse = await _directions.directions(
        directions.Location(lat: currentPosition.value!.latitude, lng: currentPosition.value!.longitude),
        directions.Location(lat: destinationPosition.value!.latitude, lng: destinationPosition.value!.longitude),
        travelMode: directions.TravelMode.driving,
      );

      if (directionsResponse.isOkay) {
        final route = directionsResponse.routes.first;
        final polylinePoints = _decodePolyline(route.overviewPolyline.points);

        // Calculate route information
        String routeInfo = 'Route calculated successfully';
        if (route.legs.isNotEmpty) {
          final leg = route.legs.first;
          String distance = leg.distance.text;
          String duration = leg.duration.text;
          routeInfo = 'Route: $distance, about $duration';
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

        // Update polylines reactively
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue.shade700, // Use a consistent blue color for routes
            width: 6,
            zIndex: 1,
            points: polylinePoints,
          ),
        );

        // Add start marker if not already present
        if (!markers.any((marker) => marker.markerId.value == 'start')) {
          markers.add(
            Marker(
              markerId: const MarkerId('start'),
              position: currentPosition.value!,
              infoWindow: InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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

    // Animate camera if controller is ready
    if (_controller.isCompleted) {
      _controller.future.then((controller) {
        // Calculate bounds to show the entire route
        double minLat = currentPosition.value!.latitude < destinationPosition.value!.latitude
            ? currentPosition.value!.latitude
            : destinationPosition.value!.latitude;
        double maxLat = currentPosition.value!.latitude > destinationPosition.value!.latitude
            ? currentPosition.value!.latitude
            : destinationPosition.value!.latitude;
        double minLng = currentPosition.value!.longitude < destinationPosition.value!.longitude
            ? currentPosition.value!.longitude
            : destinationPosition.value!.longitude;
        double maxLng = currentPosition.value!.longitude > destinationPosition.value!.longitude
            ? currentPosition.value!.longitude
            : destinationPosition.value!.longitude;

        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50), // 50 padding
        );
      });
    }

    Get.snackbar(
      'Route Set',
      'Route to destination has been set successfully',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  // Autocomplete methods
  void onDestinationTextChanged(String query) {
    if (query.isEmpty || query.length < 3) {
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
        // Convert predictions to simple format for display
        placeSuggestions.value = response.predictions.take(6).map((prediction) {
          return places.PlacesSearchResult(
            placeId: prediction.placeId ?? '',
            name: prediction.description ?? 'Unknown Place',
            formattedAddress: prediction.description ?? '',
            geometry: null,
            types: prediction.types,
            reference: prediction.reference ?? '',
          );
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

  void selectPlace(places.PlacesSearchResult place) {
    
    if (place.placeId.isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid destination selected',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }
    
    destinationController.text = place.name;
    placeSuggestions.clear();

    // Store the selected place name for fallback
    _selectedPlaceName = place.name;

    // Get place details to get coordinates
    getPlaceDetails(place.placeId);
  }

  Future<void> getPlaceDetails(String placeId) async {
    
    try {
      places.PlacesDetailsResponse response = await _places.getDetailsByPlaceId(
        placeId,
        fields: ['name', 'formatted_address', 'geometry'],
      );

      

      if (response.isOkay && response.result.geometry != null) {
        LatLng position = LatLng(
          response.result.geometry!.location.lat,
          response.result.geometry!.location.lng,
        );

        
        destinationPosition.value = position;

        // Add destination marker and route
        _addDestinationMarkerAndRoute();
      } else {
        
        Get.snackbar(
          'Destination Not Found',
          'Could not get details for "${_selectedPlaceName ?? "selected destination"}". Try using "Set Route" button or enter a different destination.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: Duration(seconds: 5),
        );
      }
    } catch (e) {
      
      Get.snackbar(
        'Error',
        'Failed to get destination details: $e',
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
      _addDestinationMarkerAndRoute();
      return true;
    }
    
    // Fallback hospitals in Dhaka
    if (query.contains('dhaka') && (query.contains('medical') || query.contains('hospital'))) {
      // Dhaka Medical College Hospital
      destinationPosition.value = LatLng(23.7250, 90.4000);
      destinationController.text = 'Dhaka Medical College Hospital';
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
    Get.to(() => AmbulanceServicesPage());
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

  void retryLocation() {
    _getCurrentLocation();
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
}