import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';

import 'package:saver/compo/success_dialog.dart';

class UserIdController extends GetxController {
  final Rx<Map<String, dynamic>?> userData = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> partnerData = Rx<Map<String, dynamic>?>(null);
  final RxBool isEditing = false.obs;
  final RxBool isLoading = true.obs;
  final RxString userCollection =
      'users'.obs; // To store which collection the user data is in

  // Profile image
  var profileImageUrl = Rx<String?>(null);
  var isUploadingImage = false.obs;
  var uploadProgress = 0.0.obs; // Upload progress (0.0 to 1.0)

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController ambulanceTypeController = TextEditingController();
  final TextEditingController coverageAreaController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    isLoading.value = true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        // Check users collection first, then drivers
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        String collectionName = 'users';
        if (!userDoc.exists) {
          userDoc = await FirebaseFirestore.instance
              .collection('drivers')
              .doc(uid)
              .get();
          collectionName = 'drivers';
        }
        userCollection.value = collectionName;
        final userDocRef =
            FirebaseFirestore.instance.collection(collectionName).doc(uid);

        if (userDoc.exists) {
          userData.value = userDoc.data() as Map<String, dynamic>?;
          nameController.text = userData.value?['name'] ?? '';
          phoneController.text = userData.value?['phone'] ?? '';
          addressController.text = userData.value?['address'] ?? '';
          emailController.text = userData.value?['email'] ?? '';
          profileImageUrl.value = userData.value?['profileImageUrl'];
        } else {
          userData.value = {
            'name': 'N/A',
            'email': FirebaseAuth.instance.currentUser!.email,
            'phone': 'N/A',
            'address': 'N/A',
            'uid': uid,
            'role': 'user', // Default role for users
            'createdAt': Timestamp.now(),
          };
          nameController.text = 'N/A';
          phoneController.text = 'N/A';
          addressController.text = 'N/A';
          emailController.text =
              FirebaseAuth.instance.currentUser!.email ?? 'N/A';
          await userDocRef.set(userData.value!);
        }

        final partnerDoc = await FirebaseFirestore.instance
            .collection('partners')
            .doc(uid)
            .get();
        if (partnerDoc.exists) {
          partnerData.value = partnerDoc.data();
          vehicleNumberController.text =
              partnerData.value?['vehicleNumber'] ?? '';
          licenseNumberController.text =
              partnerData.value?['licenseNumber'] ?? '';
          ambulanceTypeController.text =
              partnerData.value?['ambulanceType'] ?? '';
          coverageAreaController.text =
              partnerData.value?['coverageArea'] ?? '';
          contactController.text = partnerData.value?['contact'] ?? '';
          companyNameController.text = partnerData.value?['companyName'] ?? '';
        }

        await _updateLocation(uid);
      } catch (e) {
        Get.defaultDialog(
          title: 'Error',
          middleText: 'Failed to load user data: ${e.toString()}',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          onConfirm: () => Get.back(),
        );
      }
    } else {
      // Handle case when user is not authenticated
      userData.value = null;
      Get.defaultDialog(
        title: 'Authentication Required',
        middleText: 'Please log in to view your profile',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    }
    isLoading.value = false;
  }

  Future<void> updateUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection(userCollection.value)
            .doc(uid)
            .update({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'email': emailController.text.trim(),
        });

        if (partnerData.value != null) {
          await FirebaseFirestore.instance
              .collection('partners')
              .doc(uid)
              .update({
            'vehicleNumber': vehicleNumberController.text.trim(),
            'licenseNumber': licenseNumberController.text.trim(),
            'ambulanceType': ambulanceTypeController.text.trim(),
            'coverageArea': coverageAreaController.text.trim(),
            'contact': contactController.text.trim(),
            'companyName': companyNameController.text.trim(),
          });
          partnerData.value = {
            ...partnerData.value!,
            'vehicleNumber': vehicleNumberController.text.trim(),
            'licenseNumber': licenseNumberController.text.trim(),
            'ambulanceType': ambulanceTypeController.text.trim(),
            'coverageArea': coverageAreaController.text.trim(),
            'contact': contactController.text.trim(),
            'companyName': companyNameController.text.trim(),
          };
        }

        userData.value = {
          ...userData.value!,
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
          'email': emailController.text.trim(),
        };

        SuccessDialog.show(
          title: 'Success',
          message: 'Profile updated successfully!',
        );

        isEditing.value = false;
      } catch (e) {
        Get.defaultDialog(
          title: 'Error',
          middleText: 'Error updating profile: ${e.toString()}',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          onConfirm: () => Get.back(),
        );
      }
    }
  }

  Future<void> _updateLocation(String uid) async {
    try {
      Position position = await _getCurrentLocation();
      await FirebaseFirestore.instance
          .collection(userCollection.value)
          .doc(uid)
          .update({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      // Silently fail to avoid disrupting user experience
    }
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  void toggleEditing() {
    isEditing.value = !isEditing.value;
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
        Get.defaultDialog(
          title: 'Permission Required',
          middleText:
              'Photo library access is required to select images. Please grant permission when prompted.',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          onConfirm: () => Get.back(),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        Get.defaultDialog(
          title: 'Permission Required',
          middleText:
              'Photo library access is permanently denied. Please enable it in app settings.',
          confirm: TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          cancel: TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
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
      debugPrint('❌ Error picking image from gallery: $e');
      Get.defaultDialog(
        title: 'Error',
        middleText: 'Failed to pick image. Please try again.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    }
  }

  Future<void> pickAndUploadProfileImageFromCamera() async {
    try {
      debugPrint('📷 Starting camera image capture');

      // Request camera permission first
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Get.defaultDialog(
          title: 'Permission Required',
          middleText:
              'Camera access is required to take photos. Please grant permission in settings.',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          onConfirm: () => Get.back(),
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
      Get.defaultDialog(
        title: 'Error',
        middleText: 'Failed to take photo. Please try again.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      isUploadingImage.value = true;
      uploadProgress.value = 0.0; // Reset progress

      // Show immediate feedback

      // Check network connectivity first
      final isConnected = await _isConnected();
      if (!isConnected) {
        Get.defaultDialog(
          title: 'No Internet',
          middleText: 'Please check your internet connection and try again.',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          onConfirm: () => Get.back(),
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
            .collection(userCollection.value)
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
        // Offer retry option for network errors
        Get.defaultDialog(
          title: 'Upload Failed',
          middleText: 'Network error occurred. Tap to retry.',
          confirm: TextButton(
            onPressed: () {
              Get.back();
              debugPrint('🔄 User tapped retry for network error');
              _retryUpload(imageFile);
            },
            child: const Text('Retry'),
          ),
          cancel: TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        );
        return;
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMessage =
            'Permission denied. Please grant storage permissions and try again.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Upload was cancelled.';
        return; // Don't show error snackbar for cancelled uploads
      }

      Get.defaultDialog(
        title: 'Error',
        middleText: errorMessage,
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection(userCollection.value)
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
      Get.defaultDialog(
        title: 'Error',
        middleText: 'Failed to remove profile image. Please try again.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
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
            '🔄 Retrying upload in $delay.inSeconds seconds (attempt ${retryCount + 1}/$maxRetries)');

        await Future.delayed(delay);
        return _retryUpload(imageFile,
            retryCount: retryCount + 1, maxRetries: maxRetries);
      } else {
        rethrow; // Re-throw if max retries reached or non-network error
      }
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emailController.dispose();
    vehicleNumberController.dispose();
    licenseNumberController.dispose();
    ambulanceTypeController.dispose();
    coverageAreaController.dispose();
    contactController.dispose();
    companyNameController.dispose();
    super.onClose();
  }
}
