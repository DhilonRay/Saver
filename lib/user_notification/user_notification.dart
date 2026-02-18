import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:saver/components/constants/colors.dart';
import 'package:saver/components/text_styles.dart';
import 'package:saver/components/widgets/buttons.dart';
import 'package:saver/components/widgets/space.dart';
import 'user_notification_controller.dart';

class UserNotificationPage extends StatelessWidget {
  const UserNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserNotificationController>(
      init: UserNotificationController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.primaryLight,
            leading: BackButtonWidget(onTap: () => Get.back()),
            title: Text(
              'Notification',
              style: AppTextStyles.extraBodyLarge.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.border,
              ),
            ),
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.error.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    const VerticalGap(16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        controller.error.value,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const VerticalGap(16),
                    FilledButtonWidget(
                      buttonText: 'Go Back',
                      onTap: () => Get.back(),
                    ),
                  ],
                ),
              );
            }

            if (controller.notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 64,
                        color: AppColors.primaryText,
                      ),
                      const VerticalGap(24),
                      Text(
                        'এখানে কোন নোটিফিকেশন নেই',
                        style: AppTextStyles.bodyLargeSemibold.copyWith(
                          color: AppColors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const VerticalGap(8),
                      Text(
                        'আপডেট অনুরোধ এবং আপডেটের জন্য\nএখানে নোটিফিকেশন পাবেন',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.notifications.length,
              itemBuilder: (context, index) {
                final notification = controller.notifications[index];
                final colorScheme = Theme.of(context).colorScheme;
                return _buildNotificationCard(
                    notification, controller, colorScheme, context);
              },
            );
          }),
        );
      },
    );
  }

  Widget _buildNotificationCard(
    UserNotification notification,
    UserNotificationController controller,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: notification.isRead
                ? [
                    colorScheme.surface,
                    colorScheme.surface.withValues(alpha: 0.8)
                  ]
                : [
                    _getNotificationColor(notification.type)
                        .withValues(alpha: 0.1),
                    colorScheme.surface
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification, controller),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildNotificationIcon(notification.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: TextStyle(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getNotificationColor(notification.type),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!notification.isRead)
                      TextButton(
                        onPressed: () => controller.markAsRead(notification.id),
                        child: Text(
                          'Mark as Read',
                          style: TextStyle(
                            color: _getNotificationColor(notification.type),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () =>
                          _showDeleteDialog(context, notification, controller),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'ambulance':
        icon = Icons.local_hospital;
        color = Colors.red;
        break;
      case 'emergency':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'system':
        icon = Icons.info;
        color = Colors.blue;
        break;
      case 'info':
      default:
        icon = Icons.notifications;
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'ambulance':
        return Colors.red;
      case 'emergency':
        return Colors.orange;
      case 'system':
        return Colors.blue;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showDeleteDialog(BuildContext context, UserNotification notification,
      UserNotificationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteNotification(notification.id);
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(
      BuildContext context, UserNotificationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.clearAllNotifications();
              Get.back();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
      UserNotification notification, UserNotificationController controller) {
    // Mark as read if not already
    if (!notification.isRead) {
      controller.markAsRead(notification.id);
    }

    // Handle navigation based on notification type and data
    if (notification.data != null) {
      final data = notification.data!;
      final type = data['type'];
      final requestId = data['requestId'];
      final partnerId = data['partnerId'];

      if (type == 'ambulance_request') {
        // Show detailed ambulance request information
        _showAmbulanceRequestDetails(data);
      } else if (requestId != null) {
        // Navigate to request details or tracking
        Get.toNamed('/user-tracking', arguments: {'requestId': requestId});
      } else if (partnerId != null) {
        // Navigate to chat with partner
        Get.toNamed('/chat', arguments: {'partnerId': partnerId});
      }
    }
  }

  void _showAmbulanceRequestDetails(Map<String, dynamic> data) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.8),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.local_hospital, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'অ্যাম্বুলেন্স অনুরোধের তথ্য',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Request Information
                  _buildSectionHeader('অনুরোধের তথ্য'),
                  _buildInfoRow('অনুরোধ আইডি', data['requestId'] ?? 'N/A'),
                  _buildInfoRow('স্ট্যাটাস', data['status'] ?? 'N/A'),
                  _buildInfoRow('অনুরোধের সময়', data['requestTime'] ?? 'N/A'),
                  _buildInfoRow('অগ্রাধিকার', data['priority'] ?? 'N/A'),

                  const SizedBox(height: 16),

                  // Partner Information
                  _buildSectionHeader('পার্টনার তথ্য'),
                  _buildInfoRow('পার্টনার নাম', data['partnerName'] ?? 'N/A'),
                  _buildInfoRow('ফোন নম্বর', data['partnerPhone'] ?? 'N/A'),
                  _buildInfoRow(
                      'অ্যাম্বুলেন্স টাইপ', data['ambulanceType'] ?? 'N/A'),
                  _buildInfoRow('ভাড়া', data['fare'] ?? 'N/A'),

                  const SizedBox(height: 16),

                  // Location Information
                  _buildSectionHeader('অবস্থান তথ্য'),
                  _buildInfoRow(
                      'পিকআপ পয়েন্ট', data['pickupLocation'] ?? 'N/A'),
                  _buildInfoRow('গন্তব্য', data['destination'] ?? 'N/A'),
                  _buildInfoRow('দূরত্ব', data['distance'] ?? 'N/A'),
                  _buildInfoRow(
                      'আনুমানিক সময়', data['estimatedTime'] ?? 'N/A'),

                  const SizedBox(height: 16),

                  // Additional Information
                  if (data['specialInstructions'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('বিশেষ নির্দেশনা'),
                        Text(
                          data['specialInstructions'],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            // Navigate to tracking page
                            Get.toNamed('/user-tracking', arguments: {
                              'requestId': data['requestId'],
                              'partnerId': data['partnerId'],
                            });
                          },
                          icon: const Icon(Icons.track_changes),
                          label: const Text('ট্র্যাক করুন'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close),
                          label: const Text('বন্ধ করুন'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
