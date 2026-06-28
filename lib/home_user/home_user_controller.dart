import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' show FirebaseStorage, TaskState;
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp; // Keep Timestamp for type checks
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:google_maps_webservice/directions.dart' as directions;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:saver/compo/success_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../about/about.dart';
import '../user_id/userid.dart';
import '../glm_dashboard/glm_dashboard.dart';
import '../auth/log_in/login_screen.dart';
import '../chat_page/sos_chat_page.dart';
import '../partner_file/partner_orders/partners_orders_page.dart';
import '../user_order/user_order_page.dart';
import '../services/notification_service.dart';

import '../user_tracking/user_tracking_page.dart';
import '../services/fares_service.dart';
import '../widgets/fares_widgets.dart';
import 'package:saver/components/constants/alert.dart';
import '../config/api_keys.dart';
import '../../services/supabase_service.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
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
  var currentAddress = 'Finding location...'.obs;
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
  StreamSubscription<List<Map<String, dynamic>>>? _orderSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _partnersSubscription;
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
  var showAmbulances = false.obs; // Hide ambulances by default

  // User name
  var userName = 'NeoSaver'.obs;

  // Profile image
  var profileImageUrl = Rx<String?>(null);
  var isUploadingImage = false.obs;
  var uploadProgress = 0.0.obs; // Upload progress (0.0 to 1.0)

  // Maximum file size in bytes (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

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

  // Track if we've shown the no nearby ambulance popup
  bool _hasShownNoAmbulancePopup = false;

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
      debugPrint(
          '🔍 Updating ambulance providers markers (showAmbulances: ${showAmbulances.value})...');

      // Cancel existing subscription if any
      await _partnersSubscription?.cancel();
      _partnersSubscription = null;

      // Clear existing markers regardless (to ensure we don't have artifacts)
      markers.removeWhere(
          (marker) => marker.markerId.value.startsWith('ambulance_'));
      onlineAmbulances.clear();

      // IF showAmbulances is false, we just stay cleared and return
      if (!showAmbulances.value) {
        debugPrint('🚑 showAmbulances is false - markers cleared.');
        return;
      }

      // Set up real-time listener for ambulance providers
      _partnersSubscription = SupabaseService.client
          .from('partners')
          .stream(primaryKey: ['id'])
          .eq('is_online', true)
          .listen((partnersList) {
        debugPrint(
            '🚑 Real-time update: Found ${partnersList.length} online ambulance providers');

        // Clear existing ambulance markers
        markers.removeWhere(
            (marker) => marker.markerId.value.startsWith('ambulance_'));

        // Build a simple list of online ambulances for UI (drawer quick-access)
        final List<Map<String, dynamic>> onlineList = [];

        for (var item in partnersList) {
          final data = SupabaseService.toCamelCase(item);
          final latitude = data['latitude'] as double?;
          final longitude = data['longitude'] as double?;
          final companyName = data['companyName'] as String? ?? 'Ambulance Service';
          final driverName = data['name'] as String? ?? 'Driver';
          final phone = data['phone'] as String? ?? data['contact'] as String?;
          final address = data['address'] as String? ?? data['coverageArea'] as String?;
          final ambulanceType = data['ambulanceType'] as String?;
          final isOnline = data['isOnline'] as bool? ?? false;
          final lastUpdated = data['lastUpdated'] as Timestamp?;
          
          // Check if the provider is recently active (within last 5 minutes)
          // This prevents showing drivers who closed the app without going offline
          bool isRecentlyActive = true;
          if (lastUpdated != null) {
            final difference = DateTime.now().difference(lastUpdated.toDate());
            if (difference.inMinutes > 5) {
              isRecentlyActive = false;
            }
          }

          // Only show online partners with valid location and recent activity
          if (latitude != null && longitude != null && isOnline && isRecentlyActive) {
            // Create a custom ambulance data object to pass to details
            final ambulanceData = {
              'id': doc.id,
              'name': driverName,
              'driverName': driverName,
              'companyName': companyName,
              'phone': phone ?? '+8801581822846',
              'address': address ?? 'Coverage area not specified',
              'ambulanceType': ambulanceType ?? 'General Ambulance',
              'latitude': latitude,
              'longitude': longitude,
              'ambulanceImageUrl': data['ambulanceImageUrl'] as String?,
              'profileImageUrl': data['profileImageUrl'] as String?,
              'licenseNumber': data['licenseNumber'] as String? ?? 'N/A',
              'vehicleNumber': data['vehicleNumber'] as String? ?? 'N/A',
              'isOnline': isOnline,
            };

            // Add a compact representation to the list visible in drawer
            onlineList.add({
              'id': doc.id,
              'name': driverName,
              'driverName': driverName,
              'companyName': companyName,
              'phone': phone ?? '+8801793399913',
              'address': address ?? 'Coverage area not specified',
              'ambulanceType': ambulanceType ?? 'General Ambulance',
              'ambulanceImageUrl': data['ambulanceImageUrl'] as String?,
              'profileImageUrl': data['profileImageUrl'] as String?,
              'licenseNumber': data['licenseNumber'] as String? ?? 'N/A',
              'vehicleNumber': data['vehicleNumber'] as String? ?? 'N/A',
              'latitude': latitude,
              'longitude': longitude,
              'isOnline': isOnline,
            });

            markers.add(
              Marker(
                markerId: MarkerId('ambulance_${doc.id}'),
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                  title: '$companyName (Online)',
                  snippet: '🚑 $ambulanceType • Tap for details',
                  onTap: () => _showAmbulanceProviderDetails(ambulanceData),
                ),
                icon: ambulanceIcon,
                onTap: () => _showAmbulanceProviderDetails(ambulanceData),
              ),
            );
          }
        }

        // Update the reactive list
        onlineAmbulances.assignAll(onlineList);
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
        const ImageConfiguration(size: Size(45, 45)),
        'assets/images/pin-map.png',
      );
      ambulanceIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/images/ambulance.png',
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
    WidgetsBinding.instance.addObserver(this);
    _loadCustomIcons();
    // Watch for ambulance visibility toggle
    ever(showAmbulances, (_) => _addNearbyMarkers());
    // Initialize Google Places API client
    _places = places.GoogleMapsPlaces(
        apiKey: ApiKeys.googleMapsApiKey);
    _directions = directions.GoogleMapsDirections(
        apiKey: ApiKeys.googleMapsApiKey);
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
    WidgetsBinding.instance.removeObserver(this);
    destinationController.dispose();
    _debounceTimer?.cancel();
    _locationUpdateTimer?.cancel(); // Cancel location update timer
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getCurrentLocation();
    }
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
      _getAddressFromLatLng(newPosition);

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

      debugPrint(
          '📍 User location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Error updating user location: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await SupabaseService.getUser(user.uid);
        if (userDoc != null) {
          final userData = SupabaseService.toCamelCase(userDoc);
          userName.value = userData['name'] ?? user.displayName ?? 'NeoSaver';
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
        final userDoc = await SupabaseService.getUser(user.uid);
        if (userDoc != null) {
          final userData = SupabaseService.toCamelCase(userDoc);
          profileImageUrl.value = userData['profileImageUrl'];
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
          Alert.error(
              'Location permission is required to show your location on the map');
          isLoadingLocation.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Alert.error(
            'Location permission is permanently denied. Please enable it in settings.');
        isLoadingLocation.value = false;
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition.value = LatLng(position.latitude, position.longitude);
      _getAddressFromLatLng(currentPosition.value!);

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

      // One-time check for nearby ambulances to show popup
      if (!_hasShownNoAmbulancePopup && currentPosition.value != null) {
        _checkNearbyAmbulances(currentPosition.value!);
      }

      isLoadingLocation.value = false;
      // initial loading finished
      isInitialLoading.value = false;
    } catch (e) {
      // Use default position if location fails
      currentPosition.value = defaultPosition;
      _getAddressFromLatLng(defaultPosition);
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

      // One-time check for nearby ambulances to show popup
      if (!_hasShownNoAmbulancePopup && currentPosition.value != null) {
        _checkNearbyAmbulances(currentPosition.value!);
      }

      isLoadingLocation.value = false;
      // initial loading finished (even on error)
      isInitialLoading.value = false;
    }
  }

  Future<void> _checkNearbyAmbulances(LatLng position) async {
    try {
      final list = await SupabaseService.query(
        'partners',
        filters: {'is_online': true},
      );

      bool foundNearby = false;
      for (var item in list) {
        final data = SupabaseService.toCamelCase(item);
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        
        // Also check if recently active
        final lastUpdated = data['lastUpdated'];
        bool isRecentlyActive = true;
        if (lastUpdated != null) {
          final parsedDate = DateTime.tryParse(lastUpdated.toString());
          if (parsedDate != null) {
            final difference = DateTime.now().difference(parsedDate);
            if (difference.inMinutes > 5) {
              isRecentlyActive = false;
            }
          }
        }
        
        if (lat != null && lng != null && isRecentlyActive) {
          double distance = Geolocator.distanceBetween(
              position.latitude, position.longitude, lat, lng);
          if (distance <= 20000) { // 20km
            foundNearby = true;
            break;
          }
        }
      }

      if (!foundNearby) {
        _hasShownNoAmbulancePopup = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (Get.isDialogOpen == false) {
            Get.dialog(
              AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'কাছাকাছি অ্যাম্বুলেন্স নেই',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'আপনার আশেপাশে ২০ কিলোমিটারের মধ্যে কোনো সক্রিয় অ্যাম্বুলেন্স পাওয়া যায়নি। জরুরি প্রয়োজনে কল সেন্টারে যোগাযোগ করুন অথবা দূরের অ্যাম্বুলেন্স বুক করুন।',
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('ঠিক আছে',
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              barrierDismissible: true,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking nearby ambulances: $e');
    }
  }

  Future<void> setDestinationMarker() async {
    if (destinationController.text.isEmpty) {
      Alert.error('Please enter a destination');
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
          Alert.error('Could not get details for the destination');
        }
      } else {
        Alert.error('Could not find the destination location');
      }
    } catch (e) {
      Alert.error('Failed to set destination: $e');
    }
  }

  Future<void> _addDestinationMarkerAndRoute() async {
    // Check if positions are available
    if (currentPosition.value == null || destinationPosition.value == null) {
      Alert.error('Location information is not available. Please try again.');
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

    // After setting destination, show ambulances
    showAmbulances.value = true;

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
          Alert.info(
              'Using approximate straight-line route because detailed directions were not available.');
        }

        // Start marker is already represented by 'currentLocation' marker
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
        Alert.info(
            'Using approximate route. Actual driving directions may vary.');
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

      // Clear map state when query is cleared
      destinationPosition.value = null;
      polylines.clear();
      markers.removeWhere((marker) => marker.markerId.value == 'destination');

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
      Alert.error('Invalid destination selected');
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

    // Dismiss keyboard
    if (Get.context != null) {
      FocusScope.of(Get.context!).unfocus();
    }
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

    // Dismiss keyboard
    if (Get.context != null) {
      FocusScope.of(Get.context!).unfocus();
    }
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
      Alert.error(
          'Could not get details for the selected destination. Try entering a different destination.');
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
          Alert.info('Resolved: lat=$lat, lng=$lng');
          _addDestinationMarkerAndRoute();
          return;
        }
      }

      // If we reach here, fallback failed
      debugPrint(
          'getPlaceDetails: Geocoding fallback returned no results or no location');
      Alert.error(
          'Could not get details for "${_selectedPlaceName ?? addressForGeocoding}". Try using the "Set Route" button or enter a different destination.');
    } catch (e) {
      debugPrint('getPlaceDetails: Geocoding fallback failed: $e');
      Alert.error(
          'Failed to get destination details. Check your network or try another destination.');
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.client
                    .from('partners')
                    .stream(primaryKey: ['id'])
                    .eq('is_online', true),
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

                  final rawAmbulances = snapshot.data ?? [];
                  final ambulances = rawAmbulances.map((item) => SupabaseService.toCamelCase(item)).toList();

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
                      final data = ambulances[index];
                      final name = data['companyName'] ?? 'Ambulance Provider';
                      final phone = data['contact'] ?? '+8801581822846';
                      final address =
                          data['coverageArea'] ?? 'Coverage area not specified';
                      final ambulanceType =
                          data['ambulanceType'] ?? 'General Ambulance';
                      final latitude = data['latitude'] as double?;
                      final longitude = data['longitude'] as double?;
                      // ignore: unused_local_variable
                      final profileImageUrl =
                          data['profileImageUrl'] as String?;
                      final ambulanceImageUrl =
                          data['ambulanceImageUrl'] as String?;

                      return FutureBuilder<Map<String, int>>(
                        future: _fetchPartnerRates(ambulance.id),
                        builder: (context, rateSnapshot) {
                          // Rates no longer displayed in list - calculated during booking
                          // final rates = rateSnapshot.data ??
                          //     {
                          //       'serviceRate': 2500,
                          //     };

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _showAmbulanceBookingDialog(
                                data['id'] ?? data['uid'] ?? '',
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Ambulance Name with number
                                    Text(
                                      '${index + 1}.$name',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Location Row
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Ambulance Type Row
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_hospital,
                                          color: Colors.red[400],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ambulanceType,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Photo Row
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.photo_camera,
                                          color: Colors.amber[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Photo ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          '(ambulance)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Ambulance Photo Placeholder
                                    if (ambulanceImageUrl != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          ambulanceImageUrl,
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.local_shipping,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      Container(
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.local_shipping,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),

                                    // Show fare estimation if destination is set
                                    if (currentPosition.value != null &&
                                        destinationPosition.value != null) ...[
                                      const SizedBox(height: 12),
                                      FutureBuilder<Map<String, int>>(
                                        future:
                                            _fetchPartnerRates(ambulance.id),
                                        builder: (context, rateSnapshot) {
                                          if (rateSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(
                                              height: 40,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              ),
                                            );
                                          }

                                          final distance =
                                              FareCalculationService
                                                  .calculateDistance(
                                            currentPosition.value!.latitude,
                                            currentPosition.value!.longitude,
                                            destinationPosition.value!.latitude,
                                            destinationPosition
                                                .value!.longitude,
                                          );

                                          return RideDetailsWidget(
                                            pickupAddress: currentAddress.value,
                                            destinationAddress:
                                                destinationQuery.value,
                                            distance: distance,
                                            estimatedTime: (distance * 2) + 5,
                                          );
                                        },
                                      ),
                                    ],
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

      // Fetch from Supabase
      final doc = await SupabaseService.getPartner(partnerId);

      if (doc != null) {
        final data = SupabaseService.toCamelCase(doc);
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
      Alert.error('You need to be logged in to place an order.');
      return;
    }

    final partnerId = ambulanceData['id'] as String?;
    final companyName =
        ambulanceData['companyName'] as String? ?? 'Ambulance Provider';
    final driverName =
        ambulanceData['driverName'] as String? ?? 'Ambulance Driver';

    if (partnerId == null) {
      Alert.error('Invalid ambulance provider selected.');
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
                            companyName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: ambulanceData['profileImageUrl'] != null 
                                  ? NetworkImage(ambulanceData['profileImageUrl'])
                                  : null,
                                child: ambulanceData['profileImageUrl'] == null 
                                  ? const Icon(Icons.person, size: 12) 
                                  : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                driverName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.purple.shade100),
                                ),
                                child: Text(
                                  'License: ${ambulanceData['licenseNumber'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.teal.shade100),
                                ),
                                child: Text(
                                  'No: ${ambulanceData['vehicleNumber'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                              ),
                            ],
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

                // Ride Details Section (Distance and Time only, no fare initially)
                if (estimatedFare != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: RideDetailsWidget(
                      pickupAddress: currentAddress.value,
                      destinationAddress:
                          _selectedPlaceName ?? destinationQuery.value,
                      distance: estimatedFare.distance,
                      estimatedTime: estimatedFare.estimatedTime,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Actions
                Column(
                  children: [
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
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
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 160,
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
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
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.15)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                    // Company Name (Prominent at Top)
                    Text(
                      ambulanceData['companyName'] ?? 'Ambulance Service',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Driver Info Row
                    Row(
                      children: [
                        // Driver Photo
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.blue.shade100, width: 2),
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
                                  Icons.person,
                                  color: Colors.blue.shade600,
                                  size: 30,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ambulanceData['driverName'] ??
                                    ambulanceData['name'] ??
                                    'Driver',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Available',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (ambulanceData['ambulanceType'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        ambulanceData['ambulanceType'],
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
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

                          // License Number
                          if (ambulanceData['licenseNumber'] != null)
                            _buildSimpleInfoRow(
                              Icons.assignment,
                              Colors.purple.shade600,
                              'License',
                              ambulanceData['licenseNumber'],
                            ),

                          if (ambulanceData['licenseNumber'] != null)
                            SizedBox(height: 12),

                          // Vehicle Number
                          if (ambulanceData['vehicleNumber'] != null)
                            _buildSimpleInfoRow(
                              Icons.grid_3x3,
                              Colors.teal.shade600,
                              'Vehicle No',
                              ambulanceData['vehicleNumber'],
                            ),

                          if (ambulanceData['vehicleNumber'] != null)
                            SizedBox(height: 12),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Action Buttons
                    // Book Now - Primary Action (Full Width)
                    SizedBox(
                      width: double.infinity,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                        Alert.info('Emergency number copied to clipboard');
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
          bool launched =
              await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched) {
            Alert.error('Unable to open the phone dialer on this device.');
          }
        } else {
          Alert.error('Unable to open the phone dialer on this device.');
        }
      } else if (status.isPermanentlyDenied) {
        Alert.error(
            'Phone call permission is permanently denied. Please enable it in app settings.');
        // Open app settings
        await openAppSettings();
      } else {
        Alert.error('Phone call permission is required to make calls.');
      }
    } catch (e) {
      debugPrint('Failed to launch dialer: $e');
      Alert.error('Failed to start call. Please manually dial $phoneNumber');
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
    String? userId;
    Map<String, dynamic> userData = {};

    try {
      final prefs = await SharedPreferences.getInstance();
      bool isGLM = prefs.getBool('isGLMLoggedIn') ?? false;
      String? glmId = prefs.getString('currentGLMId');

      if (isGLM && glmId != null) {
        userId = glmId;
        final glmDoc = await SupabaseService.client
            .from('glm_accounts')
            .select()
            .eq('id', glmId)
            .maybeSingle();
        if (glmDoc != null) {
          final data = SupabaseService.toCamelCase(glmDoc);
          userData = {
            'name': data['hospitalName'] ?? data['fullName'] ?? 'GLM Partner',
            'phone': data['phone'] ?? 'N/A',
            'email': data['email'] ?? 'N/A',
          };
        } else {
          userData = {
            'name': 'GLM Partner',
            'phone': 'N/A',
            'email': 'N/A',
          };
        }
      } else {
        userId = _auth.currentUser?.uid;
        if (userId == null) {
          Alert.error('User not authenticated');
          return null;
        }
        final userDoc = await SupabaseService.getUser(userId);
        userData = userDoc != null ? SupabaseService.toCamelCase(userDoc) : {};
      }
    } catch (e) {
      debugPrint('Error retrieving user session: $e');
      Alert.error('Session retrieval failed');
      return null;
    }

    try {

      // Check if user already has a pending ambulance request to this specific partner
      final existingRequests = await SupabaseService.query(
        'orders',
        filters: {
          'user_id': userId,
          'partner_id': partnerId,
          'type': 'ambulance',
          'status': 'pending',
        },
      );

      if (existingRequests.isNotEmpty) {
        Alert.info(
          'You already have a pending ambulance request to this partner. Please wait for them to accept or decline before submitting a new request.',
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

      final orderId = await SupabaseService.createOrder({
        'userId': userId,
        'partnerId': partnerId,
        'companyName': companyName,
        'urgency': urgency,
        'notes': notes,
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
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
        'totalAmount': 0.0, // Initial amount is 0 for bidding
        'negotiation': {
          'status': 'user_requested',
          'driverAccepted': false,
          'userAccepted': false,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      });

      // Start listening for driver offers for this specific order
      _listenToOrderNegotiation(orderId, partnerId);

      debugPrint('✅ Order created successfully with ID: $orderId');

      // Show success dialog immediately after order creation
      SuccessDialog.show(
        title: 'Order Created',
        message: 'Your ambulance request has been submitted successfully.',
      );

      // Send notification to ambulance partner (don't fail the request if this fails)
      final requestData = {
        'orderId': orderId,
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
          message:
              'আপনার অ্যাম্বুলেন্স অনুরোধ সফলভাবে পাঠানো হয়েছে। পার্টনার খুব শীঘ্রই আপনার সাথে যোগাযোগ করবে।',
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
      Alert.error(
        'Failed to send request: $e',
      );
      return null;
    }
  }

  void _listenToOrderNegotiation(String orderId, String partnerId) {
    debugPrint('📡 Listening for negotiation updates for order: $orderId');
    SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .listen((list) {
      if (list.isEmpty) return;

      final data = SupabaseService.toCamelCase(list.first);
      final negotiation = data['negotiation'] as Map<String, dynamic>? ?? {};
      final status = negotiation['status'] as String? ?? '';
      final counterBy = negotiation['counterBy'] as String? ?? '';
      final counterFare =
          (negotiation['counterFare'] as num?)?.toDouble() ?? 0.0;

      // If driver sent an offer, navigate to negotiation page
      if (status == 'counter' && counterBy == 'driver' && counterFare > 0) {
        debugPrint(
            '💰 Driver offered fare: $counterFare. Navigating to negotiation page...');

        // Prevent multiple navigations if already on the page
        if (Get.currentRoute != '/fare-negotiation') {
          Get.toNamed('/fare-negotiation', arguments: {
            'requestId': orderId,
            'driverId': partnerId,
            'fare': counterFare,
          });
        }
      }
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        currentAddress.value =
            "${place.street}, ${place.subLocality}, ${place.locality}";
        debugPrint('📍 Resolved address: ${currentAddress.value}');
      }
    } catch (e) {
      debugPrint('❌ Error resolving address: $e');
      currentAddress.value = "Unknown Location";
    }
  }

  void listenForRequestUpdates(String orderId) {
    // Cancel any existing subscription
    _orderSubscription?.cancel();

    // Set current tracking order ID
    currentTrackingOrderId.value = orderId;

    // Listen for order updates
    _orderSubscription = SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .listen((list) {
      if (list.isNotEmpty) {
        final data = SupabaseService.toCamelCase(list.first);
        final status = data?['orderStatus'] ?? data?['status'];

        // Handle status updates
        if (status == 'fare_proposed') {
          // Driver has proposed a fare - show it to the user
          final driverFare = data?['driverFare'] as double?;
          final driverName = data?['driverName'] as String? ?? 'ড্রাইভার';
          if (driverFare != null) {
            _showFareProposalBottomSheet(
              orderId: orderId,
              driverFare: driverFare,
              driverName: driverName,
              pickupAddress: data?['pickupAddress'] as String?,
              destinationAddress: data?['destinationAddress'] as String?,
              distance: data?['distance'] as double?,
            );

            // Add notification for user
            _addUserNotification(
              title: '💰 ভাড়া প্রস্তাব এসেছে',
              message:
                  '$driverName আপনার ট্রিপের জন্য ৳${driverFare.toStringAsFixed(0)} ভাড়া প্রস্তাব করেছেন।',
              type: 'ambulance',
              data: {
                'type': 'fare_proposed',
                'requestId': orderId,
                'driverFare': driverFare,
              },
            );
          }
        } else if (status == 'accepted') {
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
            message:
                'আপনার অ্যাম্বুলেন্স অ্যাসাইন হয়েছে এবং আপনার দিকে আসছে। অ্যাম্বুলেন্স পৌঁছালে পিকআপ OTP পাবেন।',
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
              message:
                  'আপনার অ্যাম্বুলেন্স অ্যাসাইন হয়েছে এবং আপনার দিকে আসছে।',
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
              message:
                  'আপনার অ্যাম্বুলেন্স পিকআপ লোকেশনে পৌঁছেছে। OTP: $pickupOTP। ড্রাইভারকে এই OTP দেখান।',
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
                message:
                    'আপনার অ্যাম্বুলেন্স পিকআপ লোকেশনে পৌঁছেছে। OTP: $pickupOTP',
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
            message:
                'অ্যাম্বুলেন্স রোগী তুলে নিয়েছে এবং গন্তব্যের দিকে যাচ্ছে।',
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
              message:
                  'অ্যাম্বুলেন্স রোগী তুলে নিয়েছে এবং গন্তব্যের দিকে যাচ্ছে।',
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
              message:
                  'আপনার অ্যাম্বুলেন্স এখন গন্তব্যের দিকে যাচ্ছে। পৌঁছানোর OTP: $destinationOTP। পৌঁছালে ড্রাইভারকে এই OTP দেখান।',
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
                message:
                    'আপনার অ্যাম্বুলেন্স এখন গন্তব্যের দিকে যাচ্ছে। OTP: $destinationOTP',
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
              message: 'Your ambulance is now heading to the destination.',
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
          markers
              .removeWhere((marker) => marker.markerId.value == 'destination');
          markers.removeWhere((marker) => marker.markerId.value == 'start');

          SuccessDialog.show(
            title: 'Service Completed',
            message: 'Your ambulance service has been completed.',
          );

          // Add notification for user
          _addUserNotification(
            title: '🎉 সেবা সম্পন্ন হয়েছে',
            message:
                'আপনার অ্যাম্বুলেন্স সেবা সম্পন্ন হয়েছে। আমাদের সেবা ব্যবহার করার জন্য ধন্যবাদ।',
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
                  onPressed: () {
                    try {
                      Get.back();
                    } catch (_) {}
                  },
                  child: Text('ঠিক আছে'),
                ),
              ],
            ),
          );

          // Add notification for user
          _addUserNotification(
            title: '❌ অর্ডার বাতিল',
            message:
                'দুঃখিত, আপনার অ্যাম্বুলেন্স রিকুয়েস্ট বাতিল করা হয়েছে। দয়া করে আবার চেষ্টা করুন।',
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
              message:
                  'দুঃখিত, আপনার অ্যাম্বুলেন্স রিকুয়েস্ট বাতিল করা হয়েছে।',
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
          markers
              .removeWhere((marker) => marker.markerId.value == 'destination');
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

  /// Show bottom sheet with driver's proposed fare for user to accept or reject
  void _showFareProposalBottomSheet({
    required String orderId,
    required double driverFare,
    required String driverName,
    String? pickupAddress,
    String? destinationAddress,
    double? distance,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.monetization_on,
                        color: Colors.green.shade700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ভাড়া প্রস্তাব',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '$driverName ভাড়া পাঠিয়েছেন',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Fare amount - prominent display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.green.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      'প্রস্তাবিত ভাড়া',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '৳${driverFare.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trip info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    if (pickupAddress != null)
                      _buildFareInfoRow(
                        Icons.my_location,
                        'পিকআপ',
                        pickupAddress,
                        Colors.blue.shade700,
                      ),
                    if (destinationAddress != null) ...[
                      const SizedBox(height: 12),
                      _buildFareInfoRow(
                        Icons.flag,
                        'গন্তব্য',
                        destinationAddress,
                        Colors.red.shade700,
                      ),
                    ],
                    if (distance != null) ...[
                      const SizedBox(height: 12),
                      _buildFareInfoRow(
                        Icons.straighten,
                        'দূরত্ব',
                        '${distance.toStringAsFixed(1)} কিমি',
                        Colors.orange.shade700,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          try {
                            Get.back();
                          } catch (_) {}
                          _rejectProposedFare(orderId);
                        },
                        icon: const Icon(Icons.close, size: 22),
                        label: const Text(
                          'প্রত্যাখ্যান',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          try {
                            Get.back();
                          } catch (_) {}
                          _acceptProposedFare(orderId, driverFare);
                        },
                        icon: const Icon(Icons.check_circle, size: 22),
                        label: const Text(
                          'গ্রহণ করুন',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  /// Helper widget for fare info rows
  Widget _buildFareInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Accept the driver's proposed fare
  Future<void> _acceptProposedFare(String orderId, double driverFare) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update Supabase order to accepted
      await SupabaseService.updateOrder(orderId, {
        'status': 'accepted',
        'fareAcceptedAt': DateTime.now().toIso8601String(),
        'fareAcceptedBy': user.uid,
        'totalAmount': driverFare,
        'fareAmount': driverFare.toInt(),
      });

      debugPrint('✅ User accepted fare ৳$driverFare for order $orderId');

      // Send FCM notification to driver
      final orderMap = await SupabaseService.getOrder(orderId);
      final partnerId = orderMap != null ? SupabaseService.toCamelCase(orderMap)['partnerId'] : null;
      if (partnerId != null) {
        final partnerMap = await SupabaseService.getPartner(partnerId);
        final fcmToken = partnerMap != null ? SupabaseService.toCamelCase(partnerMap)['fcmToken'] : null;
        if (fcmToken != null) {
          await NotificationService.sendFCMNotification(
            token: fcmToken,
            title: '✅ ভাড়া গৃহীত হয়েছে',
            body:
                'ইউজার আপনার ৳${driverFare.toStringAsFixed(0)} ভাড়া গ্রহণ করেছেন। ট্রিপ শুরু করুন।',
            data: {
              'type': 'fare_accepted',
              'orderId': orderId,
            },
          );
        }
      }

      // Add notification
      _addUserNotification(
        title: '✅ ভাড়া গ্রহণ করা হয়েছে',
        message:
            '৳${driverFare.toStringAsFixed(0)} ভাড়া গ্রহণ করা হয়েছে। অ্যাম্বুলেন্স আসছে।',
        type: 'ambulance',
        data: {
          'type': 'fare_accepted',
          'requestId': orderId,
        },
      );
    } catch (e) {
      debugPrint('❌ Error accepting fare: $e');
      Alert.error('ভাড়া গ্রহণ করতে ব্যর্থ হয়েছে: $e');
    }
  }

  /// Reject the driver's proposed fare
  Future<void> _rejectProposedFare(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update Firestore order to fare_rejected
      // Update Supabase order to fare_rejected
      await SupabaseService.updateOrder(orderId, {
        'status': 'fare_rejected',
        'fareRejectedAt': DateTime.now().toIso8601String(),
        'fareRejectedBy': user.uid,
      });

      debugPrint('❌ User rejected fare for order $orderId');

      // Send FCM notification to driver
      final orderMap = await SupabaseService.getOrder(orderId);
      final partnerId = orderMap != null ? SupabaseService.toCamelCase(orderMap)['partnerId'] : null;
      if (partnerId != null) {
        final partnerMap = await SupabaseService.getPartner(partnerId);
        final fcmToken = partnerMap != null ? SupabaseService.toCamelCase(partnerMap)['fcmToken'] : null;
        if (fcmToken != null) {
          await NotificationService.sendFCMNotification(
            token: fcmToken,
            title: '❌ ভাড়া প্রত্যাখ্যাত',
            body: 'ইউজার আপনার প্রস্তাবিত ভাড়া প্রত্যাখ্যান করেছেন।',
            data: {
              'type': 'fare_rejected',
              'orderId': orderId,
            },
          );
        }
      }

      // Add notification
      _addUserNotification(
        title: '❌ ভাড়া প্রত্যাখ্যান করা হয়েছে',
        message: 'আপনি ভাড়া প্রত্যাখ্যান করেছেন।',
        type: 'ambulance',
        data: {
          'type': 'fare_rejected',
          'requestId': orderId,
        },
      );
    } catch (e) {
      debugPrint('❌ Error rejecting fare: $e');
      Alert.error('ভাড়া প্রত্যাখ্যান করতে ব্যর্থ হয়েছে: $e');
    }
  }

  void navigateToPartnersOrders() {
    Get.to(() => PartnersOrdersPage());
  }

  void navigateToUserOrders() {
    Get.to(() => UserOrdersPage());
  }

  void navigateToUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isGLM = prefs.getBool('isGLMLoggedIn') ?? false;
      String? glmId = prefs.getString('currentGLMId');
      if (isGLM && glmId != null) {
        Get.offAll(() => GLMDashboard(glmId: glmId));
        return;
      }
    } catch (e) {
      debugPrint('SharedPreferences error in navigateToUserId: $e');
    }
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
      // No active tracking, show success dialog
      SuccessDialog.show(
        title: 'No Active Tracking',
        message: 'You don\'t have any active ambulance tracking at the moment.',
        autoCloseDuration: const Duration(seconds: 3),
      );
      // Or navigate to orders page
      navigateToUserOrders();
    }
  }

  void navigateToUserTracking(String orderId) async {
    try {
      // Fetch the complete order data from Supabase
      final orderMap = await SupabaseService.getOrder(orderId);

      if (orderMap != null) {
        final orderData = {'id': orderId, ...SupabaseService.toCamelCase(orderMap)};
        Get.to(() => const UserTrackingPage(), arguments: orderData);
      } else {
        Get.dialog(
          AlertDialog(
            title: const Text('Error', style: TextStyle(color: Colors.red)),
            content: const Text('Order data not found'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching order data: $e');
      Get.dialog(
        AlertDialog(
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: const Text('Failed to load tracking data'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
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
                        try {
                          Get.back();
                        } catch (_) {}
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
    showAmbulances.value = false;

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

  Future<void> onMapCreated(GoogleMapController controller) async {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }

    // If we have current position, animate to it
    if (currentPosition.value != null) {
      try {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: currentPosition.value!, zoom: 14),
          ),
        );
      } catch (e) {
        debugPrint('🏠 HomeUser: onMapCreated animateCamera failed: $e');
      }
    }
  }

  // Zoom methods
  Future<void> zoomIn() async {
    if (_controller.isCompleted) {
      try {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(CameraUpdate.zoomIn());
      } catch (e) {
        debugPrint('🏠 HomeUser: zoomIn failed: $e');
      }
    }
  }

  Future<void> zoomOut() async {
    if (_controller.isCompleted) {
      try {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(CameraUpdate.zoomOut());
      } catch (e) {
        debugPrint('🏠 HomeUser: zoomOut failed: $e');
      }
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
        try {
          await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
        } catch (e) {
          debugPrint('🏠 HomeUser: setDestinationFromCoordinates animateCamera failed: $e');
        }
      }
    } catch (e) {
      Alert.error(
        'Failed to set destination: $e',
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
        final userDocMap = await SupabaseService.getUser(userId);

        if (userDocMap != null) {
          final userData = SupabaseService.toCamelCase(userDocMap);
          userName = userData['name'] ?? currentUser?.displayName ?? 'User';
          userPhone = userData['phone'] ?? currentUser?.phoneNumber ?? '';
          userAddress = userData['address'] ?? '';
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
      } else {}
    } catch (e) {}
  }

  /// Sends notification to multiple drivers based on proximity
  Future<void> sendNotificationToNearbyDrivers({
    required LatLng userLocation,
    required Map<String, dynamic> requestData,
    double radiusInKm = 5.0,
  }) async {
    try {
      print('🔍 Looking for nearby drivers within ${radiusInKm}km radius...');

      // Query nearby drivers from Supabase
      final list = await SupabaseService.query(
        'partners',
        filters: {
          'role': 'driver',
          'is_online': true,
        },
      );

      int notificationsSent = 0;

      for (var item in list) {
        final driverData = SupabaseService.toCamelCase(item);
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
      } else {
        Alert.info('আশেপাশে কোন অনলাইন ড্রাইভার পাওয়া যায়নি');
      }
    } catch (e) {
      Alert.error('আশেপাশের ড্রাইভারদের খুঁজে পেতে সমস্যা হয়েছে');
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
        return;
      }

      // Get driver's FCM token from Supabase
      final driverDocMap = await SupabaseService.getPartner(driverId);

      if (driverDocMap == null) {
        return;
      }

      final driverData = SupabaseService.toCamelCase(driverDocMap);
      final fcmToken = driverData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
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

      // Save request to Supabase
      final requestId = requestData['requestId'] as String;
      await SupabaseService.client.from('ride_requests').upsert({
        ...SupabaseService.toSnakeCase(requestData),
        'user_id': currentUser.uid,
        'created_at': DateTime.now().toIso8601String(),
        'id': requestId,
      });

      // Send push notification to driver
      await sendNotificationToDriver(
        driverId: driverId,
        fcmToken: fcmToken,
        requestData: requestData,
      );
    } catch (e) {
      print('❌ Error sending ride request: $e');
      Alert.error('রাইড রিকুয়েস্ট পাঠাতে সমস্যা হয়েছে: $e');
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
        Alert.error('অনুগ্রহ করে লগইন করুন');
        return;
      }

      if (currentPosition.value == null) {
        Alert.error('আপনার বর্তমান অবস্থান পাওয়া যায়নি');
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

      // Save request to Supabase
      final requestId2 = requestData['requestId'] as String;
      await SupabaseService.client.from('ride_requests').upsert({
        ...SupabaseService.toSnakeCase(requestData),
        'user_id': currentUser.uid,
        'created_at': DateTime.now().toIso8601String(),
        'id': requestId2,
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
      Alert.error(
          'Image size ($fileSizeMB MB) exceeds 2MB limit. Please choose a smaller image or take a new photo.');
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
        Alert.error(
            'Photo library access is required to select images. Please grant permission when prompted.');
        return;
      }

      if (status.isPermanentlyDenied) {
        Alert.error(
            'Photo library access is permanently denied. Please enable it in app settings.');
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
      Alert.error('Failed to pick image. Please try again.');
    }
  }

  Future<void> pickAndUploadProfileImageFromCamera() async {
    try {
      // Request camera permission first
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Alert.error(
            'Camera access is required to take photos. Please grant permission in settings.');
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
      Alert.error('Failed to take photo. Please try again.');
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      isUploadingImage.value = true;
      uploadProgress.value = 0.0; // Reset progress

      // Show immediate feedback
      Alert.info('Uploading profile image...');

      // Check network connectivity first
      final isConnected = await _isConnected();
      if (!isConnected) {
        Alert.error('Please check your internet connection and try again.');
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

        // Update Supabase with the new image URL
        await SupabaseService.updateUser(user.uid, {
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
        // Network error retry not supported in Alert yet
        Alert.error('Network error occurred. Please try again.');
        return; // Don't show the default error snackbar
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMessage =
            'Permission denied. Please grant storage permissions and try again.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Upload was cancelled.';
        return; // Don't show error snackbar for cancelled uploads
      }

      Alert.error(errorMessage);
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

      // Remove from Supabase
      await SupabaseService.updateUser(user.uid, {
        'profileImageUrl': null,
      });

      // Update local state
      profileImageUrl.value = null;

      SuccessDialog.show(
        title: 'Profile Updated',
        message: 'Your profile image has been removed successfully!',
      );
    } catch (e) {
      debugPrint('❌ Error removing profile image: $e');
      Alert.error('Failed to remove profile image. Please try again.');
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

  void _callAmbulance(String? phoneNumber) {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      launchUrl(launchUri);
    } else {
      Alert.error('Phone number not available');
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

      await SupabaseService.client.from('user_notifications').insert({
        'user_id': user.uid,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'timestamp': DateTime.now().toIso8601String(),
        'data': data ?? {},
      });

      debugPrint('✅ User notification added: $title');
    } catch (e) {
      debugPrint('❌ Failed to add user notification: $e');
    }
  }
}
