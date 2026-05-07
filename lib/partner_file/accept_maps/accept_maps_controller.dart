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
import '../../services/notification_service.dart';
import '../home_partner/home_partner.dart';

class AcceptMapsController extends GetxController {
  final Completer<GoogleMapController> _controller = Completer();

  // Custom marker icons
  BitmapDescriptor partnerLocationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor userLocationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  // Reactive variables
  var partnerPosition = Rx<LatLng?>(null);
  var userPosition = Rx<LatLng?>(null);
  var markers = <Marker>{}.obs;
  var polylines = <Polyline>{}.obs;
  var isLoadingLocation = true.obs;
  var requestData = Rx<Map<String, dynamic>?>(null);
  var showSlidePanel = false.obs;

  // Service rate from home partner
  var serviceRate = 2500.obs;

  // ETA variables
  var estimatedTime = Rx<String>('Calculating...');
  var estimatedDistance = Rx<double>(0.0);
  var isCalculatingETA = false.obs;

  // Live tracking variables
  var isLiveTracking = false.obs;
  StreamSubscription<Position>? _positionSubscription;

  // Timing and performance optimization
  Timer? _firestoreUpdateTimer;
  Timer? _cameraUpdateTimer;
  Timer? _etaUpdateTimer;
  Position? _lastFirestorePosition;
  DateTime? _lastFirestoreUpdateTime;
  Position? _lastCameraPosition;
  static const Duration _firestoreUpdateInterval =
      Duration(seconds: 4); // Update at least every 4 seconds
  static const Duration _cameraUpdateInterval =
      Duration(seconds: 8); // Camera update every 8 seconds
  static const Duration _etaUpdateInterval =
      Duration(seconds: 15); // ETA update every 15 seconds
  static const double _minDistanceForCameraUpdate =
      30.0; // 30 meters minimum for camera update

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

    try {
      _initializeDirections();
      _loadCustomIcons();

      // Get request data from arguments first
      final args = Get.arguments;
      if (args != null && args is Map<String, dynamic>) {
        final initialRequest = args['request'];
        requestData.value = initialRequest;

        final status = initialRequest?['status']?.toString().toLowerCase();
        final negStatus =
            initialRequest?['negotiation']?['status']?.toString().toLowerCase();

        showSlidePanel.value = args['fromActivityTab'] == true ||
            status == 'in_transit' ||
            status == 'accepted' ||
            status == 'confirmed' ||
            status == 'pickup' ||
            status == 'to_destination' ||
            negStatus == 'accepted' ||
            negStatus == 'confirmed';

        // Extract initial fare
        serviceRate.value =
            _extractFare(initialRequest) ?? args['serviceRate'] ?? 2500;

        final requestId = initialRequest?['id'];
        if (requestId != null) {
          _listenToOrderUpdates(requestId);
        }

        if (initialRequest?['pickupLat'] != null &&
            initialRequest?['pickupLng'] != null) {
          userPosition.value =
              LatLng(initialRequest['pickupLat'], initialRequest['pickupLng']);
        }
      }

      // Get current location and then calculate ETA
      _getCurrentLocation().then((_) {
        // Automatically start live tracking if order is in a trackable state
        if (requestData.value != null) {
          final status =
              requestData.value?['status']?.toString().toLowerCase();
          if (['accepted', 'in_transit', 'pickup', 'to_destination']
              .contains(status)) {
            debugPrint(
                'AcceptMaps: Automatically starting live tracking for status: $status');
            startLiveTracking(updateStatus: false);
          }
        }
      });
    } catch (e) {
      // Set default values if initialization fails
      serviceRate.value = 2500;
      showSlidePanel.value = false;
    }
  }

  int? _extractFare(Map<String, dynamic>? data) {
    if (data == null) return null;

    final fields = [
      data['fareAmount'],
      data['confirmedFare'],
      data['counterFare'],
      data['totalAmount'],
      data['totalFare'],
      data['fare'],
      data['negotiation']?['counterFare'],
      data['negotiation']?['finalFare'],
      data['negotiation']?['currentFare'],
      data['negotiation']?['driverFare'],
    ];

    for (var field in fields) {
      if (field != null && field != 0 && field != '0') {
        if (field is num) return field.toInt();
        return int.tryParse(field.toString()) ??
            double.tryParse(field.toString())?.toInt();
      }
    }
    return null;
  }

  StreamSubscription? _orderSubscription;

  void _listenToOrderUpdates(String orderId) {
    _orderSubscription?.cancel();
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        // Order deleted, return to home
        _orderSubscription?.cancel();
        Get.offAll(() => HomePartnerPage());
        return;
      }

      final data = snapshot.data();
      if (data != null) {
        final status = data['status']?.toString().toLowerCase();

        // If order is cancelled or completed, return to home
        if (status == 'cancelled' || status == 'completed') {
          _orderSubscription?.cancel();
          Get.offAll(() => HomePartnerPage());
          return;
        }

        requestData.value = {'id': orderId, ...data};

        final updatedFare = _extractFare(data);
        if (updatedFare != null && updatedFare > 0) {
          serviceRate.value = updatedFare;
        }

        final negStatus =
            data['negotiation']?['status']?.toString().toLowerCase();

        if (['accepted', 'confirmed', 'pickup', 'in_transit', 'to_destination']
                .contains(status) ||
            ['accepted', 'confirmed'].contains(negStatus)) {
          showSlidePanel.value = true;
        }
      } else {
        // No data, return to home
        _orderSubscription?.cancel();
        Get.offAll(() => HomePartnerPage());
      }
    });
  }

  void _initializeDirections() {
    try {
      // Initialize Google Maps Directions API
      _directions = directions.GoogleMapsDirections(
          apiKey: 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o');
    } catch (e) {}
  }

  Future<void> _loadCustomIcons() async {
    try {
      partnerLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(60, 60)),
        'assets/images/ambulance.png',
      );
      userLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(50, 50)),
        'assets/images/pin-map.png',
      );
    } catch (e) {
      partnerLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      userLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSuccessDialog(
              'Permission Denied', 'Location permission is required');
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
      // Calculate ETA if both positions are available
      if (userPosition.value != null) {
        calculateETA();
      }

      isLoadingLocation.value = false;
    } catch (e) {
      partnerPosition.value = defaultPosition;
      _updateMarkers();
      // Try to calculate ETA even with default position if user position exists
      if (userPosition.value != null) {
        calculateETA();
      }
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
        final origin =
            '${partnerPosition.value!.latitude},${partnerPosition.value!.longitude}';
        final destination =
            '${userPosition.value!.latitude},${userPosition.value!.longitude}';

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
        } else {}
      } catch (e) {}
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

  Future<void> onMapCreated(GoogleMapController controller) async {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }

    // If we have both positions, show both on map
    if (partnerPosition.value != null && userPosition.value != null) {
      _fitBounds();
    } else if (partnerPosition.value != null) {
      try {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: partnerPosition.value!, zoom: 14),
          ),
        );
      } catch (e) {
        debugPrint('🏁 AcceptMaps: onMapCreated animateCamera failed: $e');
      }
    }
  }

  Future<void> _fitBounds() async {
    if (partnerPosition.value != null &&
        userPosition.value != null &&
        _controller.isCompleted) {
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
      try {
        await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      } catch (e) {
        debugPrint('🏁 AcceptMaps: _fitBounds failed: $e');
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
        debugPrint('🏁 AcceptMaps: zoomIn failed: $e');
      }
    }
  }

  Future<void> zoomOut() async {
    if (_controller.isCompleted) {
      try {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(CameraUpdate.zoomOut());
      } catch (e) {
        debugPrint('🏁 AcceptMaps: zoomOut failed: $e');
      }
    }
  }

  // ETA Calculation
  Future<void> calculateETA() async {
    if (partnerPosition.value == null || userPosition.value == null) {
      estimatedTime.value = 'অনুমানিক সময়';

      return;
    }

    try {
      isCalculatingETA.value = true;

      final origin =
          '${partnerPosition.value!.latitude},${partnerPosition.value!.longitude}';
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

        // Get duration in minutes
        final durationInMinutes = (leg.duration.value / 60).round();
        final distanceInKm = (leg.distance.value / 1000);

        estimatedDistance.value = distanceInKm;
        estimatedTime.value = _formatDuration(durationInMinutes);
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
    if (minutes < 1) {
      return '১ মিনিটের কম';
    } else if (minutes < 60) {
      return '$minutes মিনিট';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ঘণ্টা${hours > 1 ? '' : ''}';
      } else {
        return '$hours ঘণ্টা${hours > 1 ? '' : ''} $remainingMinutes মিনিট';
      }
    }
  }

  Future<void> completeRide({required double fareAmount}) async {
    try {
      if (requestData.value != null) {
        final requestId = requestData.value!['id'];
        final userId = requestData.value!['userId'];

        // Update order status and fare
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(requestId)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'fareAmount': fareAmount,
          'finalFare': fareAmount,
        });

        // Send notification to user with fare amount
        if (userId != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          final fcmToken = userDoc.data()?['fcmToken'];
          if (fcmToken != null) {
            await NotificationService.sendFCMNotification(
              token: fcmToken,
              title: 'রাইড সম্পন্ন',
              body:
                  'আপনার রাইড সম্পন্ন হয়েছে। মোট খরচ: ৳${fareAmount.toStringAsFixed(0)}',
              data: {
                'type': 'ride_completed',
                'orderId': requestId,
                'fareAmount': fareAmount.toString(),
              },
            );
          }
        }

        // Update partner status back to available
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('partners')
              .doc(user.uid)
              .update({
            'isOnline': true,
            'currentOrderId': null,
            'status': 'available',
          });
        }

        // Stop live tracking if active
        if (isLiveTracking.value) {
          stopLiveTracking();
        }

        Get.back(); // Go back to home partner page
        _showSuccessDialog('রাইড সম্পন্ন',
            'রাইড সফলভাবে সম্পন্ন হয়েছে!\n\nমোট খরচ: ৳${fareAmount.toStringAsFixed(0)}',
            navigateHome: true);
      }
    } catch (e) {
      _showSuccessDialog('Error', 'Failed to complete ride: $e');
    }
  }

  // Send notification to user when order status changes
  Future<void> _sendStatusChangeNotification(String status) async {
    if (requestData.value == null) {
      return;
    }

    final requestId = requestData.value!['id'];
    final userId = requestData.value!['userId'];

    try {
      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        String title = 'Order Status Update';
        String body = 'Your order status has been updated to: $status';

        // Customize message based on status
        switch (status) {
          case 'accepted':
            title = 'রাইড গ্রহণ করা হয়েছে';
            body = 'আপনার রাইড গ্রহণ করা হয়েছে। অ্যাম্বুলেন্স আসছে।';
            break;
          case 'in_transit':
            title = 'অ্যাম্বুলেন্স রওনা হয়েছে';
            body = 'আপনার অ্যাম্বুলেন্স রওনা হয়েছে।';
            break;
          case 'pickup':
            title = 'পেশেন্ট পিকআপ সম্পন্ন';
            body = 'পেশেন্ট পিকআপ সম্পন্ন হয়েছে। গন্তব্যের দিকে যাচ্ছে।';
            break;
          case 'to_destination':
            title = 'গন্তব্যের দিকে যাচ্ছে';
            body = 'অ্যাম্বুলেন্স গন্তব্যের দিকে যাচ্ছে।';
            break;
          case 'completed':
            title = 'রাইড সম্পন্ন';
            body = 'আপনার রাইড সম্পন্ন হয়েছে।';
            break;
        }

        final success = await NotificationService.sendFCMNotification(
          token: fcmToken,
          title: title,
          body: body,
          data: {
            'type': 'status_update',
            'orderId': requestId,
            'status': status,
          },
        );

        if (success) {
        } else {}
      } else {}
    } catch (e) {}
  }

  // Live tracking functions
  void startLiveTracking({bool updateStatus = true}) async {
    if (isLiveTracking.value) return;

    isLiveTracking.value = true;

    // Update order status to in_transit only if requested and status is still accepted/confirmed
    if (requestData.value != null && updateStatus) {
      final status = requestData.value?['status']?.toString().toLowerCase();
      if (status == 'accepted' || status == 'confirmed') {
        final requestId = requestData.value!['id'];
        try {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(requestId)
              .update({
            'status': 'in_transit',
          });

          // Update local data
          requestData.value!['status'] = 'in_transit';
          requestData.refresh();

          // Send notification to user
          await _sendStatusChangeNotification('in_transit');
        } catch (e) {
          debugPrint('Error updating status to in_transit: $e');
        }
      }
    }

    // Start listening to position changes with optimized timing
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen(
      (Position position) {
        final newPosition = LatLng(position.latitude, position.longitude);
        partnerPosition.value = newPosition;

        // Update marker position immediately for smooth UI
        _updatePartnerMarker();

        // Debounced Firestore update
        _scheduleFirestoreUpdate(position);

        // Conditional camera update
        _scheduleCameraUpdate(position);

        // Periodic ETA update
        _scheduleETAUpdate();

        // Reduce debug print frequency (only every 10th update)
        if (DateTime.now().millisecondsSinceEpoch % 10000 < 1000) {}
      },
      onError: (error) {
        // Continue tracking even if there's an error
      },
    );

    _showSuccessDialog('Live Tracking Started',
        'Your location is now being tracked in real-time',
        duration: const Duration(seconds: 2));
  }

  void _scheduleFirestoreUpdate(Position position) {
    if (requestData.value == null || !isLiveTracking.value) return;

    final now = DateTime.now();
    final requestId = requestData.value!['id'];

    // Throttle check: Update if enough time passed (4s) OR moved significant distance (10m)
    final timePassed = _lastFirestoreUpdateTime == null ||
        now.difference(_lastFirestoreUpdateTime!) >= _firestoreUpdateInterval;

    final movedSignificantly = _lastFirestorePosition == null ||
        _calculateDistance(_lastFirestorePosition!, position) >= 10;

    if (timePassed || movedSignificantly) {
      // Avoid overlapping updates by checking if timer is already pending
      // or just send it if it's been long enough.
      // We'll use a direct async call here but prevent hammering.
      
      _lastFirestoreUpdateTime = now;
      _lastFirestorePosition = position;

      FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .update({
        'partnerLiveLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': Timestamp.now(),
        },
      }).catchError((e) {
        debugPrint('Error updating live location: $e');
      });
    }
  }

  void _scheduleCameraUpdate(Position position) {
    // Only update camera if moved significant distance or enough time passed
    final shouldUpdateCamera = _lastCameraPosition == null ||
        _calculateDistance(_lastCameraPosition!, position) >=
            _minDistanceForCameraUpdate;

    if (shouldUpdateCamera) {
      // Cancel existing timer
      _cameraUpdateTimer?.cancel();

      // Schedule camera update
      _cameraUpdateTimer = Timer(_cameraUpdateInterval, () {
        if (isLiveTracking.value) {
          _animateCameraToPosition(
              LatLng(position.latitude, position.longitude));
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
        cos(pos1.latitude * (pi / 180)) *
            cos(pos2.latitude * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _scheduleETAUpdate() {
    // Only update ETA if we don't have a pending timer
    if (_etaUpdateTimer?.isActive != true) {
      // Schedule ETA update
      _etaUpdateTimer = Timer(_etaUpdateInterval, () {
        if (isLiveTracking.value &&
            partnerPosition.value != null &&
            userPosition.value != null) {
          calculateETA();
        }
      });
    }
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
    _etaUpdateTimer?.cancel();
    _etaUpdateTimer = null;
  }

  void _animateCameraToPosition(LatLng position) async {
    try {
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 16.0, // Appropriate zoom level for following
          ),
        ),
      );
    } catch (e) {
      debugPrint('🏁 AcceptMaps: _animateCameraToPosition failed: $e');
    }
  }

  Future<void> _animateCameraToShowRoute() async {
    if (partnerPosition.value != null && userPosition.value != null) {
      try {
        final GoogleMapController controller = await _controller.future;

        // Calculate bounds to show both partner and destination
        final double southWestLat = min(
          partnerPosition.value!.latitude,
          userPosition.value!.latitude,
        );
        final double southWestLng = min(
          partnerPosition.value!.longitude,
          userPosition.value!.longitude,
        );
        final double northEastLat = max(
          partnerPosition.value!.latitude,
          userPosition.value!.latitude,
        );
        final double northEastLng = max(
          partnerPosition.value!.longitude,
          userPosition.value!.longitude,
        );

        final LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(southWestLat, southWestLng),
          northeast: LatLng(northEastLat, northEastLng),
        );

        // Animate camera to show the complete route
        try {
          await controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100), // 100 pixels padding
          );
        } catch (e) {
          debugPrint('🏁 AcceptMaps: _animateCameraToShowRoute animateCamera failed: $e');
        }
      } catch (e) {
        debugPrint('🏁 AcceptMaps: _animateCameraToShowRoute failed: $e');
      }
    }
  }

  void _updatePartnerMarker() {
    if (partnerPosition.value != null) {
      // Create a new set with updated markers to trigger reactivity
      final updatedMarkers = Set<Marker>.from(markers);

      // Remove existing partner marker
      updatedMarkers
          .removeWhere((marker) => marker.markerId.value == 'partner_location');

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
        _showSuccessDialog(
            'Ride Cancelled', 'The ride has been cancelled successfully',
            navigateHome: true);
      }
    } catch (e) {
      _showSuccessDialog('Error', 'Failed to cancel ride: $e');
    }
  }

  void _showSuccessDialog(String title, String message,
      {String? orderId,
      bool navigateHome = false,
      Duration duration = const Duration(seconds: 2)}) {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            lottie.Lottie.asset('assets/success.json', width: 130, height: 130),
            SizedBox(height: 16),
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(message),
            if (orderId != null) Text('Order ID: $orderId'),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    // Auto close after duration
    Future.delayed(duration, () {
      if (Get.isDialogOpen ?? false) {
        if (navigateHome) {
          Get.offAll(() => HomePartnerPage());
        } else {
          Get.back();
        }
      }
    });
  }

  // Navigate back
  void goBack() {
    Get.back();
  }

  Future<void> updateOrderStatus(String status) async {
    if (requestData.value != null) {
      final requestId = requestData.value!['id'];
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(requestId)
            .update({'status': status});

        // Update local data
        requestData.value!['status'] = status;
        requestData.refresh();

        // Send notification to user about status change
        await _sendStatusChangeNotification(status);
      } catch (e) {}
    }
  }

  Future<void> generateAndSendPickupOTP() async {
    if (requestData.value == null) return;

    final requestId = requestData.value!['id'];
    final userId = requestData.value!['userId'];

    try {
      // Generate 4-digit OTP
      final otp = (1000 + Random().nextInt(9000)).toString();

      // Store OTP in order document
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .update({
        'pickupOTP': otp,
        'otpGeneratedAt': Timestamp.now(),
      });

      // Update local data with the generated OTP
      requestData.value!['pickupOTP'] = otp;
      requestData.value!['otpGeneratedAt'] = Timestamp.now();
      requestData.refresh();

      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Send notification with OTP
        final success = await NotificationService.sendFCMNotification(
          token: fcmToken,
          title: 'Pickup OTP',
          body: 'Your ambulance has arrived. OTP for pickup confirmation: $otp',
          data: {
            'type': 'pickup_otp',
            'orderId': requestId,
            'otp': otp,
          },
        );

        if (success) {
        } else {}
      } else {}
    } catch (e) {}
  }

  Future<bool> confirmPickupOTP(String enteredOTP) async {
    if (requestData.value == null) return false;

    final requestId = requestData.value!['id'];

    try {
      // Fetch the latest order data from Firestore to get the stored OTP
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .get();

      if (!orderDoc.exists) {
        return false;
      }

      final orderData = orderDoc.data()!;
      final storedOTP = orderData['pickupOTP'];

      if (storedOTP == null) {
        return false;
      }

      if (enteredOTP == storedOTP.toString()) {
        // Update order status to pickup (patient picked up)
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(requestId)
            .update({
          'status': 'pickup',
          'pickupConfirmedAt': Timestamp.now(),
        });

        // Update local data
        requestData.value!['status'] = 'pickup';
        requestData.value!['pickupConfirmedAt'] = Timestamp.now();
        requestData.refresh();

        // Send notification to user
        await _sendStatusChangeNotification('pickup');

        // Automatically start route to destination after pickup

        goToDestination();

        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> goToDestination() async {
    if (requestData.value == null) return;

    final requestId = requestData.value!['id'];

    try {
      // Update order status to indicate going to destination
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .update({
        'status': 'to_destination',
        'destinationStartedAt': Timestamp.now(),
      });

      // Update local data
      requestData.value!['status'] = 'to_destination';
      requestData.refresh();

      // Send notification to user
      await _sendStatusChangeNotification('to_destination');

      // Generate and send destination OTP - REMOVED as per requirement
      // await generateAndSendDestinationOTP();

      // Update destination location for routing
      if (requestData.value!['destinationLat'] != null &&
          requestData.value!['destinationLng'] != null) {
        final destinationLatLng = LatLng(
          requestData.value!['destinationLat'],
          requestData.value!['destinationLng'],
        );

        // Update user position to destination for new polyline
        userPosition.value = destinationLatLng;

        // Clear existing polylines and create new route to destination
        polylines.clear();
        await _createRouteToDestination();

        // Update markers to show destination
        _updateDestinationMarker();

        // Animate camera to show both current location and destination
        await _animateCameraToShowRoute();
      }
    } catch (e) {}
  }

  Future<void> _createRouteToDestination() async {
    if (partnerPosition.value != null && userPosition.value != null) {
      try {
        final origin =
            '${partnerPosition.value!.latitude},${partnerPosition.value!.longitude}';
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
          final polylinePoints = <LatLng>[];

          // Decode the polyline points
          for (var legItem in route.legs) {
            for (var step in legItem.steps) {
              final points = _decodePolyline(step.polyline.points);
              polylinePoints.addAll(points);
            }
          }

          // Update ETA and distance to destination
          final duration = leg.duration.text;
          final distance = leg.distance.value.toDouble();
          estimatedTime.value = duration;
          estimatedDistance.value = distance / 1000; // Convert to km

          // Create polyline to destination
          final polyline = Polyline(
            polylineId: PolylineId('destination_route'),
            points: polylinePoints,
            color: Colors.green, // Different color for destination route
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          );

          polylines.add(polyline);
        }
      } catch (e) {}
    }
  }

  void _updateDestinationMarker() {
    if (userPosition.value != null) {
      // Create a new set with updated markers
      final updatedMarkers = Set<Marker>.from(markers);

      // Remove existing user marker
      updatedMarkers
          .removeWhere((marker) => marker.markerId.value == 'user_location');

      // Add destination marker
      updatedMarkers.add(
        Marker(
          markerId: MarkerId('destination_location'),
          position: userPosition.value!,
          infoWindow: InfoWindow(title: 'Destination'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Reassign to trigger reactivity
      markers.assignAll(updatedMarkers);
    }
  }

  @override
  void onClose() {
    // Cancel all timers
    _firestoreUpdateTimer?.cancel();
    _cameraUpdateTimer?.cancel();
    _etaUpdateTimer?.cancel();

    // Cancel position and order subscriptions
    _positionSubscription?.cancel();
    _orderSubscription?.cancel();

    super.onClose();
  }
}
