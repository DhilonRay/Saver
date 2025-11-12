import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../components/success_dialog.dart';

class PartnerProfileController extends GetxController {
  var isLoading = true.obs;
  var error = ''.obs;
  var personalInfo = <String, dynamic>{}.obs;
  var partnerInfo = <String, dynamic>{}.obs;
  var isEditing = false.obs;

  // Profile image
  var profileImageUrl = Rx<String?>(null);
  var isUploadingImage = false.obs;
  var uploadProgress = 0.0.obs; // Upload progress (0.0 to 1.0)

  // Location address
  var locationAddress = Rx<String?>(null);

  StreamSubscription<DocumentSnapshot>? _personalInfoSubscription;
  StreamSubscription<DocumentSnapshot>? _partnerInfoSubscription;

  @override
  void onInit() {
    super.onInit();
    _setupRealTimeListeners();
  }

  @override
  void onClose() {
    _personalInfoSubscription?.cancel();
    _partnerInfoSubscription?.cancel();
    super.onClose();
  }

  void _setupRealTimeListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      error.value = 'User not logged in.';
      isLoading.value = false;
      return;
    }

    // Set up real-time listener for personal info
    _personalInfoSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
      (userDoc) {
        if (userDoc.exists && userDoc.data() != null) {
          personalInfo.value = userDoc.data()!;
        } else {
          personalInfo.value = {
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'uid': user.uid,
          };
        }
        _checkLoadingComplete();
      },
      onError: (e) {
        personalInfo.value = {
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'uid': user.uid,
        };
        _checkLoadingComplete();
      },
    );

    // Set up real-time listener for partner info
    _partnerInfoSubscription = FirebaseFirestore.instance
        .collection('partners')
        .doc(user.uid)
        .snapshots()
        .listen(
      (doc) async {
        if (doc.exists && doc.data() != null) {
          partnerInfo.value = doc.data()!;
          profileImageUrl.value = doc.data()!['profileImageUrl'];

          // Convert coordinates to address if available
          final latitude = doc.data()!['latitude'];
          final longitude = doc.data()!['longitude'];
          if (latitude != null && longitude != null) {
            await _updateLocationAddress(latitude, longitude);
          } else {
            locationAddress.value = null;
          }
        } else {
          partnerInfo.value = {};
          profileImageUrl.value = null;
          locationAddress.value = null;
        }
        _checkLoadingComplete();
      },
      onError: (e) {
        partnerInfo.value = {};
        profileImageUrl.value = null;
        locationAddress.value = null;
        _checkLoadingComplete();
      },
    );
  }

  void _checkLoadingComplete() {
    if (personalInfo.isNotEmpty || partnerInfo.isNotEmpty) {
      isLoading.value = false;
      error.value = '';
    }
  }

  void restartListeners() {
    _personalInfoSubscription?.cancel();
    _partnerInfoSubscription?.cancel();
    _setupRealTimeListeners();
  }

  void toggleEditing() {
    isEditing.value = !isEditing.value;
  }

  Future<void> saveChanges() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if rates were changed and update timestamp
      bool ratesChanged = false;
      final originalIndoorRate = partnerInfo['indoorCityRate'];
      final originalOutdoorRate = partnerInfo['outdoorCityRate'];

      // Get current values from the map (these might have been updated by the UI)
      final currentIndoorRate = partnerInfo['indoorCityRate'];
      final currentOutdoorRate = partnerInfo['outdoorCityRate'];

      if (originalIndoorRate != currentIndoorRate ||
          originalOutdoorRate != currentOutdoorRate) {
        ratesChanged = true;
        partnerInfo['ratesLastUpdated'] = FieldValue.serverTimestamp();
        print(
            '💰 Rates updated - Indoor: $currentIndoorRate, Outdoor: $currentOutdoorRate');
      }

      // Update partner info in Firestore
      if (partnerInfo.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('partners')
            .doc(user.uid)
            .update(partnerInfo);
        print('✅ Partner info updated in Firestore');
      }

      // Update personal info in users collection
      if (personalInfo.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(personalInfo);
        print('✅ Personal info updated in Firestore');
      }

      isEditing.value = false;

      // Show appropriate success message
      if (ratesChanged) {
        SuccessDialog.show(
          title: 'Rates Updated',
          message:
              'Your indoor and outdoor city rates have been updated successfully! Users will see the new rates when making requests.',
        );
        print('📢 Rates update notification shown');
      } else {
        SuccessDialog.show(
          title: 'Profile Updated',
          message: 'Your profile information has been updated successfully!',
        );
        print('📢 General profile update notification shown');
      }
    } catch (e) {
      print('❌ Error saving changes: $e');
      Get.snackbar('Error', 'Failed to update profile: $e');
    }
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        String fileName = 'profile_${user.uid}.jpg';
        Reference ref =
            FirebaseStorage.instance.ref().child('profile_images/$fileName');
        await ref.putFile(file);
        String downloadUrl = await ref.getDownloadURL();
        personalInfo['profileImageUrl'] = downloadUrl;
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImageUrl': downloadUrl});
        SuccessDialog.show(
          title: 'Profile Picture Updated',
          message: 'Your profile picture has been updated successfully!',
        );
      } catch (e) {
        Get.snackbar('Error', 'Failed to upload image: $e');
      }
    }
  }

  // Profile Image Methods
  Future<void> pickAndUploadProfileImage() async {
    try {
      print('🖼️ Starting gallery image selection');

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
        print('📁 Image selected from gallery: ${image.path}');
        // Check file size and compress further if needed
        final compressedImage = await _ultraFastCompress(File(image.path));
        await uploadProfileImage(compressedImage);
      } else {
        print('❌ No image selected from gallery');
      }
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image from gallery. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickAndUploadProfileImageFromCamera() async {
    try {
      print('📷 Starting camera image capture');

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
        print('📸 Image captured from camera: ${image.path}');
        // Check file size and compress further if needed
        final compressedImage = await _ultraFastCompress(File(image.path));
        await uploadProfileImage(compressedImage);
      } else {
        print('❌ No image captured from camera');
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
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

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      // Create a unique filename
      final fileName =
          'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}/$fileName');

      print('📤 Starting profile image upload: $fileName');

      // Upload the file with progress monitoring
      final uploadTask = storageRef.putFile(imageFile);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        uploadProgress.value = progress;
        print('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      final snapshot =
          await uploadTask.whenComplete(() => print('✅ Upload task completed'));

      // Check if upload was successful
      if (snapshot.state == TaskState.success) {
        uploadProgress.value = 1.0; // Complete progress

        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('🔗 Download URL obtained: ${downloadUrl.substring(0, 50)}...');

        // Update Firestore with the new image URL
        await FirebaseFirestore.instance
            .collection('partners')
            .doc(user.uid)
            .update({
          'profileImageUrl': downloadUrl,
        });

        // Update local state
        profileImageUrl.value = downloadUrl;

        print('✅ Profile image updated successfully');
        SuccessDialog.show(
          title: 'Profile Picture Updated',
          message: 'Your profile picture has been updated successfully!',
        );
      } else {
        throw 'Upload failed with state: ${snapshot.state}';
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');

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
            print('🔄 User tapped retry for network error');
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
    print('🔄 Opening profile image options bottom sheet');
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
                          print('📷 Camera option selected');
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
                          print('🖼️ Gallery option selected');
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
                      print('🗑️ Remove option selected');
                      Get.back();
                      removeProfileImage();
                    },
                    fullWidth: true,
                  ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    print('❌ Cancel pressed');
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
    ).then((value) => print('📱 Bottom sheet closed'));
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
      final user = FirebaseAuth.instance.currentUser;
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

      print('🗑️ Profile image removed successfully');
      SuccessDialog.show(
        title: 'Profile Picture Removed',
        message: 'Your profile picture has been removed successfully!',
      );
    } catch (e) {
      print('❌ Error removing profile image: $e');
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
      print('⚡ Starting ultra-fast compression');

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
        print(
            '✅ Ultra-fast compression: ${compressionRatio.toStringAsFixed(1)}% size reduction');

        return tempFile;
      }

      return imageFile; // Return original if compression fails
    } catch (e) {
      print('❌ Error in ultra-fast compression: $e');
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
        print(
            '🔄 Retrying upload in ${delay.inSeconds} seconds (attempt ${retryCount + 1}/${maxRetries})');

        await Future.delayed(delay);
        return _retryUpload(imageFile,
            retryCount: retryCount + 1, maxRetries: maxRetries);
      } else {
        rethrow; // Re-throw if max retries reached or non-network error
      }
    }
  }

  // Convert coordinates to human-readable address
  Future<void> _updateLocationAddress(double latitude, double longitude) async {
    try {
      print('📍 Converting coordinates to address: $latitude, $longitude');

      // Get placemarks from coordinates
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Build a readable address string
        List<String> addressParts = [];
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        String address = addressParts.join(', ');
        if (address.isEmpty) {
          address =
              '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        }

        locationAddress.value = address;
        print('✅ Address converted: $address');
      } else {
        locationAddress.value =
            '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        print('⚠️ No address found for coordinates');
      }
    } catch (e) {
      print('❌ Error converting coordinates to address: $e');
      locationAddress.value =
          '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }
}
