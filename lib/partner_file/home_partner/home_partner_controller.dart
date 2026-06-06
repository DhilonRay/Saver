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

import '../../services/notification_service.dart';
import '../../services/fares_service.dart';
import '../../components/alert.dart';

class HomePartnerController extends GetxController {
  final bool isNewSignup;

  HomePartnerController({this.isNewSignup = false});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Completer<GoogleMapController> _controller = Completer();

  // Dynamic ambulance rate (can be changed by partner)
  var serviceRate = 2500.obs; // Default 2500 TK for service

  // Specific rates syncing with Profile
  var indoorRate = 0.obs;
  var outdoorRate = 0.obs;

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
  var isApproved = false.obs; // Approval status from admin
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
  final RxSet<String> interactedRequestIds =
      <String>{}.obs; // Track requests already responded to or accepted
  var activeOrderId = Rx<String?>(null); // Track currently active order ID
  StreamSubscription<QuerySnapshot>? _activeOrdersSubscription;
  StreamSubscription<QuerySnapshot>? _requestsSubscription;
  StreamSubscription<DocumentSnapshot>? _nameSubscription;
  StreamSubscription<DocumentSnapshot>? _imageSubscription;
  StreamSubscription<DocumentSnapshot>? _rateSubscription;
  StreamSubscription<DocumentSnapshot>? _fareResponseSubscription;
  StreamSubscription<DocumentSnapshot>? _approvalSubscription;

  // Fare input controller for driver fare entry
  final TextEditingController _fareInputController = TextEditingController();

  // Location Stream and Camera Following
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _lastFirestoreUpdateTime;
  Position? _lastFirestorePosition;
  static const Duration _firestoreUpdateInterval = Duration(seconds: 4);
  var shouldFollowDriver = true.obs; // Camera follows ambulance by default
  bool isUserGesturing = false; // Internal flag to detect manual pan
  StreamSubscription? _activeNegotiationSubscription;
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

  Future<void> _initializeFCM() async {
    try {
      final token = await NotificationService.initializeFCMToken();
      if (token != null) {
      } else {}
    } catch (e) {}
  }

  Future<void> _loadCustomIcons() async {
    try {
      debugPrint('Loading custom PNG icons for partner...');
      currentLocationIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(45, 45)),
        'assets/images/ambulance.png',
      );
      userLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } catch (e) {
      currentLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      userLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _loadPartnerRates() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _rateSubscription?.cancel();
      _rateSubscription = FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          // Load specific rates to match Profile Page
          indoorRate.value = data['indoorCityRate'] ?? defaultServiceRate;
          outdoorRate.value = data['outdoorCityRate'] ?? defaultServiceRate;

          // Also set serviceRate for legacy support
          serviceRate.value = data['serviceRate'] ?? defaultServiceRate;
        } else {
          indoorRate.value = defaultServiceRate;
          outdoorRate.value = defaultServiceRate;
          serviceRate.value = defaultServiceRate;
        }
      }, onError: (e) {
        indoorRate.value = defaultServiceRate;
        outdoorRate.value = defaultServiceRate;
        serviceRate.value = defaultServiceRate;
      });
    } catch (e) {}
  }

  void _loadPartnerName() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _nameSubscription?.cancel();
      _nameSubscription = FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          partnerName.value =
              data['name'] ?? user.displayName ?? 'NeoSaver Partner';
        } else {
          partnerName.value = user.displayName ?? 'NeoSaver Partner';
        }
      }, onError: (e) {
        partnerName.value =
            _auth.currentUser?.displayName ?? 'NeoSaver Partner';
      });
    } catch (e) {}
  }

  void _loadProfileImage() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _imageSubscription?.cancel();
      _imageSubscription = FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          profileImageUrl.value = data['profileImageUrl'];
        }
      }, onError: (e) {});
    } catch (e) {}
  }

  // Profile Image Methods
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
        Alert.info('Photo library access is required to select images.');
        return;
      }

      if (status.isPermanentlyDenied) {
        Alert.info(
            'Photo library access is permanently denied. Please enable it in app settings.');
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
        final compressedImage = await _ultraFastCompress(File(image.path));
        await uploadProfileImage(compressedImage);
      } else {}
    } catch (e) {
      Alert.info('Failed to pick image from gallery. Please try again.');
    }
  }

  Future<void> pickAndUploadProfileImageFromCamera() async {
    try {
      // Request camera permission first
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        Alert.info('Camera access is required to take photos.');
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
        // Check file size and compress further if needed
        final compressedImage = await _ultraFastCompress(File(image.path));
        await uploadProfileImage(compressedImage);
      } else {}
    } catch (e) {
      Alert.info('Failed to take photo. Please try again.');
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      isUploadingImage.value = true;
      uploadProgress.value = 0.0; // Reset progress

      // Check network connectivity first
      final isConnected = await _isConnected();
      if (!isConnected) {
        Alert.info('Please check your internet connection and try again.');
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

      // Upload the file with progress monitoring
      final uploadTask = storageRef.putFile(imageFile);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        uploadProgress.value = progress;
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

        if (Get.context != null) {
          Alert.info('Your profile image has been updated successfully!');
        }
      } else {
        throw 'Upload failed with state: ${snapshot.state}';
      }
    } catch (e) {
      // Provide more specific error messages
      String errorMessage = 'Failed to upload profile image. Please try again.';
      if (e.toString().contains('network') ||
          e.toString().contains('unavailable')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
        // Offer retry option for network errors
        if (Get.context != null) {
          Alert.info('Network error occurred. Please try again.');
        }
        return; // Don't show the default error snackbar
      } else if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMessage =
            'Permission denied. Please grant storage permissions and try again.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Upload was cancelled.';
        return; // Don't show error snackbar for cancelled uploads
      }

      Alert.info(errorMessage);
    } finally {
      isUploadingImage.value = false;
      uploadProgress.value = 0.0; // Reset progress
    }
  }

  void showProfileImageOptions() {
    if (Get.context != null) {
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
      if (Get.context != null) {
        Alert.info('Your profile image has been removed successfully!');
      }
    } catch (e) {
      debugPrint('❌ Error removing profile image: $e');
      if (Get.context != null) {
        Alert.info(
          'Failed to remove profile image. Please try again.',
        );
      }
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

        return tempFile;
      }

      return imageFile; // Return original if compression fails
    } catch (e) {
      return imageFile; // Return original on error
    }
  }

  Future<bool> updatePartnerRates(int newIndoorRate, int newOutdoorRate) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Alert.info('You must be logged in to update rates');
        return false;
      }

      // Validate rates
      if (newIndoorRate < 500 || newOutdoorRate < 500) {
        Alert.info('Service rates must be at least ৳500');
        return false;
      }

      // Update Firestore with BOTH fields to sync with Profile Page
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .update({
        'indoorCityRate': newIndoorRate,
        'outdoorCityRate': newOutdoorRate,
        'serviceRate':
            newIndoorRate, // Keeping base service rate synced with indoor
        'ratesLastUpdated': Timestamp.now(),
      });

      // Update local reactive variables
      indoorRate.value = newIndoorRate;
      outdoorRate.value = newOutdoorRate;
      serviceRate.value = newIndoorRate;

      return true;
    } catch (e) {
      Alert.info('Failed to update rates: $e');
      return false;
    }
  }

  void showRateChangeDialog() {
    // Current values
    int tempIndoorRate =
        indoorRate.value > 0 ? indoorRate.value : serviceRate.value;
    int tempOutdoorRate =
        outdoorRate.value > 0 ? outdoorRate.value : serviceRate.value;

    if (Get.context != null) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Update Service Rates',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Set your ambulance service rates. These will be shown on your profile.',
                  style:
                      TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Indoor Rate Field
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Indoor City Rate (৳)',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    hintText: 'e.g. 2500',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF42A5F5), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.number,
                  controller:
                      TextEditingController(text: tempIndoorRate.toString()),
                  onChanged: (value) {
                    tempIndoorRate = int.tryParse(value) ?? tempIndoorRate;
                  },
                ),
                const SizedBox(height: 16),

                // Outdoor Rate Field
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Outdoor City Rate (৳)',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    hintText: 'e.g. 5000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF42A5F5), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.number,
                  controller:
                      TextEditingController(text: tempOutdoorRate.toString()),
                  onChanged: (value) {
                    tempOutdoorRate = int.tryParse(value) ?? tempOutdoorRate;
                  },
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Close keyboard first
                          FocusScope.of(Get.context!).unfocus();

                          // Perform update with BOTH rates
                          bool success = await updatePartnerRates(
                              tempIndoorRate, tempOutdoorRate);

                          // Close dialog
                          Get.back();

                          // Show success if updated
                          if (success) {
                            // Short delay to allow dialog to fully close
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              if (Get.context != null) {
                                Alert.info(
                                    'Your service rates have been updated successfully!');
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF5C9DFF), // Custom Blue
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Update Rates',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        barrierColor: Colors.black.withValues(alpha: 0.5),
      );
    }
  }

  Future<Map<String, int>> _fetchPartnerRates() async {
    return {'serviceRate': serviceRate.value};
  }

  @override
  void onInit() {
    super.onInit();
    // Call async initialization
    _initializeController();
  }

  Future<void> _initializeController() async {
    // Load custom icons first
    await _loadCustomIcons();

    // Load previously declined requests BEFORE listening to requests (Fixes race condition)
    await _loadHandledRequestIds();

    // Start listening for requests
    _listenForRequests();
    _listenForActiveOrders(); // Also listen for active/accepted orders

    // Other initializations
    _getCurrentLocation();
    _loadPartnerRates(); // Load partner's custom rates
    _loadPartnerName(); // Load partner's name
    _loadProfileImage(); // Load partner's profile image
    _loadInitialOnlineStatus(); // Load online/offline status
    _listenToApprovalStatus(); // Listen for admin approval status

    // Initialize FCM token specifically for this partner
    _initializeFCM();

    // Check for initial request from notifications (Deep-linking)
    if (Get.arguments != null && Get.arguments['initialRequest'] != null) {
      final request =
          Map<String, dynamic>.from(Get.arguments['initialRequest']);
      // Ensure it has an ID field that the bottom sheet expects
      final String? reqId = request['id'] ?? request['orderId'];

      if (reqId != null) {
        request['id'] = reqId; // Normalize to 'id'
        Future.delayed(const Duration(milliseconds: 800), () async {
          try {
            // Re-verify status from Firestore to ensure it's still pending
            final doc = await FirebaseFirestore.instance
                .collection('orders')
                .doc(reqId)
                .get();

            if (doc.exists) {
              final status = doc.data()?['status']?.toString().toLowerCase();
              if (status == 'pending') {
                _showRequestBottomSheet(request);
              } else {
                debugPrint(
                    '🏠 HomePartner: Initial request $reqId is no longer pending ($status).');
              }
            }
          } catch (e) {
            debugPrint('🏠 HomePartner: Error checking initial request: $e');
            // Fallback: show it anyway if check fails, or could be safer to hide it
          }
        });
      }
    }

    // Debug: Check for existing orders after a delay
    Future.delayed(const Duration(seconds: 3), () {
      _debugCheckOrders();
    });

    // Start periodic location updates every 10 seconds
    // Start location updates via stream
    _startPositionSubscription();

    // Show success dialog for new driver signups
    if (isNewSignup) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.context != null) {}
      });
    }
  }

  void _listenToApprovalStatus() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _approvalSubscription?.cancel();
      _approvalSubscription = FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          isApproved.value = data['isApproved'] ?? false;
          debugPrint('🛡️ Approval Status: ${isApproved.value}');
        }
      }, onError: (e) {
        debugPrint('❌ Error listening to approval status: $e');
      });
    } catch (e) {}
  }

  @override
  void onClose() {
    _requestsSubscription?.cancel();
    _nameSubscription?.cancel();
    _imageSubscription?.cancel();
    _rateSubscription?.cancel();
    _fareResponseSubscription?.cancel();
    _approvalSubscription?.cancel();
    _fareInputController.dispose();
    _positionSubscription?.cancel(); // Cancel location stream
    _activeOrdersSubscription?.cancel(); // Cancel active orders listener
    shownRequestIds.clear(); // Clear shown requests when controller closes
    // Don't clear declinedRequestIds - they should persist across sessions
    super.onClose();
  }

  /// Start periodic location updates every 10 seconds
  void _startPositionSubscription() async {
    try {
      // Check permission before starting stream
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint(
            '🏠 HomePartner: Location permission denied, using default position');
        if (currentPosition.value == null) {
          currentPosition.value = defaultPosition;
          isLoadingLocation.value = false;
          isInitialLoading.value = false;
        }
        return;
      }

      // Also check if location service is enabled
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        debugPrint(
            '🏠 HomePartner: Location service disabled, using default position');
        if (currentPosition.value == null) {
          currentPosition.value = defaultPosition;
          isLoadingLocation.value = false;
          isInitialLoading.value = false;
        }
        return;
      }

      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2, // Update every 2 meters
        ),
      ).listen((Position position) {
        _handleNewPosition(position);
      }, onError: (e) {
        debugPrint('🏠 HomePartner: Position stream error: $e');
        // Ensure map is not stuck on grey if stream errors
        if (currentPosition.value == null) {
          currentPosition.value = defaultPosition;
          isLoadingLocation.value = false;
          isInitialLoading.value = false;
        }
        _startLocationUpdateTimer();
      });

      // Safety fallback: if no position received within 10 seconds, use default
      Future.delayed(const Duration(seconds: 10), () {
        if (currentPosition.value == null) {
          debugPrint(
              '🏠 HomePartner: No position after 10s, using default position');
          currentPosition.value = defaultPosition;
          isLoadingLocation.value = false;
          isInitialLoading.value = false;
        }
      });
    } catch (e) {
      debugPrint('Error starting position stream: $e');
      if (currentPosition.value == null) {
        currentPosition.value = defaultPosition;
        isLoadingLocation.value = false;
        isInitialLoading.value = false;
      }
      // Fallback to timer if stream fails
      _startLocationUpdateTimer();
    }
  }

  void _handleNewPosition(Position position) async {
    final newPosition = LatLng(position.latitude, position.longitude);

    // Filter noise - only update if moved significantly or if it's the first fix
    if (currentPosition.value != null) {
      final distance = Geolocator.distanceBetween(
        currentPosition.value!.latitude,
        currentPosition.value!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      if (distance < 2) return; // Ignore very small movements (noise)
    }

    currentPosition.value = newPosition;

    // Update marker
    markers.removeWhere((m) => m.markerId.value == 'currentLocation');
    markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: newPosition,
        infoWindow: const InfoWindow(title: 'Your Ambulance Location'),
        icon: currentLocationIcon,
      ),
    );

    // Camera following logic
    if (shouldFollowDriver.value && _controller.isCompleted) {
      try {
        final GoogleMapController mapController = await _controller.future;
        await mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newPosition, zoom: 14),
          ),
        );
      } catch (e) {
        debugPrint('🏠 HomePartner: animateCamera failed: $e');
      }
    }

    final now = DateTime.now();

    // Throttle check: Update if enough time passed (4s) OR moved significant distance (10m)
    final timePassed = _lastFirestoreUpdateTime == null ||
        now.difference(_lastFirestoreUpdateTime!) >= _firestoreUpdateInterval;

    final movedSignificantly = _lastFirestorePosition == null ||
        Geolocator.distanceBetween(
              _lastFirestorePosition!.latitude,
              _lastFirestorePosition!.longitude,
              position.latitude,
              position.longitude,
            ) >=
            10;

    if (isOnline.value && (timePassed || movedSignificantly)) {
      _lastFirestoreUpdateTime = now;
      _lastFirestorePosition = position;
      await _updatePartnerLocation();
    }
  }

  // Fallback timer (kept for robustness)
  void _startLocationUpdateTimer() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateCurrentLocation();
    });
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
    } catch (e) {}
  }

  /// Reset shown requests (useful when driver logs out and logs back in)
  void resetShownRequests() {
    shownRequestIds.clear();
    showRequestBottomSheet.value = false;
  }

  /// Load handled request IDs from shared preferences
  Future<void> _loadHandledRequestIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      if (user != null) {
        // Load declined IDs (legacy)
        final declinedKey = 'declined_requests_${user.uid}';
        final declinedIds = prefs.getStringList(declinedKey) ?? [];
        declinedRequestIds.addAll(declinedIds);

        // Load interacted IDs (new)
        final interactedKey = 'interacted_requests_${user.uid}';
        final interactedIds = prefs.getStringList(interactedKey) ?? [];
        interactedRequestIds.addAll(interactedIds);
      }
    } catch (e) {
      debugPrint('❌ Error loading handled request IDs: $e');
    }
  }

  /// Save handled request IDs to shared preferences
  Future<void> _saveHandledRequestIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _auth.currentUser;
      if (user != null) {
        final declinedKey = 'declined_requests_${user.uid}';
        await prefs.setStringList(declinedKey, declinedRequestIds.toList());

        final interactedKey = 'interacted_requests_${user.uid}';
        await prefs.setStringList(interactedKey, interactedRequestIds.toList());
      }
    } catch (e) {
      debugPrint('❌ Error saving handled request IDs: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      isLoadingLocation.value = true;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Alert.info(
              'Location permission is required to show your location on the map');
          isLoadingLocation.value = false;
          // Fallback to default position so map works
          currentPosition.value = defaultPosition;
          isInitialLoading.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Alert.info(
            'Location permission is permanently denied. Please enable it in settings.');
        isLoadingLocation.value = false;
        // Fallback to default position so map works
        currentPosition.value = defaultPosition;
        isInitialLoading.value = false;
        return;
      }

      // Add a 8-second time limit to avoid indefinite hanging
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
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
      debugPrint('🏠 HomePartner: _getCurrentLocation failed or timed out: $e');
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

        // Also update active order tracking if exists
        if (activeOrderId.value != null && isOnline.value) {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(activeOrderId.value)
              .update({
            'partnerLiveLocation': {
              'latitude': currentPosition.value!.latitude,
              'longitude': currentPosition.value!.longitude,
              'timestamp': Timestamp.now(),
            },
          });
          debugPrint(
              '🏠 HomePartner: Updated active order location: ${activeOrderId.value}');
        }
      }
    } catch (e) {}
  }

  void _listenForRequests() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }

      _requestsSubscription = FirebaseFirestore.instance
          .collection('orders')
          .where('type', isEqualTo: 'ambulance')
          .where('status', whereIn: ['pending', 'counter'])
          .where('partnerId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            // Log each document and handle state recovery
            for (var doc in snapshot.docs) {
              final data = doc.data();
              debugPrint(
                  '📄 Document ${doc.id}: status=${data['status']}, type=${data['type']}, partnerId=${data['partnerId']}');

              // If user sent a counter offer, we MUST show it again even if driver previously interacted
              final negotiation =
                  data['negotiation'] as Map<String, dynamic>? ?? {};
              if (negotiation['status'] == 'counter' &&
                  negotiation['counterBy'] == 'user') {
                if (interactedRequestIds.contains(doc.id)) {
                  interactedRequestIds.remove(doc.id);
                  _saveHandledRequestIds();
                  debugPrint(
                      '♻️ Order ${doc.id} removed from interacted set due to user counter-offer');
                }
              }
            }

            // Filter out declined and interacted requests
            final allRequests = snapshot.docs
                .map((doc) {
                  return {
                    'id': doc.id,
                    ...doc.data(),
                  };
                })
                .where((request) =>
                    !declinedRequestIds.contains(request['id']) &&
                    !interactedRequestIds.contains(request['id']))
                .toList();

            pendingRequests.value = allRequests;

            // Show bottom sheet if there are pending requests that haven't been shown yet and aren't declined
            final newRequests = pendingRequests
                .where((request) =>
                    !shownRequestIds.contains(request['id']) &&
                    !declinedRequestIds.contains(request['id']))
                .toList();

            if (newRequests.isNotEmpty && !showRequestBottomSheet.value) {
              final firstNewRequest = newRequests.first;
              shownRequestIds.add(firstNewRequest['id']); // Mark as shown
              showRequestBottomSheet.value = true;

              // Start listening to THIS specific request to detect when user accepts
              _startActiveNegotiationListener(firstNewRequest);

              _showRequestBottomSheet(firstNewRequest);
            } else if (newRequests.isEmpty) {
            } else {}
          }, onError: (error) {
            // Check for network connectivity issues
            if (error.toString().contains('UNAVAILABLE') ||
                error.toString().contains('firestore.googleapis.com') ||
                error.toString().contains('Unable to resolve host')) {}
          });
    } catch (e) {}
  }

  void _listenForActiveOrders() {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _activeOrdersSubscription?.cancel();
      _activeOrdersSubscription = FirebaseFirestore.instance
          .collection('orders')
          .where('acceptedBy', isEqualTo: user.uid)
          .where('status',
              whereIn: ['accepted', 'in_transit', 'pickup', 'to_destination'])
          .snapshots()
          .listen((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              // Get the most recent active order
              final activeOrder = snapshot.docs.first;
              activeOrderId.value = activeOrder.id;
              debugPrint(
                  '🏠 HomePartner: Detected active order: ${activeOrder.id}');
            } else {
              activeOrderId.value = null;
            }
          });
    } catch (e) {
      debugPrint('Error listening for active orders: $e');
    }
  }

  void _showRequestBottomSheet(Map<String, dynamic> request) {
    bool isFareConfirmed = request['status'] == 'accepted' || 
                           request['status'] == 'confirmed' || 
                           request['negotiation']?['status'] == 'confirmed' || 
                           request['negotiation']?['status'] == 'accepted';

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
                      color: Colors.red.shade200.withValues(alpha: 0.3),
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
                      color: Colors.blue.shade100.withValues(alpha: 0.3),
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
                      isFareConfirmed 
                          ? (request['phone'] ?? 'ফোন নম্বর নেই - ইমেইল চেক করুন') 
                          : 'ভাড়া কনফার্ম হওয়ার পর দেখা যাবে',
                      Colors.blue.shade700,
                    ),
                    if (request['email'] != null &&
                        request['email'].toString().isNotEmpty)
                      _buildInfoRow(
                        Icons.email,
                        'ইমেইল',
                        isFareConfirmed 
                            ? request['email'] 
                            : 'ভাড়া কনফার্ম হওয়ার পর দেখা যাবে',
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
                      color: Colors.blue.shade100.withValues(alpha: 0.3),
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
                        color: Colors.blue.shade100.withValues(alpha: 0.3),
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
                        color: Colors.blue.shade100.withValues(alpha: 0.3),
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

              // Driver Fare Entry Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100.withValues(alpha: 0.3),
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
                        Icon(Icons.monetization_on,
                            color: Colors.green.shade700, size: 24),
                        SizedBox(width: 12),
                        Text(
                          request['negotiation']?['counterBy'] == 'user'
                              ? 'ইউজার একটি ভাড়া প্রস্তাব করেছেন'
                              : 'ভাড়া নির্ধারণ করুন',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      request['negotiation']?['counterBy'] == 'user'
                          ? 'ইউজারের প্রস্তাবিত ভাড়া নিচে দেখুন। আপনি চাইলে এটি গ্রহণ করতে পারেন বা নতুন ভাড়া প্রস্তাব করতে পারেন।'
                          : 'দূরত্ব ও রুট দেখে ভাড়া লিখুন। এই ভাড়া ইউজারের কাছে পাঠানো হবে।',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _fareInputController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                      decoration: InputDecoration(
                        prefixText: '৳ ',
                        prefixStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                        hintText: 'ভাড়া লিখুন',
                        hintStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.green.shade600, width: 2),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  // Cancel/Decline Button
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _fareInputController.clear();
                          Get.back();
                          declineRequest(request['id']);
                        },
                        icon: Icon(Icons.cancel, size: 24),
                        label: Text(
                          'প্রত্যাখ্যান',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                  SizedBox(width: 8),

                  // Accept Button (Only if user has countered)
                  if (request['negotiation']?['counterBy'] == 'user') ...[
                    Expanded(
                      child: Container(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _fareInputController.clear();
                            Get.back();
                            acceptRequest(request['id']);
                          },
                          icon: Icon(Icons.check_circle, size: 24),
                          label: Text(
                            'গ্রহণ করুন',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.blue.shade200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],

                  // Bid/Counter Button
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final fareText = _fareInputController.text.trim();
                          if (fareText.isEmpty) {
                            Alert.info(
                                'ভাড়া প্রয়োজন: অনুগ্রহ করে ভাড়ার পরিমাণ লিখুন');
                            return;
                          }
                          final fareAmount = double.tryParse(fareText);
                          if (fareAmount == null || fareAmount <= 0) {
                            Alert.info(
                                'অবৈধ ভাড়া: অনুগ্রহ করে সঠিক ভাড়ার পরিমাণ লিখুন');
                            return;
                          }
                          _fareInputController.clear();
                          Get.back();
                          submitFareToUser(request['id'], fareAmount, request);
                        },
                        icon: Icon(Icons.send, size: 24),
                        label: Text(
                          request['negotiation']?['counterBy'] == 'user'
                              ? 'নতুন ভাড়া'
                              : 'ভাড়া পাঠান',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
                        color: Colors.blue.shade100.withValues(alpha: 0.3),
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
    ).then((_) {
      // When the bottom sheet is closed manually or otherwise, stop the listener
      _stopActiveNegotiationListener();
      showRequestBottomSheet.value = false;
    });
  }

  void _startActiveNegotiationListener(Map<String, dynamic> request) {
    _stopActiveNegotiationListener(); // Cancel any existing one

    final requestId = request['id'];
    if (requestId == null) return;

    debugPrint(
        'HomePartner: Starting active negotiation listener for $requestId');

    _activeNegotiationSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(requestId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data == null) return;

        final status = data['status']?.toString().toLowerCase();
        final negotiationStatus =
            data['negotiation']?['status']?.toString().toLowerCase();

        debugPrint(
            'HomePartner: Active negotiation update. status: $status, negStatus: $negotiationStatus');

        if (status == 'accepted' ||
            status == 'confirmed' ||
            negotiationStatus == 'confirmed' ||
            negotiationStatus == 'accepted') {
          _handleRideConfirmed(requestId!, data);
        }
      }
    }, onError: (e) {
      debugPrint('HomePartner: Active negotiation listener error: $e');
    });
  }

  /// Centralized method to handle transition to active ride map
  void _handleRideConfirmed(String orderId, Map<String, dynamic> data) {
    // Prevent multiple navigation attempts
    if (Get.currentRoute == '/AcceptMapsPage') return;

    debugPrint('🏁 HomePartner: Processing ride start for order $orderId');

    // Stop all relevant listeners
    _stopActiveNegotiationListener();
    _fareResponseSubscription?.cancel();
    _fareResponseSubscription = null;

    // Small delay to ensure any closing bottom sheets or UI states are settled
    Future.delayed(const Duration(milliseconds: 300), () {
      // Close any open bottom sheets
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }

      Alert.info(
          '✅ ভাড়া গৃহীত! ইউজার আপনার ভাড়া গ্রহণ করেছেন। ট্রিপ শুরু করুন।');

      // Prepare fresh data for navigation
      final updatedRequest = {'id': orderId, ...data};

      // Use offAll to match SplashPageController behavior for stable redirection
      Get.offAll(() => const AcceptMapsPage(), arguments: {
        'request': updatedRequest,
        'serviceRate': serviceRate.value,
      });
    });
  }

  void _stopActiveNegotiationListener() {
    if (_activeNegotiationSubscription != null) {
      debugPrint('HomePartner: Stopping active negotiation listener');
      _activeNegotiationSubscription?.cancel();
      _activeNegotiationSubscription = null;
    }
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

      // Add to handled list and save to preferences to prevent reappearing as a "new" request
      interactedRequestIds.add(requestId);
      await _saveHandledRequestIds();

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
        // Update negotiation map to show mutual agreement
        'negotiation.status': 'confirmed',
        'negotiation.driverAccepted': true,
        'negotiation.userAccepted': true,
        'negotiation.updatedAt': Timestamp.now(),
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
            data: {
              'type': 'order_accepted',
              'orderId': requestId,
              'userId': userId // Add userId for background notification storage
            },
          );
        }
      }

      // Navigate to accept maps page with updated request data
      debugPrint(
          'HomePartner: Passing serviceRate to AcceptMaps: ${serviceRate.value}');

      // Navigate to accept maps page with request data
      Get.to(() => AcceptMapsPage(), arguments: {
        'request': updatedRequest,
        'serviceRate': serviceRate.value
      });
    } catch (e) {
      Alert.info('Failed to accept request: $e');
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
        debugPrint(
            '⚠️ Request $requestId already removed or processed (doc not found), returning quietly');
        if (Get.isBottomSheetOpen == true) {
          Get.back();
        }
        return;
      }

      final requestData = doc.data()!;
      final userId = requestData['userId'];

      // Add to declined list and save to preferences
      declinedRequestIds.add(requestId);
      await _saveHandledRequestIds();

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
            data: {
              'type': 'order_cancelled',
              'orderId': requestId,
              'userId': userId // Add userId for background notification storage
            },
          );
        }
      }

      showRequestBottomSheet.value = false;
      debugPrint('❌ Request declined and saved: $requestId');

      if (Get.context != null) {
        Alert.info('Request declined');
      }
    } catch (e) {
      debugPrint('❌ Error declining request: $e');
      Alert.info('Failed to decline request: $e');
    }
  }

  /// Submit driver's proposed fare to the user
  Future<void> submitFareToUser(
      String requestId, double fareAmount, Map<String, dynamic> request) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update Firestore order with proposed fare in the negotiation map
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(requestId)
          .update({
        'status': 'pending', // Keep pending until both agree
        'negotiation.status': 'counter',
        'negotiation.counterFare': fareAmount,
        'negotiation.counterBy': 'driver',
        'negotiation.userAccepted': false,
        'negotiation.driverAccepted':
            true, // Driver agrees to their own proposal
        'negotiation.updatedAt': FieldValue.serverTimestamp(),
        'driverName': partnerName.value,
      });

      // Add to interacted list so it doesn't show in the pending list until user counters
      interactedRequestIds.add(requestId);
      await _saveHandledRequestIds();

      debugPrint('✅ Fare proposed: ৳$fareAmount for order $requestId');

      // Send FCM notification to user
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
            title: '💰 ভাড়া প্রস্তাব এসেছে',
            body:
                '${partnerName.value} আপনার ট্রিপের জন্য ৳${fareAmount.toStringAsFixed(0)} ভাড়া প্রস্তাব করেছেন।',
            data: {
              'type': 'fare_proposed',
              'orderId': requestId,
              'driverFare': fareAmount.toString(),
              'driverName': partnerName.value,
              'userId':
                  userId, // Add userId for background notification storage
            },
          );
          debugPrint('✅ FCM notification sent to user $userId');
        }
      }

      showRequestBottomSheet.value = false;

      // Start listening for fare response from user
      _listenForFareResponse(requestId);

      // Delay alert to ensure overlay is available after bottom sheet closes
      Future.delayed(const Duration(milliseconds: 500), () {
        Alert.info(
            '✅ ভাড়া পাঠানো হয়েছে: ৳${fareAmount.toStringAsFixed(0)} ভাড়া ইউজারের কাছে পাঠানো হয়েছে। ইউজারের সম্মতির জন্য অপেক্ষা করুন।');
      });
    } catch (e) {
      debugPrint('❌ Error submitting fare: $e');
      Alert.info('ত্রুটি: ভাড়া পাঠাতে ব্যর্থ হয়েছে: $e');
    }
  }

  /// Listen for user's response to the proposed fare
  void _listenForFareResponse(String orderId) {
    _fareResponseSubscription?.cancel();
    _fareResponseSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      final status = data?['status']?.toString().toLowerCase();
      final negStatus =
          data?['negotiation']?['status']?.toString().toLowerCase();

      // Broad triggers to catch ride start regardless of update order
      if (status == 'confirmed' ||
          status == 'accepted' ||
          negStatus == 'confirmed' ||
          negStatus == 'accepted') {
        debugPrint('✅ Negotiation confirmed/accepted for order $orderId');
        _handleRideConfirmed(orderId, data!);
      } else if (data?['negotiation']?['status'] == 'counter' &&
          data?['negotiation']?['counterBy'] == 'user') {
        // User sent a counter offer! Show the bottom sheet again for the driver to respond
        final counterFare =
            (data?['negotiation']?['counterFare'] as num?)?.toDouble() ?? 0.0;
        debugPrint('💰 User sent a counter offer: ৳$counterFare');

        // Mark as NOT shown so the main listener (or this one) can trigger the UI
        shownRequestIds.remove(orderId);

        // Remove from interacted list list so it reappears for responding
        if (interactedRequestIds.contains(orderId)) {
          interactedRequestIds.remove(orderId);
          _saveHandledRequestIds();
        }

        // Update the input field with the user's offer to make it easy for the driver to accept or counter back
        _fareInputController.text = counterFare.toStringAsFixed(0);

        // Show the bottom sheet if not already showing
        if (!showRequestBottomSheet.value) {
          final requestData = {'id': orderId, ...data!};
          _showRequestBottomSheet(requestData);
        }
      } else if (status == 'cancelled' ||
          data?['negotiation']?['status'] == 'rejected') {
        _fareResponseSubscription?.cancel();
        debugPrint('❌ Negotiation rejected for order $orderId');

        Alert.info('❌ ভাড়া প্রত্যাখ্যাত বা ট্রিপ বাতিল করা হয়েছে।');
        showRequestBottomSheet.value = false;
      }
    }, onError: (error) {
      debugPrint('❌ Error listening for fare response: $error');
    });
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
        Alert.info(
            'Request Not Found: The requested ambulance request could not be found');
      }
    } catch (e) {
      debugPrint('❌ Error fetching request $orderId: $e');
      Alert.info(
        'Failed to load request details: $e',
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
      final allOrders =
          await FirebaseFirestore.instance.collection('orders').get();

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

      debugPrint(
          '🚑 Pending ambulance orders for this partner: ${pendingAmbulance.length}');

      // Log details of pending orders
      for (var doc in pendingAmbulance) {
        final data = doc.data();
        debugPrint(
            '📋 Pending Order ${doc.id}: patient=${data['patientName']}, phone=${data['phone']}, urgency=${data['urgency']}');
      }

      // Check if there are any orders for other partner IDs
      final otherPartnerOrders = allOrders.docs.where((doc) {
        final data = doc.data();
        final partnerId = data['partnerId'];
        return partnerId != null &&
            partnerId != user.uid &&
            data['status'] == 'pending';
      }).toList();

      debugPrint(
          '👥 Pending orders for other partners: ${otherPartnerOrders.length}');

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
      Alert.info('Failed to show request details: $e');
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
      if (Get.context != null) {
        Get.offAll(() => LoginPage());
      }
    } catch (e) {
      Alert.info('Failed to sign out: $e');
    }
  }

  /// Toggle online/offline status
  Future<void> toggleOnlineStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Alert.info(
          'অনুগ্রহ করে লগইন করুন',
        );
        return;
      }

      // Show confirmation dialog when going offline
      if (isOnline.value) {
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade600),
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
                    onPressed: () => Navigator.of(Get.context!).pop(false),
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
                    onPressed: () => Navigator.of(Get.context!).pop(true),
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

      debugPrint(
          '✅ Partner status updated to: ${isOnline.value ? "Online" : "Offline"}');
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

      // Force status to online initially on login/startup
      isOnline.value = true;

      await FirebaseFirestore.instance
          .collection('partners')
          .doc(user.uid)
          .update({
        'isOnline': true,
        'lastStatusUpdate': Timestamp.now(),
      });
      debugPrint('✅ Initial online status loaded as ONLINE: true');
    } catch (e) {
      debugPrint('❌ Error setting initial online status: $e');
      // Fallback
      isOnline.value = true;
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
        debugPrint('🏠 HomePartner: onMapCreated animateCamera failed: $e');
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
        debugPrint('🏠 HomePartner: zoomIn failed: $e');
      }
    }
  }

  Future<void> zoomOut() async {
    if (_controller.isCompleted) {
      try {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(CameraUpdate.zoomOut());
      } catch (e) {
        debugPrint('🏠 HomePartner: zoomOut failed: $e');
      }
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
        try {
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
          await controller
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
        } catch (e) {
          debugPrint(
              '🏠 HomePartner: showRouteToUser animateCamera failed: $e');
        }
      }

      Alert.info(
        'Patient location has been marked on the map',
      );
    } catch (e) {
      Alert.info(
        'Failed to show route to user: $e',
      );
    }
  }

  Future<void> animateCameraToCurrent() async {
    if (_controller.isCompleted && currentPosition.value != null) {
      try {
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: currentPosition.value!, zoom: 14),
          ),
        );
      } catch (e) {
        debugPrint('🏠 HomePartner: animateCameraToCurrent failed: $e');
      }
    }
  }
}
