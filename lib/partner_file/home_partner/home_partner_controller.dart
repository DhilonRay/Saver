import 'dart:async';
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
import 'package:shared_preferences/shared_preferences.dart';
import '../../about/about.dart';
import '../partner_orders/partners_orders_page.dart';
import '../../chat_page/sos_chat_page.dart';
import '../../auth/log_in/login_screen.dart';
import '../accept_maps/accept_maps.dart';
import '../../components/success_dialog.dart';
import '../../services/notification_service.dart';
import '../../services/fares_service.dart';
import 'package:intl/intl.dart';

class HomePartnerController extends GetxController {
  final bool isNewSignup;

  HomePartnerController({this.isNewSignup = false});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();

  // Dynamic ambulance rate (can be changed by partner)
  var serviceRate = 2500.obs; // Default 2500 TK for service

  // Default rate (fallback value)
  static const int defaultServiceRate = 2500;

  // Custom marker icons
  BitmapDescriptor currentLocationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor userLocationIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  // Reactive variables
  var currentPosition = Rx<LatLng?>(null);
  var markers = <Marker>{}.obs;
  var isLoadingLocation = true.obs;
  var isInitialLoading = true.obs;
  var mapError = ''.obs;
  
  // Online/Offline status
  var isOnline = true.obs;
  var partnerName = 'NeoSaver Partner'.obs;

  // Profile image
  var profileImageUrl = Rx<String?>(null);
  var isUploadingImage = false.obs;
  var uploadProgress = 0.0.obs; // Upload progress (0.0 to 1.0)

  // Ambulance requests
  var pendingRequests = <Map<String, dynamic>>[].obs;
  var showRequestBottomSheet = false.obs;
  var shownRequestIds =
      <String>{}.obs; // Track requests that have already been shown
  var declinedRequestIds =
      <String>{}.obs; // Track declined requests to prevent showing again
  StreamSubscription<QuerySnapshot>? _requestsSubscription;

  // Timer for periodic location updates (10 seconds)
  Timer? _locationUpdateTimer;

  // Helper function to format address display
  String _formatAddress(String? address) {
    if (address == null || address.isEmpty) {
      return 'Address not provided - contact patient';
    }

    // Check if it's coordinates format
    if (address.startsWith('Lat:') && address.contains('Lng:')) {
      return 'Location coordinates available - contact patient for details';
    }

    return address;
  }

  // Default position (Dhaka, Bangladesh) in case location fails
  static const LatLng defaultPosition = LatLng(23.8103, 90.4125);

  Future<void> _loadCustomIcons() async {
    try {
      debugPrint('Loading custom PNG icons for partner...');
      currentLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/markers/ambulance.png',
      );
      userLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      debugPrint('Partner custom icons loaded successfully');
    } catch (e) {
      debugPrint('Failed to load partner custom icons: $e');
      currentLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      userLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _loadPartnerRates() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        serviceRate.value = data['serviceRate'] ?? defaultServiceRate;
        debugPrint('✅ Loaded partner rate: Service=${serviceRate.value}');
      } else {
        // Use default rate if no custom rate set
        serviceRate.value = defaultServiceRate;
        debugPrint('ℹ️ Using default rate for new partner');
      }
    } catch (e) {
      debugPrint('❌ Error loading partner rates: $e');
      // Use default rates on error
      serviceRate.value = defaultServiceRate;
    }
  }

  Future<void> _loadPartnerName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        partnerName.value =
            data['name'] ?? user.displayName ?? 'NeoSaver Partner';
        debugPrint('✅ Loaded partner name: ${partnerName.value}');
      } else {
        partnerName.value = user.displayName ?? 'NeoSaver Partner';
        debugPrint('ℹ️ Using display name or default for partner name');
      }
    } catch (e) {
      debugPrint('❌ Error loading partner name: $e');
      partnerName.value = _auth.currentUser?.displayName ?? 'NeoSaver Partner';
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        profileImageUrl.value = data['profileImageUrl'];
        debugPrint(
            '✅ Loaded profile image: ${profileImageUrl.value != null ? 'Yes' : 'No'}');
      }
    } catch (e) {
      debugPrint('❌ Error loading profile image: $e');
    }
  }

  // Profile Image Methods
  Future<void> pickAndUploadProfileImage() async {
    try {
      debugPrint('🖼️ Starting gallery image selection');

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
        maxWidth: 256, // Reduced from 512 for faster upload
        maxHeight: 256, // Reduced from 512 for faster upload
        imageQuality: 60, // Reduced from 75 for faster upload
      );

      if (image != null) {
        debugPrint('📁 Image selected from gallery: ${image.path}');
        // Check file size and compress further if needed
        final compressedImage = await _ultraFastCompress(File(image.path));
        await uploadProfileImage(compressedImage);
      } else {
        debugPrint('❌ No image selected from gallery');
      }
    } catch (e) {
      debugPrint('❌ Error picking image from gallery: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image from gallery. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickAndUploadProfileImageFromCamera() async {
    try {
      debugPrint('📷 Starting camera image capture');

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
        maxWidth: 256, // Reduced from 512 for faster upload
        maxHeight: 256, // Reduced from 512 for faster upload
        imageQuality: 60, // Reduced from 75 for faster upload
      );

      if (image != null) {
        debugPrint('📸 Image captured from camera: ${image.path}');
        // Check file size and compress further if needed
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

      // Upload the file with progress monitoring
      final uploadTask = storageRef.putFile(imageFile);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        uploadProgress.value = progress;
        debugPrint(
            '📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
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
            .collection('partners')
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
          .collection('partners')
          .doc(user.uid)
          .update({
        'profileImageUrl': FieldValue.delete(),
      });

      // Update local state
      profileImageUrl.value = null;

      debugPrint('🗑️ Profile image removed successfully');
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

  Future<void> updatePartnerRates(int newServiceRate) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'You must be logged in to update rates',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }

      // Validate rate
      if (newServiceRate < 1000) {
        Get.snackbar(
          'Invalid Rate',
          'Service rate must be at least ৳1,000',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .update({
        'serviceRate': newServiceRate,
        'ratesLastUpdated': Timestamp.now(),
      });

      // Update local reactive variable
      serviceRate.value = newServiceRate;

      Get.snackbar(
        'Success',
        'Rate updated successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      debugPrint('✅ Partner rate updated: Service=${newServiceRate}');
    } catch (e) {
      debugPrint('❌ Error updating partner rates: $e');
      Get.snackbar(
        'Error',
        'Failed to update rate: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void showRateChangeDialog() {
    int tempServiceRate = serviceRate.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Update Service Rate'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set your ambulance service rate. This rate will be shown to users when they book your services.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Service Rate (৳)',
                    hintText: 'Minimum 1000',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller:
                      TextEditingController(text: tempServiceRate.toString()),
                  onChanged: (value) {
                    tempServiceRate = int.tryParse(value) ?? tempServiceRate;
                  },
                ),
                const SizedBox(height: 20),
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
              updatePartnerRates(tempServiceRate);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Rate'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _fetchPartnerRates() async {
    return {'serviceRate': serviceRate.value};
  }

  @override
  void onInit() {
    super.onInit();
    _loadCustomIcons();
    _getCurrentLocation();
    _loadDeclinedRequestIds(); // Load previously declined requests
    _listenForRequests();
    _loadPartnerRates(); // Load partner's custom rates
    _loadPartnerName(); // Load partner's name
    _loadProfileImage(); // Load partner's profile image
    _loadInitialOnlineStatus(); // Load online/offline status

    // Debug: Check for existing orders after a delay
    Future.delayed(const Duration(seconds: 3), () {
      _debugCheckOrders();
    });

    // Start periodic location updates every 10 seconds
    _startLocationUpdateTimer();

    // Show success dialog for new driver signups
    if (isNewSignup) {
      Future.delayed(const Duration(milliseconds: 500), () {
        SuccessDialog.show(
          title: 'Welcome to NeoSaver Partner!',
          message:
              'Your driver account has been created successfully. You can now start accepting ambulance requests.',
        );
      });
    }
  }

  @override
  void onClose() {
    _requestsSubscription?.cancel();
    _locationUpdateTimer?.cancel(); // Cancel location update timer
    shownRequestIds.clear(); // Clear shown requests when controller closes
    // Don't clear declinedRequestIds - they should persist across sessions
    super.onClose();
  }

  /// Start periodic location updates every 10 seconds
  void _startLocationUpdateTimer() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateCurrentLocation();
    });
    debugPrint('📍 Started location update timer (10 second interval)');
  }

  /// Update current location silently (without loading indicators)
  Future<void> _updateCurrentLocation() async {
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
          infoWindow: InfoWindow(title: 'Your Ambulance Location'),
          icon: currentLocationIcon,
        ),
      );

      // Update location in Firestore if online
      if (isOnline.value) {
        await _updatePartnerLocation();
      }

      debugPrint('📍 Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
    }
  }

  /// Reset shown requests (useful when driver logs out and logs back in)
  void resetShownRequests() {
    shownRequestIds.clear();
    showRequestBottomSheet.value = false;
  }

  /// Load declined request IDs from shared preferences
  Future<void> _loadDeclinedRequestIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      if (user != null) {
        final key = 'declined_requests_${user.uid}';
        final declinedIds = prefs.getStringList(key) ?? [];
        declinedRequestIds.addAll(declinedIds);
        debugPrint('✅ Loaded ${declinedIds.length} declined request IDs');
      }
    } catch (e) {
      debugPrint('❌ Error loading declined request IDs: $e');
    }
  }

  /// Save declined request IDs to shared preferences
  Future<void> _saveDeclinedRequestIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      if (user != null) {
        final key = 'declined_requests_${user.uid}';
        await prefs.setStringList(key, declinedRequestIds.toList());
        debugPrint('✅ Saved ${declinedRequestIds.length} declined request IDs');
      }
    } catch (e) {
      debugPrint('❌ Error saving declined request IDs: $e');
    }
  }

  // Format a fare value to localized currency string (no decimal places)
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

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

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
          infoWindow: InfoWindow(title: 'Your Ambulance Location'),
          icon: currentLocationIcon,
        ),
      );

      // Update partner location in Firestore
      await _updatePartnerLocation();

      isLoadingLocation.value = false;
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

      isLoadingLocation.value = false;
      isInitialLoading.value = false;
    }
  }

  Future<void> _updatePartnerLocation() async {
    try {
      final user = _auth.currentUser;
      if (user != null && currentPosition.value != null) {
        await FirebaseFirestore.instance
            .collection('partners')
            .doc(user.uid)
            .update({
          'latitude': currentPosition.value!.latitude,
          'longitude': currentPosition.value!.longitude,
          'lastUpdated': Timestamp.now(),
          'isOnline': isOnline.value, // Use the observable value
        });
      }
    } catch (e) {
      debugPrint('Failed to update partner location: $e');
    }
  }

  void _listenForRequests() {
    debugPrint('🚀 _listenForRequests() method called - Starting setup...');
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user for listening to requests');
        return;
      }

      debugPrint('🔍 Setting up request listener for partner: ${user.uid}');
      debugPrint('🔍 Querying orders collection with: type=ambulance, status=pending, partnerId=${user.uid}');

      _requestsSubscription = FirebaseFirestore.instance
          .collection('orders')
          .where('type', isEqualTo: 'ambulance')
          .where('status', isEqualTo: 'pending')
          .where('partnerId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        debugPrint('📡 Request listener triggered - found ${snapshot.docs.length} documents');
        
        // Log each document for debugging
        for (var doc in snapshot.docs) {
          final data = doc.data();
          debugPrint('📄 Document ${doc.id}: status=${data['status']}, type=${data['type']}, partnerId=${data['partnerId']}');
        }

        // Filter out declined requests
        final allRequests = snapshot.docs
            .map((doc) {
              return {
                'id': doc.id,
                ...doc.data(),
              };
            })
            .where((request) => !declinedRequestIds.contains(request['id']))
            .toList();

        pendingRequests.value = allRequests;
        debugPrint('📋 Filtered pending requests: ${allRequests.length} (after excluding ${declinedRequestIds.length} declined)');

        // Show bottom sheet if there are pending requests that haven't been shown yet and aren't declined
        final newRequests = pendingRequests
            .where((request) => 
                !shownRequestIds.contains(request['id']) &&
                !declinedRequestIds.contains(request['id']))
            .toList();

        debugPrint('🆕 New requests to show: ${newRequests.length}');
        debugPrint('🚫 Already shown: ${shownRequestIds.length}, Declined: ${declinedRequestIds.length}');
        debugPrint('📱 Bottom sheet currently showing: ${showRequestBottomSheet.value}');

        if (newRequests.isNotEmpty && !showRequestBottomSheet.value) {
          final firstNewRequest = newRequests.first;
          shownRequestIds.add(firstNewRequest['id']); // Mark as shown
          showRequestBottomSheet.value = true;
          debugPrint('🔔 Showing bottom sheet for new request: ${firstNewRequest['id']}');
          debugPrint('👤 Patient: ${firstNewRequest['patientName']}, Phone: ${firstNewRequest['phone']}');
          _showRequestBottomSheet(firstNewRequest);
        } else if (newRequests.isEmpty) {
          debugPrint('ℹ️ No new requests to show');
        } else {
          debugPrint('⏳ Bottom sheet already showing, queuing request');
        }
      }, onError: (error) {
        debugPrint('❌ Error in request listener: $error');
        debugPrint('❌ Error type: ${error.runtimeType}');
        
        // Check for network connectivity issues
        if (error.toString().contains('UNAVAILABLE') || 
            error.toString().contains('firestore.googleapis.com') ||
            error.toString().contains('Unable to resolve host')) {
          debugPrint('🌐 Network connectivity issue detected. Firestore offline mode will handle sync when connection returns.');
        }
      });
    } catch (e) {
      debugPrint('❌ Failed to set up request listener: $e');
    }
  }

  void _showRequestBottomSheet(Map<String, dynamic> request) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with emergency icon
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade200.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emergency,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'অ্যাম্বুলেন্স অনুরোধ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'জরুরী সেবা প্রয়োজন',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Patient Information Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person,
                            color: Colors.blue.shade700, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'রোগীর তথ্য',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.person_outline,
                      'নাম',
                      request['patientName'] ?? 'নাম প্রদান করা হয়নি',
                      Colors.blue.shade700,
                    ),
                    _buildInfoRow(
                      Icons.phone,
                      'ফোন',
                      request['phone'] ?? 'ফোন নম্বর নেই - ইমেইল চেক করুন',
                      Colors.blue.shade700,
                    ),
                    if (request['email'] != null &&
                        request['email'].toString().isNotEmpty)
                      _buildInfoRow(
                        Icons.email,
                        'ইমেইল',
                        request['email'],
                        Colors.blue.shade700,
                      ),
                    if (request['patientAge'] != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        'বয়স',
                        '${request['patientAge']} বছর',
                        Colors.blue.shade700,
                      ),
                    if (request['bloodGroup'] != null)
                      _buildInfoRow(
                        Icons.bloodtype,
                        'রক্তের গ্রুপ',
                        request['bloodGroup'],
                        Colors.blue.shade700,
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Location Information Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.blue.shade700, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'অবস্থান তথ্য',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.location_city,
                      'অবস্থান',
                      _formatAddress(request['pickupAddress']),
                      Colors.blue.shade700,
                    ),
                    if (request['detailedAddress'] != null &&
                        request['detailedAddress'].toString().isNotEmpty)
                      _buildInfoRow(
                        Icons.home,
                        'বিস্তারিত ঠিকানা',
                        request['detailedAddress'],
                        Colors.blue.shade700,
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Medical Information Card (if available)
              if (request['currentCondition'] != null ||
                  request['medicalHistory'] != null ||
                  request['allergies'] != null)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_services,
                              color: Colors.blue.shade700, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'চিকিৎসা তথ্য',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (request['currentCondition'] != null)
                        _buildInfoRow(
                          Icons.warning,
                          'বর্তমান অসুস্থতা',
                          request['currentCondition'],
                          Colors.blue.shade700,
                        ),
                      if (request['medicalHistory'] != null)
                        _buildInfoRow(
                          Icons.history,
                          'চিকিৎসা ইতিহাস',
                          request['medicalHistory'],
                          Colors.blue.shade700,
                        ),
                      if (request['allergies'] != null)
                        _buildInfoRow(
                          Icons.warning_amber,
                          'অ্যালার্জি',
                          request['allergies'],
                          Colors.blue.shade700,
                        ),
                    ],
                  ),
                ),

              SizedBox(height: 16),

              // Fare Information Card
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade300, width: 1.5),
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
                    SizedBox(height: 16),
                    // CRITICAL: Always show the exact stored amount that was agreed upon
                    // Do not recalculate - this causes fare mismatches
                    Builder(
                      builder: (context) {
                        // First priority: Check if we have stored totalAmount from user's booking
                        // Try multiple possible field names for the fare amount
                        final storedTotalAmount =
                            request['totalAmount'] as double? ??
                                request['fareAmount'] as double? ??
                                (request['fareAmount'] as int?)?.toDouble();
                        final storedFareDetails =
                            request['fareDetails'] as Map<String, dynamic>?;

                        // Debug: Print all available fields to understand data structure
                        debugPrint(
                            '🔍 Request data fields: ${request.keys.toList()}');
                        debugPrint('💰 totalAmount: ${request['totalAmount']}');
                        debugPrint('💰 fareAmount: ${request['fareAmount']}');
                        debugPrint('💰 fareDetails: ${request['fareDetails']}');
                        debugPrint(
                            '💰 Final storedTotalAmount: $storedTotalAmount');

                        // PRIORITY 1: Check fareDetails first (this contains user's original calculation)
                        if (storedFareDetails != null) {
                          final fareFromDetails =
                              storedFareDetails['totalFare'] as double? ??
                                  storedFareDetails['totalAmount'] as double? ??
                                  (storedFareDetails['totalFare'] as int?)
                                      ?.toDouble() ??
                                  (storedFareDetails['totalAmount'] as int?)
                                      ?.toDouble();

                          debugPrint(
                              '🎯 Fare from fareDetails: $fareFromDetails');

                          if (fareFromDetails != null && fareFromDetails > 0) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Distance info if available
                                  if (storedFareDetails['distance'] != null)
                                    Row(
                                      children: [
                                        Icon(Icons.straighten,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(storedFareDetails['distance'] as double).toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.access_time,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '~${(storedFareDetails['estimatedTime'] as double? ?? 0).toStringAsFixed(0)} min',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  if (storedFareDetails['distance'] != null)
                                    const SizedBox(height: 12),

                                  // Fare breakdown if available
                                  if (storedFareDetails['breakdown'] !=
                                      null) ...[
                                    const Text(
                                      'মূল ভাড়ার বিবরণ:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...((storedFareDetails['breakdown']
                                            as Map<String, dynamic>)
                                        .entries
                                        // Remove subtotal, surge, and multiplier entries for clarity
                                        .where((entry) =>
                                            !entry.key
                                                .toLowerCase()
                                                .contains('subtotal') &&
                                            !entry.key
                                                .toLowerCase()
                                                .contains('surge') &&
                                            !entry.key
                                                .toLowerCase()
                                                .contains('multiplier'))
                                        .map((entry) {
                                      final label = _friendlyFareKey(entry.key);
                                      String valueText;
                                      // For multiplier-like entries, show a simple × multiplier with note for normal
                                      if (entry.key
                                              .toLowerCase()
                                              .contains('multiplier') ||
                                          entry.key
                                              .toLowerCase()
                                              .contains('surge') ||
                                          entry.key
                                              .toLowerCase()
                                              .contains('urgency')) {
                                        final num? rawNum = entry.value is num
                                            ? entry.value as num
                                            : num.tryParse(
                                                entry.value?.toString() ?? '');

                                        if (rawNum != null) {
                                          valueText =
                                              '×${rawNum.toStringAsFixed(1)}';
                                          if (rawNum == 1.0)
                                            valueText += ' (নিয়মিত)';
                                        } else {
                                          valueText =
                                              entry.value?.toString() ?? '';
                                        }
                                      } else {
                                        valueText = _formatFare(entry.value);
                                      }

                                      // Use standardized breakdown row style
                                      return _buildBreakdownRow(
                                          label, valueText,
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
                                    }).toList()),
                                    // Add per-km rate if we can compute it (distance cost / distance)
                                    if (storedFareDetails['distance'] != null)
                                      (() {
                                        try {
                                          final distance =
                                              (storedFareDetails['distance']
                                                      as num)
                                                  .toDouble();
                                          // Try find a distance charge key
                                          final distanceEntries =
                                              (storedFareDetails['breakdown']
                                                      as Map<String, dynamic>)
                                                  .entries
                                                  .where((e) =>
                                                      e.key
                                                          .toLowerCase()
                                                          .contains(
                                                              'distance') &&
                                                      (e.value is num ||
                                                          double.tryParse(e
                                                                      .value
                                                                      ?.toString() ??
                                                                  '') !=
                                                              null))
                                                  .toList();

                                          if (distanceEntries.isNotEmpty &&
                                              distance > 0) {
                                            final distanceEntry =
                                                distanceEntries.first;
                                            final distCharge = distanceEntry
                                                    .value is num
                                                ? (distanceEntry.value as num)
                                                    .toDouble()
                                                : double.tryParse(distanceEntry
                                                        .value
                                                        .toString()) ??
                                                    0.0;
                                            final ratePerKm =
                                                distCharge / distance;

                                            return _buildBreakdownRow(
                                              'প্রতি কিমি মূল্য',
                                              '${_formatFare(ratePerKm)}/কিমি',
                                              valueColor: Colors.green.shade700,
                                              icon: Icons.straighten,
                                            );
                                          }
                                        } catch (_) {}
                                        return const SizedBox.shrink();
                                      }()),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                  ],

                                  // Total amount from fareDetails - EXACT USER AMOUNT
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: const Text(
                                            '💰 সম্মত ভাড়া',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1976D2),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatFare(fareFromDetails),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1976D2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }

                        // PRIORITY 2: Check direct totalAmount/fareAmount fields
                        if (storedTotalAmount != null &&
                            storedTotalAmount > 0) {
                          // We have the exact amount the user was quoted - USE THIS!
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Distance info if available
                                if (storedFareDetails != null &&
                                    storedFareDetails['distance'] != null)
                                  Row(
                                    children: [
                                      Icon(Icons.straighten,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(storedFareDetails['distance'] as double).toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.access_time,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '~${(storedFareDetails['estimatedTime'] as double? ?? 0).toStringAsFixed(0)} min',
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                if (storedFareDetails != null &&
                                    storedFareDetails['distance'] != null)
                                  const SizedBox(height: 12),

                                // Fare breakdown if available
                                if (storedFareDetails != null &&
                                    storedFareDetails['breakdown'] != null) ...[
                                  const Text(
                                    'ভাড়ার বিবরণ:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...((storedFareDetails['breakdown']
                                          as Map<String, dynamic>)
                                      .entries
                                      // Hide subtotal, surge, and multiplier keys for clarity
                                      .where((entry) =>
                                          !entry.key
                                              .toLowerCase()
                                              .contains('subtotal') &&
                                          !entry.key
                                              .toLowerCase()
                                              .contains('surge') &&
                                          !entry.key
                                              .toLowerCase()
                                              .contains('multiplier'))
                                      .map((entry) {
                                    final label = _friendlyFareKey(entry.key);
                                    String valueText;
                                    if (entry.key
                                            .toLowerCase()
                                            .contains('multiplier') ||
                                        entry.key
                                            .toLowerCase()
                                            .contains('surge') ||
                                        entry.key
                                            .toLowerCase()
                                            .contains('urgency')) {
                                      final num? rawNum = entry.value is num
                                          ? entry.value as num
                                          : num.tryParse(
                                              entry.value?.toString() ?? '');

                                      if (rawNum != null) {
                                        valueText =
                                            '×${rawNum.toStringAsFixed(1)}';
                                        if (rawNum == 1.0)
                                          valueText += ' (নিয়মিত)';
                                      } else {
                                        valueText =
                                            entry.value?.toString() ?? '';
                                      }
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
                                  }).toList()),
                                  // Add per-km rate if we can compute it (distance cost / distance)
                                  if (storedFareDetails['distance'] != null)
                                    (() {
                                      try {
                                        final distance =
                                            (storedFareDetails['distance']
                                                    as num)
                                                .toDouble();
                                        final distanceEntries =
                                            (storedFareDetails['breakdown']
                                                    as Map<String, dynamic>)
                                                .entries
                                                .where((e) =>
                                                    e.key
                                                        .toLowerCase()
                                                        .contains('distance') &&
                                                    (e.value is num ||
                                                        double.tryParse(e.value
                                                                    ?.toString() ??
                                                                '') !=
                                                            null))
                                                .toList();

                                        if (distanceEntries.isNotEmpty &&
                                            distance > 0) {
                                          final distanceEntry =
                                              distanceEntries.first;
                                          final distCharge =
                                              distanceEntry.value is num
                                                  ? (distanceEntry.value as num)
                                                      .toDouble()
                                                  : double.tryParse(
                                                          distanceEntry.value
                                                              .toString()) ??
                                                      0.0;
                                          final ratePerKm =
                                              distCharge / distance;

                                          return _buildBreakdownRow(
                                              'প্রতি কিমি মূল্য',
                                              '${_formatFare(ratePerKm)}/কিমি',
                                              valueColor: Colors.green.shade700,
                                              icon: Icons.straighten);
                                        }
                                      } catch (_) {}
                                      return const SizedBox.shrink();
                                    }()),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                ],

                                // THE CRITICAL FIX: Always show the stored total amount
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: const Text(
                                          '💰 সম্মত ভাড়া',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1976D2),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatFare(storedTotalAmount),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.amber.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info,
                                          size: 16,
                                          color: Colors.amber.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'এটাই ইউজারের কাছে চার্জ করা হয়েছে - পুনরায় গণনা করবেন না',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.amber.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // PRIORITY 3: Try to calculate fare if no stored amount exists
                        debugPrint(
                            '⚠️ No stored fare amount found, attempting calculation...');

                        // Try to get distance for calculation
                        final storedDistance = request['distance'] as double?;
                        double? calculatedDistance;

                        if (storedDistance != null) {
                          calculatedDistance = storedDistance;
                        } else if (request['destinationLat'] != null &&
                            request['destinationLng'] != null &&
                            request['pickupLat'] != null &&
                            request['pickupLng'] != null) {
                          calculatedDistance =
                              FareCalculationService.calculateDistance(
                            request['pickupLat'] as double,
                            request['pickupLng'] as double,
                            request['destinationLat'] as double,
                            request['destinationLng'] as double,
                          );
                        }

                        if (calculatedDistance != null &&
                            calculatedDistance > 0) {
                          // Calculate fare using base rates
                          final fareDetails =
                              FareCalculationService.estimateFare(
                            distanceKm: calculatedDistance,
                            serviceType: 'ambulance',
                            partnerRates: {
                              'serviceRate': 2500
                            }, // Use default base rate
                            urgency: request['urgency'] ?? 'normal',
                          );

                          debugPrint(
                              '📊 Calculated fare: ${_formatFare(fareDetails.totalFare)}');

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.calculate,
                                    color: Colors.blue.shade700, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'আনুমানিক ভাড়া',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatFare(fareDetails.totalFare),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${calculatedDistance.toStringAsFixed(1)} কিমি এর জন্য গণনা করা',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning,
                                          size: 16, color: Colors.red.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'সংরক্ষিত ইউজার ভাড়া পাওয়া যায়নি - ইউজারের সাথে পরিমাণ নিশ্চিত করুন',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Final fallback - no fare data available at all
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.error,
                                  color: Colors.blue.shade700, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'ভাড়ার তথ্য পাওয়া যায়নি',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'এই রিকুয়েস্ট গ্রহণ করার আগে ইউজারের সাথে ভাড়ার পরিমাণ নিশ্চিত করুন',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
              if (request['destinationAddress'] != null &&
                  request['destinationAddress'].toString().isNotEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag,
                              color: Colors.blue.shade700, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'গন্তব্য তথ্য',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.location_on,
                        'গন্তব্য ঠিকানা',
                        request['destinationAddress'],
                        Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                    Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          declineRequest(request['id']);
                        },
                        icon: Icon(Icons.cancel, size: 24),
                        label: Text(
                          'প্রত্যাখ্যান',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.red.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          acceptRequest(request['id']);
                        },
                        icon: Icon(Icons.check_circle, size: 24),
                        label: Text(
                          'গ্রহণ করুন',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.green.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                 
                
                ],
              ),

              SizedBox(height: 16),

              // Emergency Contact Info
              if (request['emergencyContact'] != null)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.contact_emergency,
                          color: Colors.blue.shade700, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'জরুরী যোগাযোগ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              request['emergencyContact'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          SizedBox(width: 12),
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
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.back();
        return;
      }

      // Get the request data before updating status (since it will be filtered out)
      final request =
          pendingRequests.firstWhere((req) => req['id'] == requestId);

      // Use the already stored totalAmount from user's original booking
      // Don't recalculate - use what was already agreed upon
      final storedTotalAmount = request['totalAmount'] as double?;

      final updateData = {
        'status': 'accepted',
        'acceptedBy': user.uid,
        'acceptedAt': Timestamp.now(),
      };

      // Add partner's current location if available
      if (currentPosition.value != null) {
        updateData['partnerLocation'] = {
          'latitude': currentPosition.value!.latitude,
          'longitude': currentPosition.value!.longitude,
        };
      }

      // Use the stored fare amount if available, otherwise keep existing fareAmount
      if (storedTotalAmount != null) {
        updateData['fareAmount'] = storedTotalAmount.toInt();
        debugPrint(
            '✅ Using stored total amount: ৳${storedTotalAmount.toInt()}');
      } else {
        // Fallback: calculate fare only if no stored amount exists
        double? fareAmount;
        final rates = await _fetchPartnerRates();
        final storedDistance = request['distance'] as double?;

        // Calculate distance if not stored
        double? calculatedDistance;
        if (storedDistance != null) {
          calculatedDistance = storedDistance;
        } else if (request['destinationLat'] != null &&
            request['destinationLng'] != null &&
            request['pickupLat'] != null &&
            request['pickupLng'] != null) {
          calculatedDistance = FareCalculationService.calculateDistance(
            request['pickupLat'] as double,
            request['pickupLng'] as double,
            request['destinationLat'] as double,
            request['destinationLng'] as double,
          );
        }

        // Calculate final fare if distance is available
        if (calculatedDistance != null && calculatedDistance > 0) {
          final fareDetails = FareCalculationService.estimateFare(
            distanceKm: calculatedDistance,
            serviceType: 'ambulance',
            partnerRates: rates,
            urgency: request['urgency'] ?? 'normal',
          );
          fareAmount = fareDetails.totalFare;
          updateData['fareAmount'] = fareAmount.toInt();
        }

        debugPrint('✅ Calculated fallback fare amount: ৳$fareAmount');
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .update(updateData);

      showRequestBottomSheet.value = false;
      debugPrint('✅ Request accepted: $requestId');

      // Fetch the updated request data from Firestore
      final updatedDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .get();
      
      final updatedRequest = {'id': requestId, ...updatedDoc.data()!};
      debugPrint('✅ Updated request status: ${updatedRequest['status']}');

      // Send notification to user
      final userId = request['userId'];
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final fcmToken = userDoc.data()?['fcmToken'];
        if (fcmToken != null) {
          await NotificationService.sendFCMNotification(
            token: fcmToken,
            title: 'Order Accepted',
            body: 'Your order has been accepted. The ambulance is on the way.',
            data: {'type': 'order_accepted', 'orderId': requestId},
          );
        }
      }

      // Navigate to accept maps page with updated request data
      debugPrint(
          'HomePartner: Passing serviceRate to AcceptMaps: ${serviceRate.value}');

      // Navigate to accept maps page with request data
      Get.to(() => AcceptMapsPage(),
          arguments: {'request': updatedRequest, 'serviceRate': serviceRate.value});
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept request: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      // First, get the request data to find userId
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .get();

      if (!doc.exists) {
        Get.snackbar(
          'Error',
          'Request not found',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        Get.back();
        return;
      }

      final requestData = doc.data()!;
      final userId = requestData['userId'];

      // Add to declined list and save to preferences
      declinedRequestIds.add(requestId);
      await _saveDeclinedRequestIds();

      // Update status to declined
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .update({
        'status': 'declined',
        'declinedAt': Timestamp.now(),
        'declinedBy': _auth.currentUser?.uid,
      });

      // Send notification to user if userId exists
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final fcmToken = userDoc.data()?['fcmToken'];
        if (fcmToken != null) {
          await NotificationService.sendFCMNotification(
            token: fcmToken,
            title: 'অর্ডার বাতিল',
            body: 'আপনার অ্যাম্বুলেন্স রিকুয়েস্ট বাতিল করা হয়েছে',
            data: {'type': 'order_cancelled', 'orderId': requestId},
          );
        }
      }

      showRequestBottomSheet.value = false;
      debugPrint('❌ Request declined and saved: $requestId');

      Get.snackbar(
        'Success',
        'Request declined',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to decline request: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Fetch request from Firestore and show bottom sheet
  Future<void> _fetchAndShowRequest(String orderId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        final request = {
          'id': doc.id,
          ...doc.data()!,
        };

        // Mark as shown and show bottom sheet
        shownRequestIds.add(orderId);
        showRequestBottomSheet.value = true;
        _showRequestBottomSheet(request);
        debugPrint('🔔 Showing bottom sheet for fetched request: $orderId');
      } else {
        Get.snackbar(
          'Request Not Found',
          'The requested ambulance request could not be found',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching request $orderId: $e');
      Get.snackbar(
        'Error',
        'Failed to load request details: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Debug method to check orders in database
  Future<void> _debugCheckOrders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user for debug check');
        return;
      }

      debugPrint('🔍 DEBUG: Checking orders for partner: ${user.uid}');

      // Check all orders in the collection
      final allOrders = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      
      debugPrint('📊 Total orders in database: ${allOrders.docs.length}');

      // Check orders with this partner ID
      final partnerOrders = allOrders.docs.where((doc) {
        final data = doc.data();
        return data['partnerId'] == user.uid;
      }).toList();

      debugPrint('🎯 Orders for this partner: ${partnerOrders.length}');

      // Check pending ambulance orders for this partner
      final pendingAmbulance = partnerOrders.where((doc) {
        final data = doc.data();
        return data['type'] == 'ambulance' && data['status'] == 'pending';
      }).toList();

      debugPrint('🚑 Pending ambulance orders for this partner: ${pendingAmbulance.length}');

      // Log details of pending orders
      for (var doc in pendingAmbulance) {
        final data = doc.data();
        debugPrint('📋 Pending Order ${doc.id}: patient=${data['patientName']}, phone=${data['phone']}, urgency=${data['urgency']}');
      }

      // Check if there are any orders for other partner IDs
      final otherPartnerOrders = allOrders.docs.where((doc) {
        final data = doc.data();
        final partnerId = data['partnerId'];
        return partnerId != null && partnerId != user.uid && data['status'] == 'pending';
      }).toList();

      debugPrint('👥 Pending orders for other partners: ${otherPartnerOrders.length}');

      if (pendingAmbulance.isNotEmpty) {
        debugPrint('✅ Found pending orders! Bottom sheet should show.');
        // Force show the first one if not already showing
        if (!showRequestBottomSheet.value && pendingAmbulance.isNotEmpty) {
          final firstOrder = pendingAmbulance.first;
          final request = {
            'id': firstOrder.id,
            ...firstOrder.data(),
          };
          debugPrint('🔔 Force showing bottom sheet for debug');
          _showRequestBottomSheet(request);
        }
      } else {
        debugPrint('❌ No pending orders found for this partner');
      }

    } catch (e) {
      debugPrint('❌ Debug check failed: $e');
    }
  }





  /// Show bottom sheet for a specific request (used when notification is clicked)
  void showBottomSheetForRequest(String orderId) {
    try {
      // Find the request in pending requests
      final request =
          pendingRequests.firstWhereOrNull((req) => req['id'] == orderId);

      if (request != null) {
        // Mark as shown and show bottom sheet
        shownRequestIds.add(orderId);
        showRequestBottomSheet.value = true;
        _showRequestBottomSheet(request);
        debugPrint(
            '🔔 Showing bottom sheet for notification-clicked request: $orderId');
      } else {
        // Request not found in pending requests, try to fetch it from Firestore
        _fetchAndShowRequest(orderId);
      }
    } catch (e) {
      debugPrint('❌ Error showing bottom sheet for request $orderId: $e');
      Get.snackbar(
        'Error',
        'Failed to show request details: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // Navigation methods
  void navigateToPartnersOrders() {
    Get.to(() => PartnersOrdersPage());
  }

  void navigateToAboutUs() {
    Get.to(() => AboutUsPage());
  }

  void navigateToSOSChat() {
    Get.to(() => const SOSChatPage());
  }

  Future<void> signOut() async {
    try {
      // Update online status to false
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('partners')
            .doc(user.uid)
            .update({
          'isOnline': false,
        });
      }

      await _auth.signOut();
      Get.offAll(() => LoginPage());
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: $e');
    }
  }

  /// Toggle online/offline status
  Future<void> toggleOnlineStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar(
          'ত্রুটি',
          'অনুগ্রহ করে লগইন করুন',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }

      // Show confirmation dialog when going offline
      if (isOnline.value) {
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
                SizedBox(width: 8),
                Text('অফলাইনে যেতে চান?'),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আপনি অফলাইনে গেলে:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text('• রোগীরা আপনার অ্যাম্বুলেন্স দেখতে পারবেন না'),
                Text('• নতুন রাইড রিকোয়েস্ট পাবেন না'),
                Text('• ম্যাপে আপনার অবস্থান দেখানো হবে না'),
                SizedBox(height: 12),
                Text(
                  'আপনি কি নিশ্চিত যে অফলাইনে যেতে চান?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    // ignore: sort_child_properties_last
                    child: Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      backgroundColor: Colors.red.shade100,
                      minimumSize: Size(120, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                   
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: Size(120, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text('Yes,Confirm'),
                  ),
                ],
              ),
            ],
          ),
        );

        if (confirmed != true) return; // User cancelled
      }

      // Toggle the local status first for immediate UI update
      isOnline.value = !isOnline.value;
      
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .update({
        'isOnline': isOnline.value,
        'lastStatusUpdate': Timestamp.now(),
      });

      

      debugPrint('✅ Partner status updated to: ${isOnline.value ? "Online" : "Offline"}');
    } catch (e) {
      // Revert the local status if Firestore update failed
      isOnline.value = !isOnline.value;
      
    
      debugPrint('❌ Error updating online status: $e');
    }
  }

  /// Load initial online status from Firestore
  Future<void> _loadInitialOnlineStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        isOnline.value = data['isOnline'] ?? true;
        debugPrint('✅ Initial online status loaded: ${isOnline.value}');
      }
    } catch (e) {
      debugPrint('❌ Error loading initial online status: $e');
      // Default to online if there's an error
      isOnline.value = true;
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

  // Method to show route to user location (for accepted requests)
  Future<void> showRouteToUser(double latitude, double longitude) async {
    try {
      final userLatLng = LatLng(latitude, longitude);

      // Add user location marker
      markers.add(
        Marker(
          markerId: MarkerId('user_location_$latitude$longitude'),
          position: userLatLng,
          infoWindow: InfoWindow(title: 'Patient Location'),
          icon: userLocationIcon,
        ),
      );

      // Move camera to show both partner location and user location
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

      Get.snackbar(
        'Route Updated',
        'Patient location has been marked on the map',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to show route to user: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
