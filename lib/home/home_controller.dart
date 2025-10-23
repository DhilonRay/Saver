import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_webservice/places.dart' as places;
import '../aboutus.dart';
import '../userid.dart';
import '../log_in/login_screen.dart';
import '../sos_chat_page.dart';
import '../ambulance_services_page.dart';
import '../partners_orders_page.dart';
import '../user_order_page.dart';

class HomeController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();
  
  // Google Places API client
  late places.GoogleMapsPlaces _places;

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

  @override
  void onInit() {
    super.onInit();
    // Initialize Google Places API client
    _places = places.GoogleMapsPlaces(apiKey: 'AIzaSyA4Ktf1DDkFlYYinXeBRLlW2etfLFLCZVQ');
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
      print('Error getting current location: $e');
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

      // Otherwise, geocode the address
      List<Location> locations =
          await locationFromAddress(destinationController.text);
      if (locations.isNotEmpty) {
        destinationPosition.value =
            LatLng(locations[0].latitude, locations[0].longitude);
        _addDestinationMarkerAndRoute();
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

  void _addDestinationMarkerAndRoute() {
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

    // Update polylines reactively
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

    // Animate camera if controller is ready
    if (_controller.isCompleted) {
      _controller.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(destinationPosition.value!, 14),
        );
      });
    }
  }

  // Autocomplete methods
  void onDestinationTextChanged(String query) {
    if (query.isEmpty) {
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

      // Use Google Places Autocomplete API for real suggestions
      places.PlacesAutocompleteResponse response = await _places.autocomplete(
        query,
        location: currentPosition.value != null
          ? places.Location(lat: currentPosition.value!.latitude, lng: currentPosition.value!.longitude)
          : null,
        radius: 50000, // 50km radius
        language: 'en',
        components: [places.Component('country', 'bd')], // Bangladesh only
      );

      if (response.isOkay && response.predictions.isNotEmpty) {
        // Convert predictions to simple format for display
        placeSuggestions.value = response.predictions.take(6).map((prediction) {
          return places.PlacesSearchResult(
            placeId: prediction.placeId ?? '',
            name: prediction.description ?? 'Unknown Place',
            formattedAddress: '',
            geometry: null,
            types: [],
            reference: prediction.reference ?? '',
          );
        }).toList();
      } else {
        placeSuggestions.clear();
      }
    } catch (e) {
      placeSuggestions.clear();
      print('Error searching places: $e');
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  void selectPlace(places.PlacesSearchResult place) {
    destinationController.text = place.name;
    placeSuggestions.clear();

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

        // Add destination marker
        markers.removeWhere((marker) => marker.markerId.value == 'destination');
        markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: position,
            infoWindow: InfoWindow(title: response.result.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );

        // Animate camera to destination
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: position, zoom: 16),
          ),
        );
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
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