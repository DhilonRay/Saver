import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp; // Keep Timestamp for type checks
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:saver/compo/success_dialog.dart';
import '../../services/supabase_service.dart';

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

  // Ambulance image
  var ambulanceImageUrl = Rx<String?>(null);
  var isUploadingAmbulanceImage = false.obs;
  var ambulanceUploadProgress = 0.0.obs;

  // Maximum file size in bytes (10MB)
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  // Location address
  var locationAddress = Rx<String?>(null);

  StreamSubscription<List<Map<String, dynamic>>>? _personalInfoSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _partnerInfoSubscription;

  @override
  void onInit() {
    super.onInit();
    _setupRealTimeListeners();
    calculateEarnings(); // Calculate earnings on initialization
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
    _personalInfoSubscription = SupabaseService.client
        .from('drivers')
        .stream(primaryKey: ['id'])
        .eq('id', user.uid)
        .listen(
      (list) {
        if (list.isNotEmpty) {
          personalInfo.value = SupabaseService.toCamelCase(list.first);
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
    _partnerInfoSubscription = SupabaseService.client
        .from('partners')
        .stream(primaryKey: ['id'])
        .eq('id', user.uid)
        .listen(
      (list) async {
        if (list.isNotEmpty) {
          final data = SupabaseService.toCamelCase(list.first);
          partnerInfo.value = data;
          profileImageUrl.value = data['profileImageUrl'];
          ambulanceImageUrl.value = data['ambulanceImageUrl'];

          // Convert coordinates to address if available
          final latitude = data['latitude'];
          final longitude = data['longitude'];
          if (latitude != null && longitude != null) {
            await _updateLocationAddress(latitude, longitude);
          } else {
            locationAddress.value = null;
          }
        } else {
          partnerInfo.value = {};
          profileImageUrl.value = null;
          ambulanceImageUrl.value = null;
          locationAddress.value = null;
        }
        _checkLoadingComplete();
      },
      onError: (e) {
        partnerInfo.value = {};
        profileImageUrl.value = null;
        ambulanceImageUrl.value = null;
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
      final originalServiceRate = partnerInfo['serviceRate'];

      // Get current value from the map (this might have been updated by the UI)
      final currentServiceRate = partnerInfo['serviceRate'];

      if (originalServiceRate != currentServiceRate) {
        ratesChanged = true;
        partnerInfo['ratesLastUpdated'] = DateTime.now().toIso8601String();
        print('💰 Service rate updated: $currentServiceRate');
      }

      // Update partner info in Supabase
      if (partnerInfo.isNotEmpty) {
        final updateMap = Map<String, dynamic>.from(partnerInfo);
        updateMap.remove('id');
        updateMap.remove('uid');
        await SupabaseService.updatePartner(user.uid, updateMap);
        print('✅ Partner info updated in Supabase');
      }

      // Update personal info in drivers table in Supabase
      if (personalInfo.isNotEmpty) {
        final updateMap = Map<String, dynamic>.from(personalInfo);
        updateMap.remove('id');
        updateMap.remove('uid');
        await SupabaseService.updateDriver(user.uid, updateMap);
        print('✅ Personal info updated in Supabase');
      }

      isEditing.value = false;

      // Show appropriate success message
      if (ratesChanged) {
        SuccessDialog.show(
          title: 'Service Rate Updated',
          message:
              'Your service rate has been updated successfully! Users will see the new rate when making requests.',
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
        // Update Supabase
        await SupabaseService.updateDriver(user.uid, {'profileImageUrl': downloadUrl});
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

        // Update Supabase with the new image URL
        await SupabaseService.updatePartner(user.uid, {
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

      // Remove from Supabase
      await SupabaseService.updatePartner(user.uid, {
        'profileImageUrl': null,
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

  // ==================== AMBULANCE IMAGE METHODS ====================

  // Check if file size is within 10MB limit
  Future<bool> _checkFileSizeLimit(File file) async {
    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) {
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      Get.snackbar(
        'File Too Large',
        'Image size ($fileSizeMB MB) exceeds 10MB limit. Please choose a smaller image or take a new photo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
    return true;
  }

  Future<void> pickAndUploadAmbulanceImage() async {
    try {
      print('🚑 Starting ambulance image selection from gallery');

      // Request photo library permissions
      PermissionStatus status;
      if (GetPlatform.isIOS) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          status = await Permission.photos.request();
        }
      }

      if (status.isDenied) {
        Get.snackbar(
          'Permission Required',
          'Photo library access is required to select images.',
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
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Larger for ambulance photos
        maxHeight: 600,
        imageQuality: 70,
      );

      if (image != null) {
        print('📁 Ambulance image selected: ${image.path}');
        File imageFile = File(image.path);

        // Check file size before compression
        if (!await _checkFileSizeLimit(imageFile)) {
          return;
        }

        // Compress image
        final compressedImage = await _compressAmbulanceImage(imageFile);

        // Check file size after compression
        if (!await _checkFileSizeLimit(compressedImage)) {
          return;
        }

        await uploadAmbulanceImage(compressedImage);
      } else {
        print('❌ No ambulance image selected');
      }
    } catch (e) {
      print('❌ Error picking ambulance image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickAndUploadAmbulanceImageFromCamera() async {
    try {
      print('📷 Starting ambulance image capture from camera');

      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Required',
          'Camera access is required to take photos.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 70,
      );

      if (image != null) {
        print('📸 Ambulance image captured: ${image.path}');
        File imageFile = File(image.path);

        // Check file size before compression
        if (!await _checkFileSizeLimit(imageFile)) {
          return;
        }

        // Compress image
        final compressedImage = await _compressAmbulanceImage(imageFile);

        // Check file size after compression
        if (!await _checkFileSizeLimit(compressedImage)) {
          return;
        }

        await uploadAmbulanceImage(compressedImage);
      } else {
        print('❌ No ambulance image captured');
      }
    } catch (e) {
      print('❌ Error capturing ambulance image: $e');
      Get.snackbar(
        'Error',
        'Failed to take photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<File> _compressAmbulanceImage(File imageFile) async {
    try {
      print('🗜️ Compressing ambulance image');

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 600,
        minHeight: 400,
        quality: 60,
        rotate: 0,
      );

      if (compressedBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
            '${tempDir.path}/ambulance_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(compressedBytes);

        final originalSize = await imageFile.length();
        final compressedSize = await tempFile.length();
        print(
            '✅ Ambulance image compressed: ${((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)}% reduction');

        return tempFile;
      }

      return imageFile;
    } catch (e) {
      print('❌ Error compressing ambulance image: $e');
      return imageFile;
    }
  }

  Future<void> uploadAmbulanceImage(File imageFile) async {
    try {
      isUploadingAmbulanceImage.value = true;
      ambulanceUploadProgress.value = 0.0;

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

      final fileName =
          'ambulance_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('ambulance_images/${user.uid}/$fileName');

      print('📤 Starting ambulance image upload: $fileName');

      final uploadTask = storageRef.putFile(imageFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        ambulanceUploadProgress.value = progress;
        print(
            '📊 Ambulance upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      final snapshot = await uploadTask
          .whenComplete(() => print('✅ Ambulance image upload completed'));

      if (snapshot.state == TaskState.success) {
        ambulanceUploadProgress.value = 1.0;

        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('🔗 Ambulance image URL obtained');

        // Update Supabase with the new image URL
        await SupabaseService.updatePartner(user.uid, {
          'ambulanceImageUrl': downloadUrl,
        });

        ambulanceImageUrl.value = downloadUrl;

        print('✅ Ambulance image updated successfully');
        SuccessDialog.show(
          title: 'Ambulance Photo Updated',
          message:
              'Your ambulance photo has been uploaded successfully! Users can now see your ambulance before booking.',
        );
      } else {
        throw 'Upload failed with state: ${snapshot.state}';
      }
    } catch (e) {
      print('❌ Error uploading ambulance image: $e');

      String errorMessage =
          'Failed to upload ambulance image. Please try again.';
      if (e.toString().contains('network') ||
          e.toString().contains('unavailable')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('permission') ||
          e.toString().contains('PERMISSION_DENIED')) {
        errorMessage =
            'Permission denied. Please check Firebase Storage rules.';
      } else if (e.toString().contains('object-not-found')) {
        errorMessage = 'Storage path not found. Please try again.';
      }

      Get.snackbar(
        'Upload Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isUploadingAmbulanceImage.value = false;
      ambulanceUploadProgress.value = 0.0;
    }
  }

  void showAmbulanceImageOptions() {
    print('🚑 Opening ambulance image options bottom sheet');
    Get.bottomSheet(
      Container(
        height: ambulanceImageUrl.value != null ? 280 : 240,
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
                  'Upload Ambulance Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Max file size: 2MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionCard(
                        icon: Icons.camera_alt,
                        title: 'Take Photo',
                        color: Colors.blue,
                        onTap: () {
                          Get.back();
                          pickAndUploadAmbulanceImageFromCamera();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOptionCard(
                        icon: Icons.photo_library,
                        title: 'Gallery',
                        color: Colors.green,
                        onTap: () {
                          Get.back();
                          pickAndUploadAmbulanceImage();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ambulanceImageUrl.value != null)
                  _buildOptionCard(
                    icon: Icons.delete,
                    title: 'Remove Photo',
                    color: Colors.red,
                    onTap: () {
                      Get.back();
                      removeAmbulanceImage();
                    },
                    fullWidth: true,
                  ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
  }

  Future<void> removeAmbulanceImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await SupabaseService.updatePartner(user.uid, {
        'ambulanceImageUrl': null,
      });

      ambulanceImageUrl.value = null;

      print('🗑️ Ambulance image removed successfully');
      SuccessDialog.show(
        title: 'Ambulance Photo Removed',
        message: 'Your ambulance photo has been removed.',
      );
    } catch (e) {
      print('❌ Error removing ambulance image: $e');
      Get.snackbar(
        'Error',
        'Failed to remove ambulance image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ==================== END AMBULANCE IMAGE METHODS ====================

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

      // If there's no internet connectivity, bail out early and use coordinates
      final connected = await _isConnected();
      if (!connected) {
        print('⚠️ No internet available — skipping reverse geocoding');
        locationAddress.value =
            '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
        return;
      }

      // Get placemarks from coordinates with a timeout so the UI won't hang
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude)
              .timeout(const Duration(seconds: 8));

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
    } on TimeoutException catch (_) {
      print('⏱️ Reverse geocoding timed out — using raw coordinates');
      locationAddress.value =
          '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      print('❌ Error converting coordinates to address: $e');
      locationAddress.value =
          '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

  // Earnings calculation methods
  var totalEarnings = 0.0.obs;
  var completedRides = 0.obs;
  var monthlyEarnings = 0.0.obs;
  var isCalculatingEarnings = false.obs;

  Future<void> calculateEarnings() async {
    try {
      isCalculatingEarnings.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get all completed orders for this partner
      final orders = await SupabaseService.query(
        'orders',
        filters: {
          'partner_id': user.uid,
          'status': 'completed',
        },
      );

      double total = 0.0;
      int rides = 0;
      double monthTotal = 0.0;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var item in orders) {
        final data = SupabaseService.toCamelCase(item);
        final fareAmount = data['fareAmount'] ?? data['totalFare'] ?? 0.0;
        DateTime? timestamp;
        if (data['timestamp'] != null) {
          timestamp = DateTime.tryParse(data['timestamp'].toString());
        }

        if (fareAmount is num) {
          total += fareAmount.toDouble();
          rides++;

          // Check if order is from current month
          if (timestamp != null && timestamp.isAfter(startOfMonth)) {
            monthTotal += fareAmount.toDouble();
          }
        }
      }

      totalEarnings.value = total;
      completedRides.value = rides;
      monthlyEarnings.value = monthTotal;
    } catch (e) {
      print('Error calculating earnings: $e');
    } finally {
      isCalculatingEarnings.value = false;
    }
  }

  String formatCurrency(double amount) {
    return '৳${amount.toStringAsFixed(0)}';
  }

  /// Builds a network image with error handling and fallback
  /// Returns a DecorationImage for BoxDecoration or null if URL is null
  static DecorationImage? buildNetworkDecorationImage(
    String? imageUrl, {
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    return DecorationImage(
      image: NetworkImage(imageUrl),
      fit: fit,
      onError: (exception, stackTrace) {
        print('❌ Failed to load image: $exception');
      },
    );
  }
}
