import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'partner_notification_controller.dart';

class PartnerNotificationPage extends StatelessWidget {
  const PartnerNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GetBuilder<PartnerNotificationController>(
      init: PartnerNotificationController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Obx(() => Text(
              'Notifications ${controller.unreadCount.value > 0 ? '(${controller.unreadCount.value})' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600),
             
            )
            ),
            centerTitle: true,
            backgroundColor: Colors.teal.shade800,
            elevation: 2,
            iconTheme: IconThemeData(color: colorScheme.onPrimary),
            titleTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 18),
            actions: [
              Obx(() => controller.notifications.isNotEmpty
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'mark_all_read':
                          controller.markAllAsRead();
                          break;
                        case 'clear_all':
                          _showClearAllDialog(context, controller);
                          break;
                        case 'add_test':
                          controller.addTestNotification();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'mark_all_read',
                        child: Text('Mark All as Read'),
                      ),
                      const PopupMenuItem(
                        value: 'clear_all',
                        child: Text('Clear All'),
                      ),
                      const PopupMenuItem(
                        value: 'add_test',
                        child: Text('Add Test Notification'),
                      ),
                    ],
                  )
                : const SizedBox()),
            ],
          ),
          backgroundColor: colorScheme.surface,
          body: Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(color: Colors.teal.shade800),
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
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.error.value,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            if (controller.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ll receive notifications for new orders and updates here',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.notifications.length,
              itemBuilder: (context, index) {
                final notification = controller.notifications[index];
                return _buildNotificationCard(notification, controller, colorScheme, context);
              },
            );
          }),
        );
      },
    );
  }

  Widget _buildNotificationCard(
    PartnerNotification notification,
    PartnerNotificationController controller,
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
              ? [colorScheme.surface, colorScheme.surface.withValues(alpha: 0.8)]
              : [_getNotificationColor(notification.type).withValues(alpha: 0.1), colorScheme.surface],
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
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                      onPressed: () => _showDeleteDialog(context, notification, controller),
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
      case 'order':
        icon = Icons.assignment;
        color = Colors.blue;
        break;
      case 'emergency':
        icon = Icons.warning;
        color = Colors.red;
        break;
      case 'system':
        icon = Icons.info;
        color = Colors.orange;
        break;
      case 'info':
      default:
        icon = Icons.notifications;
        color = Colors.teal;
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
      case 'order':
        return Colors.blue;
      case 'emergency':
        return Colors.red;
      case 'system':
        return Colors.orange;
      case 'info':
      default:
        return Colors.teal;
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

  void _showDeleteDialog(BuildContext context, PartnerNotification notification, PartnerNotificationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
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

  void _showClearAllDialog(BuildContext context, PartnerNotificationController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
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

  void _handleNotificationTap(PartnerNotification notification, PartnerNotificationController controller) {
    // Mark as read if not already
    if (!notification.isRead) {
      controller.markAsRead(notification.id);
    }

    // Handle navigation based on notification type and data
    if (notification.data != null) {
      final data = notification.data!;
      final type = data['type'];
      final orderId = data['orderId'];
      final userId = data['userId'];

      if (type == 'ambulance_request') {
        // Show detailed ambulance request information
        _showAmbulanceRequestDetails(data);
      } else if (orderId != null) {
        // Navigate to order details
        Get.toNamed('/partner-orders', arguments: {'orderId': orderId});
      } else if (userId != null) {
        // Navigate to user details or chat
        Get.toNamed('/chat', arguments: {'userId': userId});
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
                      Icon(Icons.emergency, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'অ্যাম্বুলেন্স অনুরোধ',
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

                  // Patient Information
                  _buildSectionHeader('রোগীর তথ্য'),
                  _buildInfoRow('নাম', data['patientName'] ?? 'N/A'),
                  _buildInfoRow('বয়স', data['patientAge'] ?? 'N/A'),
                  _buildInfoRow('লিঙ্গ', data['patientGender'] ?? 'N/A'),
                  _buildInfoRow('ওজন', data['patientWeight'] ?? 'N/A'),
                  _buildInfoRow('রক্তের গ্রুপ', data['bloodGroup'] ?? 'N/A'),

                  const SizedBox(height: 16),

                  // Contact Information
                  _buildSectionHeader('যোগাযোগের তথ্য'),
                  _buildInfoRow('ফোন নম্বর', data['phoneNumber'] ?? 'N/A'),
                  _buildInfoRow('ইমেইল', data['email'] ?? 'N/A'),
                  _buildInfoRow('জরুরী যোগাযোগ', data['emergencyContact'] ?? 'N/A'),

                  const SizedBox(height: 16),

                  // Medical Information
                  _buildSectionHeader('চিকিৎসা তথ্য'),
                  _buildInfoRow('চিকিৎসা ইতিহাস', data['medicalHistory'] ?? 'N/A'),
                  _buildInfoRow('বর্তমান অসুস্থতা', data['currentCondition'] ?? 'N/A'),
                  _buildInfoRow('অ্যালার্জি', data['allergies'] ?? 'N/A'),
                  _buildInfoRow('ওষুধ', data['medications'] ?? 'N/A'),

                  const SizedBox(height: 16),

                  // Location Information
                  _buildSectionHeader('অবস্থান তথ্য'),
                  _buildInfoRow('অবস্থান', data['location'] ?? 'N/A'),
                  _buildInfoRow('বিস্তারিত ঠিকানা', data['detailedAddress'] ?? 'N/A'),
                  _buildInfoRow('ল্যাটিটিউড', data['latitude']?.toString() ?? 'N/A'),
                  _buildInfoRow('লংগিটিউড', data['longitude']?.toString() ?? 'N/A'),

                  const SizedBox(height: 16),

                  // Additional Information
                  _buildSectionHeader('অতিরিক্ত তথ্য'),
                  _buildInfoRow('অনুরোধের সময়', data['requestTime'] ?? 'N/A'),
                  _buildInfoRow('অগ্রাধিকার', data['priority'] ?? 'N/A'),
                  _buildInfoRow('বিশেষ নির্দেশনা', data['specialInstructions'] ?? 'N/A'),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            // Navigate to accept the request
                            Get.toNamed('/accept-maps', arguments: {
                              'requestData': data,
                              'isFromNotification': true,
                            });
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('গ্রহণ করুন'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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
                          label: const Text('বাতিল করুন'),
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
