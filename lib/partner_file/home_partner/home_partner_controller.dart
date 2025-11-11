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
import '../../about/about.dart';
import '../partner_orders/partners_orders_page.dart';
import '../../chat_page/sos_chat_page.dart';
import '../../auth/log_in/login_screen.dart';
import '../accept_maps/accept_maps.dart';
import '../../components/success_dialog.dart';

class HomePartnerController extends GetxController {
  final bool isNewSignup;
  
  HomePartnerController({this.isNewSignup = false});
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();

  // Dynamic ambulance rates (can be changed by partner)
  var indoorCityRate = 2500.obs; // Default 2500 TK for indoor city
  var outdoorCityRate = 10000.obs; // Default 10000 TK for outdoor city

  // Default rates (fallback values)
  static const int defaultIndoorCityRate = 2500;
  static const int defaultOutdoorCityRate = 10000;

  // Custom marker icons
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  // Reactive variables
  var currentPosition = Rx<LatLng?>(null);
  var markers = <Marker>{}.obs;
  var isLoadingLocation = true.obs;
  var isInitialLoading = true.obs;
  var mapError = ''.obs;
  var partnerName = 'NeoSaver Partner'.obs;

  // Profile image
  var profileImageUrl = Rx<String?>(null);
  var isUploadingImage = false.obs;
  var uploadProgress = 0.0.obs; // Upload progress (0.0 to 1.0)

  // Ambulance requests
  var pendingRequests = <Map<String, dynamic>>[].obs;
  var showRequestBottomSheet = false.obs;
  var shownRequestIds = <String>{}.obs; // Track requests that have already been shown
  StreamSubscription<QuerySnapshot>? _requestsSubscription;

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
      userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      debugPrint('Partner custom icons loaded successfully');
    } catch (e) {
      debugPrint('Failed to load partner custom icons: $e');
      currentLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _loadPartnerRates() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('partners').doc(user.uid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        indoorCityRate.value = data['indoorCityRate'] ?? defaultIndoorCityRate;
        outdoorCityRate.value = data['outdoorCityRate'] ?? defaultOutdoorCityRate;
        debugPrint('✅ Loaded partner rates: Indoor=${indoorCityRate.value}, Outdoor=${outdoorCityRate.value}');
      } else {
        // Use default rates if no custom rates set
        indoorCityRate.value = defaultIndoorCityRate;
        outdoorCityRate.value = defaultOutdoorCityRate;
        debugPrint('ℹ️ Using default rates for new partner');
      }
    } catch (e) {
      debugPrint('❌ Error loading partner rates: $e');
      // Use default rates on error
      indoorCityRate.value = defaultIndoorCityRate;
      outdoorCityRate.value = defaultOutdoorCityRate;
    }
  }

  Future<void> _loadPartnerName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        partnerName.value = data['name'] ?? user.displayName ?? 'NeoSaver Partner';
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

      final doc = await FirebaseFirestore.instance.collection('partners').doc(user.uid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        profileImageUrl.value = data['profileImageUrl'];
        debugPrint('✅ Loaded profile image: ${profileImageUrl.value != null ? 'Yes' : 'No'}');
      }
    } catch (e) {
      debugPrint('❌ Error loading profile image: $e');
    }
  }

  // Profile Image Methods
  Future<void> pickAndUploadProfileImage() async {
    try {
      debugPrint('🖼️ Starting gallery image selection');

      // Request storage permission first
      final status = await Permission.photos.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Required',
          'Photo library access is required to select images. Please grant permission in settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,  // Reduced from 512 for faster upload
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
        maxWidth: 256,  // Reduced from 512 for faster upload
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
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${user.uid}/$fileName');

      debugPrint('📤 Starting profile image upload: $fileName');

      // Upload the file with progress monitoring
      final uploadTask = storageRef.putFile(imageFile);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        uploadProgress.value = progress;
        debugPrint('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      final snapshot = await uploadTask.whenComplete(() => debugPrint('✅ Upload task completed'));

      // Check if upload was successful
      if (snapshot.state == TaskState.success) {
        uploadProgress.value = 1.0; // Complete progress
        
        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('🔗 Download URL obtained: ${downloadUrl.substring(0, 50)}...');

        // Update Firestore with the new image URL
        await FirebaseFirestore.instance.collection('partners').doc(user.uid).update({
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
      if (e.toString().contains('network') || e.toString().contains('unavailable')) {
        errorMessage = 'Network error. Please check your connection and try again.';
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
      } else if (e.toString().contains('permission') || e.toString().contains('denied')) {
        errorMessage = 'Permission denied. Please grant storage permissions and try again.';
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
        height: profileImageUrl.value != null ? 280 : 240, // Dynamic height based on content
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
      await FirebaseFirestore.instance.collection('partners').doc(user.uid).update({
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
        minWidth: 180,  // Optimized size for speed vs quality
        minHeight: 180,
        quality: 45,    // Aggressive compression for speed
        rotate: 0,      // Skip rotation for speed
      );

      if (compressedBytes != null) {
        // Create a temporary file with compressed data
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/ultra_fast_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(compressedBytes);

        final originalSize = await imageFile.length();
        final compressedSize = await tempFile.length();
        final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);
        debugPrint('✅ Ultra-fast compression: ${compressionRatio.toStringAsFixed(1)}% size reduction');

        return tempFile;
      }

      return imageFile; // Return original if compression fails
    } catch (e) {
      debugPrint('❌ Error in ultra-fast compression: $e');
      return imageFile; // Return original on error
    }
  }

  // Retry upload with exponential backoff
  Future<void> _retryUpload(File imageFile, {int retryCount = 0, int maxRetries = 3}) async {
    const baseDelay = Duration(seconds: 1);

    try {
      await uploadProfileImage(imageFile);
    } catch (e) {
      if (retryCount < maxRetries && (e.toString().contains('network') || e.toString().contains('unavailable'))) {
        final delay = baseDelay * (1 << retryCount); // Exponential backoff
        debugPrint('🔄 Retrying upload in ${delay.inSeconds} seconds (attempt ${retryCount + 1}/${maxRetries})');

        await Future.delayed(delay);
        return _retryUpload(imageFile, retryCount: retryCount + 1, maxRetries: maxRetries);
      } else {
        rethrow; // Re-throw if max retries reached or non-network error
      }
    }
  }

  Future<void> updatePartnerRates(int newIndoorRate, int newOutdoorRate) async {
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

      // Validate rates
      if (newIndoorRate < 1000 || newOutdoorRate < 2000) {
        Get.snackbar(
          'Invalid Rates',
          'Indoor rate must be at least ৳1,000 and outdoor rate at least ৳2,000',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      if (newIndoorRate >= newOutdoorRate) {
        Get.snackbar(
          'Invalid Rates',
          'Outdoor rate must be higher than indoor rate',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('partners').doc(user.uid).update({
        'indoorCityRate': newIndoorRate,
        'outdoorCityRate': newOutdoorRate,
        'ratesLastUpdated': Timestamp.now(),
      });

      // Update local reactive variables
      indoorCityRate.value = newIndoorRate;
      outdoorCityRate.value = newOutdoorRate;

      Get.snackbar(
        'Success',
        'Rates updated successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      debugPrint('✅ Partner rates updated: Indoor=${newIndoorRate}, Outdoor=${newOutdoorRate}');
    } catch (e) {
      debugPrint('❌ Error updating partner rates: $e');
      Get.snackbar(
        'Error',
        'Failed to update rates: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void showRateChangeDialog() {
    int tempIndoorRate = indoorCityRate.value;
    int tempOutdoorRate = outdoorCityRate.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Update Ambulance Rates'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set your ambulance rates. These will be shown to users when they book your services.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Indoor City Rate (৳)',
                    hintText: 'Minimum 1000',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: tempIndoorRate.toString()),
                  onChanged: (value) {
                    tempIndoorRate = int.tryParse(value) ?? tempIndoorRate;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Outdoor City Rate (৳)',
                    hintText: 'Minimum 2000',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: tempOutdoorRate.toString()),
                  onChanged: (value) {
                    tempOutdoorRate = int.tryParse(value) ?? tempOutdoorRate;
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Tips:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('• Indoor: Within city limits', style: TextStyle(fontSize: 12)),
                      Text('• Outdoor: Outside city or long distance', style: TextStyle(fontSize: 12)),
                      Text('• Rates should reflect distance and urgency', style: TextStyle(fontSize: 12)),
                    ],
                  ),
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
              updatePartnerRates(tempIndoorRate, tempOutdoorRate);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Rates'),
          ),
        ],
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    _loadCustomIcons();
    _getCurrentLocation();
    _listenForRequests();
    _loadPartnerRates(); // Load partner's custom rates
    _loadPartnerName(); // Load partner's name
    _loadProfileImage(); // Load partner's profile image
    
    // Show success dialog for new driver signups
    if (isNewSignup) {
      Future.delayed(const Duration(milliseconds: 500), () {
        SuccessDialog.show(
          title: 'Welcome to NeoSaver Partner!',
          message: 'Your driver account has been created successfully. You can now start accepting ambulance requests.',
        );
      });
    }
  }

  @override
  void onClose() {
    _requestsSubscription?.cancel();
    shownRequestIds.clear(); // Clear shown requests when controller closes
    super.onClose();
  }

  /// Reset shown requests (useful when driver logs out and logs back in)
  void resetShownRequests() {
    shownRequestIds.clear();
    showRequestBottomSheet.value = false;
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
        await FirebaseFirestore.instance.collection('partners').doc(user.uid).update({
          'latitude': currentPosition.value!.latitude,
          'longitude': currentPosition.value!.longitude,
          'lastUpdated': Timestamp.now(),
          'isOnline': true,
        });
      }
    } catch (e) {
      debugPrint('Failed to update partner location: $e');
    }
  }

  void _listenForRequests() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _requestsSubscription = FirebaseFirestore.instance
          .collection('orders')
          .where('type', isEqualTo: 'ambulance')
          .where('status', isEqualTo: 'pending')
          .where('partnerId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        pendingRequests.value = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();

        // Show bottom sheet if there are pending requests that haven't been shown yet
        final newRequests = pendingRequests.where((request) => !shownRequestIds.contains(request['id'])).toList();
        
        if (newRequests.isNotEmpty && !showRequestBottomSheet.value) {
          final firstNewRequest = newRequests.first;
          shownRequestIds.add(firstNewRequest['id']); // Mark as shown
          showRequestBottomSheet.value = true;
          debugPrint('🔔 Showing bottom sheet for new request: ${firstNewRequest['id']}');
          _showRequestBottomSheet(firstNewRequest);
        }
      });
    } catch (e) {
      debugPrint('Failed to listen for requests: $e');
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
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emergency,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'অ্যাম্বুলেন্স অনুরোধ',
                            style: TextStyle(
                              fontSize: 22,
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

              SizedBox(height: 24),

              // Patient Information Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue.shade700, size: 24),
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
                      Colors.green.shade700,
                    ),
                    if (request['email'] != null && request['email'].toString().isNotEmpty)
                      _buildInfoRow(
                        Icons.email,
                        'ইমেইল',
                        request['email'],
                        Colors.orange.shade700,
                      ),
                    if (request['patientAge'] != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        'বয়স',
                        '${request['patientAge']} বছর',
                        Colors.purple.shade700,
                      ),
                    if (request['bloodGroup'] != null)
                      _buildInfoRow(
                        Icons.bloodtype,
                        'রক্তের গ্রুপ',
                        request['bloodGroup'],
                        Colors.red.shade700,
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Location Information Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green.shade700, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'অবস্থান তথ্য',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.location_city,
                      'অবস্থান',
                      _formatAddress(request['pickupAddress']),
                      Colors.green.shade700,
                    ),
                    if (request['detailedAddress'] != null && request['detailedAddress'].toString().isNotEmpty)
                      _buildInfoRow(
                        Icons.home,
                        'বিস্তারিত ঠিকানা',
                        request['detailedAddress'],
                        Colors.green.shade600,
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Medical Information Card (if available)
              if (request['currentCondition'] != null || request['medicalHistory'] != null || request['allergies'] != null)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_services, color: Colors.orange.shade700, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'চিকিৎসা তথ্য',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
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
                          Colors.red.shade700,
                        ),
                      if (request['medicalHistory'] != null)
                        _buildInfoRow(
                          Icons.history,
                          'চিকিৎসা ইতিহাস',
                          request['medicalHistory'],
                          Colors.orange.shade700,
                        ),
                      if (request['allergies'] != null)
                        _buildInfoRow(
                          Icons.warning_amber,
                          'অ্যালার্জি',
                          request['allergies'],
                          Colors.red.shade600,
                        ),
                    ],
                  ),
                ),

              SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => acceptRequest(request['id']),
                        icon: Icon(Icons.check_circle, size: 24),
                        label: Text(
                          'গ্রহণ করুন',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => declineRequest(request['id']),
                        icon: Icon(Icons.cancel, size: 24),
                        label: Text(
                          'প্রত্যাখ্যান',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                ],
              ),

              SizedBox(height: 16),

              // Emergency Contact Info
              if (request['emergencyContact'] != null)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.contact_emergency, color: Colors.red.shade700, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'জরুরী যোগাযোগ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                            Text(
                              request['emergencyContact'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade700,
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
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
      if (user == null) return;

      // Get the request data before updating status (since it will be filtered out)
      final request = pendingRequests.firstWhere((req) => req['id'] == requestId);

      await FirebaseFirestore.instance.collection('orders').doc(requestId).update({
        'status': 'accepted',
        'acceptedBy': user.uid,
        'acceptedAt': Timestamp.now(),
      });

      Get.back(); // Close bottom sheet
      showRequestBottomSheet.value = false;
      debugPrint('✅ Request accepted: $requestId');

      // Navigate to accept maps page with request data
      Get.to(() => AcceptMapsPage(), arguments: request);

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
      await FirebaseFirestore.instance.collection('orders').doc(requestId).update({
        'status': 'declined',
        'declinedAt': Timestamp.now(),
      });

      Get.back(); // Close bottom sheet
      showRequestBottomSheet.value = false;
      debugPrint('❌ Request declined: $requestId');

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
      final doc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      
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

  /// Show bottom sheet for a specific request (used when notification is clicked)
  void showBottomSheetForRequest(String orderId) {
    try {
      // Find the request in pending requests
      final request = pendingRequests.firstWhereOrNull((req) => req['id'] == orderId);

      if (request != null) {
        // Mark as shown and show bottom sheet
        shownRequestIds.add(orderId);
        showRequestBottomSheet.value = true;
        _showRequestBottomSheet(request);
        debugPrint('🔔 Showing bottom sheet for notification-clicked request: $orderId');
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
        await FirebaseFirestore.instance.collection('partners').doc(user.uid).update({
          'isOnline': false,
        });
      }

      await _auth.signOut();
      Get.offAll(() => LoginPage());
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: $e');
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
            latitude < currentPosition.value!.latitude ? latitude : currentPosition.value!.latitude,
            longitude < currentPosition.value!.longitude ? longitude : currentPosition.value!.longitude,
          ),
          northeast: LatLng(
            latitude > currentPosition.value!.latitude ? latitude : currentPosition.value!.latitude,
            longitude > currentPosition.value!.longitude ? longitude : currentPosition.value!.longitude,
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
