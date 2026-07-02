import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:saver/components/alert.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/directions.dart' as directions;
import 'trip_rating_page.dart';
import '../config/api_keys.dart';
import '../../services/supabase_service.dart';

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

  // Partner info
  var partnerName = 'NeoSaver Partner'.obs;
  var partnerImage = Rx<String?>(null);
  var partnerPhone = Rx<String?>(null);

  // Route polyline variables
  var routePoints = <LatLng>[].obs;

  // ETA variables
  var estimatedTime = Rx<String>('গণনা হচ্ছে...');
  var estimatedDistance = Rx<double>(0.0);
  var isCalculatingETA = false.obs;
  
  bool _isNavigatingHome = false;

  // Live tracking variables
  var isLiveTracking = false.obs;
  StreamSubscription<List<Map<String, dynamic>>>? _orderSubscription;

  // Timing and performance optimization
  Timer? _etaUpdateTimer;
  static const Duration _etaUpdateInterval = Duration(seconds: 10);

  // Default position (Dhaka, Bangladesh)
  static const LatLng defaultPosition = LatLng(23.8103, 90.4125);

  // Google Maps Directions API client
  late directions.GoogleMapsDirections _directions;

  void _initializeDirections() {
    _directions = directions.GoogleMapsDirections(
        apiKey: ApiKeys.googleMapsApiKey);
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
    debugPrint('UserTracking: Processing order with status: $status');

    // Set destination as user position if status is pickup or to_destination
    if (status == 'pickup' || status == 'to_destination') {
      final destinationLat = orderData['destinationLat'];
      final destinationLng = orderData['destinationLng'];

      if (destinationLat != null && destinationLng != null) {
        final destinationLocation = LatLng(destinationLat, destinationLng);
        userPosition.value = destinationLocation;
        debugPrint(
            'UserTracking: Set destination as user position for status $status: $destinationLocation');
      }
    }

    // Process ambulance location if available
    if (status != 'completed') {
      // Try partnerLiveLocation first
      final liveLocation =
          orderData['partnerLiveLocation'] as Map<String, dynamic>?;
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

          debugPrint(
              'UserTracking: Processed existing ambulance live location: $location');
        }
      } else {
        // Fallback to partnerLocation
        final partnerLocation =
            orderData['partnerLocation'] as Map<String, dynamic>?;
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

            debugPrint(
                'UserTracking: Processed existing partner location: $location');
          }
        } else {
          debugPrint(
              'UserTracking: No ambulance location found in existing order data');
        }
      }
    }
  }

  void _forceInitialDataCalculation() {
    debugPrint('UserTracking: Forcing initial data calculation');

    final status =
        orderData.value?['orderStatus'] ?? orderData.value?['status'];
    debugPrint('UserTracking: Current status for initial calculation: $status');

    // Process destination for pickup and to_destination status
    if (status == 'pickup' || status == 'to_destination') {
      final destinationLat = orderData.value?['destinationLat'];
      final destinationLng = orderData.value?['destinationLng'];

      if (destinationLat != null && destinationLng != null) {
        final destinationLocation = LatLng(destinationLat, destinationLng);
        userPosition.value = destinationLocation;
        debugPrint(
            'UserTracking: Set destination in force calculation for status $status: $destinationLocation');
      }
    }

    // Update markers and polylines
    _updateMarkers();
    _updatePolylines();

    // Calculate ETA if we have both positions
    if (ambulancePosition.value != null && userPosition.value != null) {
      debugPrint(
          'UserTracking: Both positions available - Ambulance: ${ambulancePosition.value}, Destination: ${userPosition.value}');

      // For pickup or to_destination status, calculate route to destination
      if (status == 'pickup' || status == 'to_destination') {
        debugPrint(
            'UserTracking: Calculating initial route to destination for status: $status');
        calculateRouteToDestination(userPosition.value!);
      } else {
        debugPrint('UserTracking: Calculating initial ETA');
        calculateETA();
      }
    } else {
      debugPrint(
          'UserTracking: Missing positions for ETA calculation - Ambulance: ${ambulancePosition.value}, User: ${userPosition.value}');

      // If pickup completed or going to destination but missing ambulance position, try to get it from order data
      if ((status == 'pickup' || status == 'to_destination') &&
          ambulancePosition.value == null) {
        final partnerLocation =
            orderData.value?['partnerLocation'] as Map<String, dynamic>?;
        if (partnerLocation != null) {
          final lat = partnerLocation['latitude'] as double?;
          final lng = partnerLocation['longitude'] as double?;

          if (lat != null && lng != null) {
            ambulancePosition.value = LatLng(lat, lng);
            debugPrint(
                'UserTracking: Got ambulance position from partnerLocation: ${ambulancePosition.value}');

            // Try to calculate route now
            if (userPosition.value != null) {
              calculateRouteToDestination(userPosition.value!);
            }
          }
        } else {
          debugPrint(
              'UserTracking: Status is pickup/to_destination but no ambulance position available in order data');
        }
      }
    }

    // Start periodic ETA updates only if not pickup completed or going to destination
    if (status != 'pickup' && status != 'to_destination') {
      _scheduleETAUpdate();
    }
  }

  Future<void> _loadCustomIcons() async {
    try {
      debugPrint('Loading custom icons for user tracking...');

      // User location icon (red)

      userLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(50, 50)),
        'assets/images/pin-map.png',
      );

      // Ambulance location icon (blue)
      ambulanceLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(60, 60)),
        'assets/images/ambulance.png',
      );

      debugPrint('User tracking custom icons loaded successfully');
    } catch (e) {
      debugPrint('Failed to load user tracking custom icons: $e');
      ambulanceLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLoadingLocation.value = false;
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final status =
          orderData.value?['orderStatus'] ?? orderData.value?['status'];
      // Only set userPosition if we're not heading to a fixed destination
      if (status != 'pickup' && status != 'to_destination') {
        userPosition.value = LatLng(position.latitude, position.longitude);
      }

      // Update markers
      _updateMarkers();

      isLoadingLocation.value = false;
    } catch (e) {
      if (userPosition.value == null) {
        userPosition.value = defaultPosition;
      }
      _updateMarkers();
      isLoadingLocation.value = false;
      debugPrint('Error getting user location: $e');
    }
  }

  void _updateMarkers() {
    markers.clear();

    final status =
        (orderData.value?['orderStatus'] ?? orderData.value?['status'] ?? '')
            .toString()
            .toLowerCase();
    final isGoingToDestination =
        status == 'pickup' || status == 'to_destination';

    // Add user/destination marker
    if (userPosition.value != null) {
      markers.add(
        Marker(
          markerId: MarkerId(isGoingToDestination ? 'destination' : 'user'),
          position: userPosition.value!,
          infoWindow: InfoWindow(
            title: isGoingToDestination ? 'গন্তব্য' : 'আপনার অবস্থান',
            snippet: isGoingToDestination
                ? 'পেশেন্ট এখানে যাচ্ছে'
                : 'অ্যাম্বুলেন্স এখানে আসছে',
          ),
          icon: isGoingToDestination
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Add ambulance marker
    if (ambulancePosition.value != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ambulance'),
          position: ambulancePosition.value!,
          infoWindow: const InfoWindow(
            title: 'অ্যাম্বুলেন্স (লাইভ)',
            snippet: 'রিয়েল-টাইম ট্র্যাকিং হচ্ছে',
          ),
          icon: ambulanceLocationIcon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: 0, // Could be improved with actual bearing if available
        ),
      );
    }
  }

  void listenForOrderUpdates(String orderId) {
    debugPrint('UserTracking: Starting to listen for order updates: $orderId');

    // Cancel any existing subscription
    _orderSubscription?.cancel();

    // Listen for order updates
    _orderSubscription = SupabaseService.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .listen((list) {
      if (list.isNotEmpty) {
        final data = SupabaseService.toCamelCase(list.first);
        final status = data['orderStatus'] ?? data['status'];

        debugPrint('UserTracking: Order status update: $status');

        // Handle status changes
        if (status == 'completed') {
          // Clear ambulance location and trail when service is completed
          ambulancePosition.value = null;
          ambulanceLocationTrail.clear();
          routePoints.clear();
          _updateMarkers();
          _updatePolylines();
          debugPrint(
              'UserTracking: Service completed - cleared ambulance location');
        }

        // Handle live location updates (only if not completed)
        if (status != 'completed') {
          final liveLocation =
              data['partnerLiveLocation'] as Map<String, dynamic>?;
          if (liveLocation != null) {
            final lat = liveLocation['latitude'] as double?;
            final lng = liveLocation['longitude'] as double?;

            if (lat != null && lng != null) {
              final newLocation = LatLng(lat, lng);

              // Update ambulance live location
              ambulancePosition.value = newLocation;

              // Add to location trail
              if (ambulanceLocationTrail.isEmpty ||
                  ambulanceLocationTrail.last != newLocation) {
                ambulanceLocationTrail.add(newLocation);

                // Keep only last 50 points to avoid performance issues
                if (ambulanceLocationTrail.length > 50) {
                  ambulanceLocationTrail.removeAt(0);
                }
              }

              debugPrint(
                  'UserTracking: Ambulance location updated from live location: $newLocation');

              // Calculate ETA periodically (not for pickup/destination as it's handled below)
              if (status != 'pickup' && status != 'to_destination') {
                _scheduleETAUpdate();
              }
            }
          }
        }

        _updateMarkers();
        _updatePolylines();

        if (status == 'completed') {
          debugPrint('UserTracking: Ride completed. Preparing to go home.');
          _handleRideCompletion();
        }

        if (ambulancePosition.value != null &&
            userPosition.value != null &&
            status != 'completed') {
          final prevStatus =
              orderData.value?['orderStatus'] ?? orderData.value?['status'];
          if (status != prevStatus &&
              (status == 'pickup' || status == 'to_destination')) {
            debugPrint(
                'UserTracking: Status changed to $status - updating destination coordinates');
            
            final destLat = data['destinationLat'];
            final destLng = data['destinationLng'];
            if (destLat != null && destLng != null) {
              userPosition.value = LatLng(destLat, destLng);
              debugPrint('UserTracking: Target destination updated to: ${userPosition.value}');
            }
            routePoints.clear();
          }

          // We schedule it to avoid hammering the API on every tiny snapshot change
          _scheduleETAUpdate();

          // Force an immediate calculation if the route is empty or status just changed
          if (routePoints.isEmpty || (status != prevStatus && (status == 'pickup' || status == 'to_destination'))) {
            if ((status == 'pickup' || status == 'to_destination') && userPosition.value != null) {
              calculateRouteToDestination(userPosition.value!);
            } else if (status != 'completed') {
              calculateETA();
            }
          }
        }

        // Improved fare extraction: prioritize non-zero values from all possible fields
        dynamic getValidFare(Map<String, dynamic>? data) {
          final fields = [
            data?['fareAmount'],
            data?['confirmedFare'],
            data?['counterFare'],
            data?['totalAmount'],
            data?['totalFare'],
            data?['fare'],
            data?['negotiation']?['counterFare'],
            data?['negotiation']?['finalFare'],
            data?['negotiation']?['currentFare'],
            data?['negotiation']?['driverFare'],
          ];

          for (var field in fields) {
            if (field != null && field != 0 && field != '0') {
              return field;
            }
          }
          return null;
        }

        final rawFare = getValidFare(data);

        final fareAmount = (rawFare is num)
            ? rawFare.toInt()
            : (int.tryParse(rawFare?.toString() ?? '0') ??
                double.tryParse(rawFare?.toString() ?? '0')?.toInt() ??
                0);

        final currentId = orderData.value?['id'] ?? orderId;
        final updatedData = {
          'id': currentId,
          ...?data,
          'fareAmount': fareAmount,
        };

        orderData.value = updatedData;

        // Fetch partner details if we have partnerId/acceptedBy and haven't fetched yet
        final partnerId =
            data['partnerId'] ?? data['acceptedBy'] ?? data['driverId'];

        // Use driverName from order data if available immediately
        if (data['driverName'] != null) {
          partnerName.value = data['driverName'];
        }

        if (partnerId != null &&
            (partnerName.value == 'NeoSaver Partner' ||
                partnerImage.value == null)) {
          _fetchPartnerDetails(partnerId);
        }
      }
    });
  }

  void _handleRideCompletion() async {
    if (_isNavigatingHome) return;
    _isNavigatingHome = true;

    // Show completion UI for a few seconds before going home
    await Future.delayed(const Duration(seconds: 4));

    // Navigate to Rating Page
    final data = orderData.value ?? {};
    if (!data.containsKey('id')) {
      data['id'] = orderId;
    }
    Get.offAll(() => TripRatingPage(orderData: data));
  }

  Future<void> _fetchPartnerDetails(String partnerId) async {
    try {
      debugPrint('UserTracking: Fetching details for partner: $partnerId');

      // 1. Try to fetch Name from "drivers" collection
      final driverMap = await SupabaseService.client
          .from('drivers')
          .select()
          .eq('id', partnerId)
          .maybeSingle();

      if (driverMap != null) {
        final data = SupabaseService.toCamelCase(driverMap);
        if (data['name'] != null) {
          partnerName.value = data['name'];
          debugPrint(
              'UserTracking: Fetched name from drivers table: ${partnerName.value}');
        }
        if (data['phone'] != null || data['contact'] != null) {
          partnerPhone.value = data['phone'] ?? data['contact'];
        }
      }

      // 2. Try to fetch Profile Image from "partners" collection
      final partnerMap = await SupabaseService.client
          .from('partners')
          .select()
          .eq('id', partnerId)
          .maybeSingle();

      if (partnerMap != null) {
        final data = SupabaseService.toCamelCase(partnerMap);
        if (data['profileImageUrl'] != null) {
          partnerImage.value = data['profileImageUrl'];
          debugPrint('UserTracking: Fetched image from partners table');
        }
        // If name wasn't in drivers, try partners
        if (partnerName.value == 'NeoSaver Partner' && data['name'] != null) {
          partnerName.value = data['name'];
        }
        if (partnerPhone.value == null && (data['phone'] != null || data['contact'] != null)) {
          partnerPhone.value = data['phone'] ?? data['contact'];
        }
      }

      // 3. Fallback to "users" collection if still missing
      if (partnerName.value == 'NeoSaver Partner' ||
          partnerImage.value == null || partnerPhone.value == null) {
        final userMap = await SupabaseService.client
            .from('users')
            .select()
            .eq('id', partnerId)
            .maybeSingle();

        if (userMap != null) {
          final data = SupabaseService.toCamelCase(userMap);
          if (partnerName.value == 'NeoSaver Partner') {
            partnerName.value = data['name'] ?? 'NeoSaver Partner';
          }
          if (partnerImage.value == null) {
            partnerImage.value = data['profileImageUrl'];
          }
          if (partnerPhone.value == null && data['phone'] != null) {
            partnerPhone.value = data['phone'];
          }
        }
      }
    } catch (e) {
      debugPrint('UserTracking: Error fetching partner details: $e');
    }
  }

  void _updatePolylines() {
    polylines.clear();

    final status =
        (orderData.value?['orderStatus'] ?? orderData.value?['status'] ?? '')
            .toString()
            .toLowerCase();
    final isGoingToDestination =
        status == 'pickup' || status == 'to_destination';
    final isComingToUser = status == 'accepted' ||
        status == 'sent' ||
        status == 'counter' ||
        status == 'in_transit';

    // Add ambulance trail polyline
    if (ambulanceLocationTrail.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ambulance_trail'),
          color: isGoingToDestination
              ? Colors.green.shade600
              : Colors.blue.shade600,
          width: 4,
          points: ambulanceLocationTrail,
          zIndex: 2,
        ),
      );
    }

    // Add route from ambulance to user/destination if both positions available
    if (routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_user'),
          color: isGoingToDestination
              ? Colors.green.shade700
              : Colors.blue.shade700,
          width: 5, // Slightly thinner for better map visibility
          points: routePoints,
          zIndex: 1,
        ),
      );
    } else if (ambulancePosition.value != null &&
        userPosition.value != null &&
        (isGoingToDestination || isComingToUser)) {
      // Fallback to straight line if no route calculated
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_user'),
          color: isGoingToDestination
              ? Colors.green.shade700
              : Colors.blue.shade700,
          width: 5,
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
    if (ambulancePosition.value != null)
      positions.add(ambulancePosition.value!);

    // Include route points in bounds calculation
    positions.addAll(routePoints);

    if (positions.isNotEmpty) {
      if (positions.length == 1) {
        try {
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: positions.first, zoom: 14),
            ),
          );
        } catch (e) {
          debugPrint('UserTracking: _fitBounds (single) failed: $e');
        }
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
        try {
          await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
        } catch (e) {
          debugPrint('UserTracking: _fitBounds (bounds) failed: $e');
        }
      }
    }
  }

  // Calculate route to destination
  Future<void> calculateRouteToDestination(LatLng destination) async {
    if (ambulancePosition.value == null) {
      return;
    }

    try {
      final origin =
          '${ambulancePosition.value!.latitude},${ambulancePosition.value!.longitude}';
      final dest = '${destination.latitude},${destination.longitude}';

      final result = await _directions.directions(
        origin,
        dest,
        travelMode: directions.TravelMode.driving,
        units: directions.Unit.metric,
      );

      if (result.status == 'OK' && result.routes.isNotEmpty) {
        final route = result.routes.first;
        final leg = route.legs.first;

        // Extract and decode route polyline points
        final encodedPolyline = route.overviewPolyline.points;
        final decodedPoints = _decodePolyline(encodedPolyline);
        routePoints.value = decodedPoints;

        // Update ETA for destination
        final duration = leg.duration.text;
        final distance = leg.distance.value.toDouble();
        estimatedTime.value = duration;
        estimatedDistance.value = distance / 1000; // Convert to km

        // Update polylines and markers
        _updatePolylines();
        _updateMarkers();
        _fitBounds();
      } else {}
    } catch (e) {}
  }

  // ETA Calculation
  Future<void> calculateETA() async {
    if (ambulancePosition.value == null || userPosition.value == null) {
      estimatedTime.value = 'অনুমানিক সময়';
      return;
    }

    try {
      isCalculatingETA.value = true;

      final origin =
          '${ambulancePosition.value!.latitude},${ambulancePosition.value!.longitude}';
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
      } else {
        estimatedTime.value = 'গণনা করা যায়নি';
      }
    } catch (e) {
      estimatedTime.value = 'সময় গণনায় ত্রুটি';
    } finally {
      isCalculatingETA.value = false;
    }
  }

  String _formatDuration(int minutes) {
    String toBengaliDigits(String input) {
      const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      for (int i = 0; i < english.length; i++) {
        input = input.replaceAll(english[i], bengali[i]);
      }
      return input;
    }

    if (minutes < 1) {
      return '১ মিনিটের কম';
    } else if (minutes < 60) {
      return '${toBengaliDigits(minutes.toString())} মিনিট';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${toBengaliDigits(hours.toString())} ঘণ্টা';
      } else {
        return '${toBengaliDigits(hours.toString())} ঘণ্টা ${toBengaliDigits(remainingMinutes.toString())} মিনিট';
      }
    }
  }

  void callPartner() async {
    final phone = partnerPhone.value ?? orderData.value?['partnerPhone'] ?? orderData.value?['driverPhone'] ?? orderData.value?['phone'];
    if (phone != null && phone.toString().isNotEmpty) {
      final Uri uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint('Could not launch $uri');
      }
    } else {
      Alert.error('ফোন নম্বর পাওয়া যায়নি');
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
    // Throttling: If the timer is already active, don't restart it or hammer the API.
    // This allows the current timer to finish and run calculateETA() correctly.
    if (_etaUpdateTimer?.isActive == true) {
      return;
    }

    // If it's the first time or enough time has passed, schedule the next update
    _etaUpdateTimer = Timer(_etaUpdateInterval, () {
      if (isLiveTracking.value || ambulancePosition.value != null) {
        calculateETA();
      }
    });
  }

  void startLiveTracking() {
    isLiveTracking.value = true;
  }

  void stopLiveTracking() {
    isLiveTracking.value = false;
    _orderSubscription?.cancel();
    _orderSubscription = null;
    _etaUpdateTimer?.cancel();
    _etaUpdateTimer = null;
  }

  // Navigation methods
  void zoomIn() async {
    if (_controller.isCompleted) {
      try {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(CameraUpdate.zoomIn());
      } catch (e) {
        debugPrint('UserTracking: zoomIn failed: $e');
      }
    }
  }

  void zoomOut() async {
    if (_controller.isCompleted) {
      try {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(CameraUpdate.zoomOut());
      } catch (e) {
        debugPrint('UserTracking: zoomOut failed: $e');
      }
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
