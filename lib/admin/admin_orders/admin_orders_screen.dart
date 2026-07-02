import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../widgets/billing_breakdown_widget.dart';
import '../admin_theme.dart';
import '../../services/supabase_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: const AdminAppBar(title: 'Order Management'),
      body: Container(
        decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
        child: Column(
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AdminFilterChip(
                      label: 'All',
                      selected: _selectedFilter == 'all',
                      onTap: () => setState(() => _selectedFilter = 'all')),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Pending',
                      selected: _selectedFilter == 'pending',
                      onTap: () => setState(() => _selectedFilter = 'pending')),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Accepted',
                      selected: _selectedFilter == 'accepted',
                      onTap: () =>
                          setState(() => _selectedFilter = 'accepted')),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Picked Up',
                      selected: _selectedFilter == 'picked_up',
                      onTap: () =>
                          setState(() => _selectedFilter = 'picked_up')),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Completed',
                      selected: _selectedFilter == 'completed',
                      onTap: () =>
                          setState(() => _selectedFilter = 'completed')),
                  const SizedBox(width: 8),
                  AdminFilterChip(
                      label: 'Cancelled',
                      selected: _selectedFilter == 'cancelled',
                      onTap: () =>
                          setState(() => _selectedFilter = 'cancelled')),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _selectedFilter == 'all'
                    ? SupabaseService.client
                        .from('orders')
                        .stream(primaryKey: ['id'])
                    : SupabaseService.client.from('orders').stream(
                        primaryKey: ['id']).eq('status', _selectedFilter),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: AdminTheme.body));
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AdminTheme.accent));

                  // Sort locally to avoid composite index requirement
                  var orders =
                      List<Map<String, dynamic>>.from(snapshot.data ?? []);
                  orders.sort((a, b) {
                    try {
                      final aTStr = a['created_at'] ?? a['timestamp'];
                      final bTStr = b['created_at'] ?? b['timestamp'];
                      if (aTStr == null) return 1;
                      if (bTStr == null) return -1;
                      final aT = DateTime.tryParse(aTStr.toString());
                      final bT = DateTime.tryParse(bTStr.toString());
                      if (aT == null) return 1;
                      if (bT == null) return -1;
                      return bT.compareTo(aT);
                    } catch (_) {
                      return 0;
                    }
                  });
                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: AdminTheme.bgSurface.withOpacity(0.5),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.shopping_bag_rounded,
                                size: 40, color: AdminTheme.textMuted),
                          ),
                          const SizedBox(height: 14),
                          const Text('No orders found', style: AdminTheme.body),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var orderData =
                          SupabaseService.toCamelCase(orders[index]);
                      var orderId = orderData['id'] ?? orderData['uid'] ?? '';
                      final statusColor =
                          _getStatusColor(orderData['status'] ?? 'pending');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          onTap: () => _viewOrderDetails(orderId, orderData),
                          accentColor: statusColor,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      orderId.length > 8
                                          ? 'Order #${orderId.substring(0, 8)}'
                                          : 'Order #$orderId',
                                      style: AdminTheme.heading3),
                                  AdminStatusBadge(
                                      label: (orderData['status'] ?? 'pending')
                                          .toString()
                                          .toUpperCase(),
                                      color: statusColor),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                  'Customer: ${orderData['userName'] ?? 'N/A'}',
                                  style: AdminTheme.body),
                              const SizedBox(height: 4),
                              Text('Amount: ৳${orderData['totalAmount'] ?? 0}',
                                  style: AdminTheme.heading3.copyWith(
                                      color: AdminTheme.green, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                orderData['createdAt'] != null
                                    ? DateFormat('dd MMM yyyy, hh:mm a').format(
                                        DateTime.tryParse(
                                            orderData['createdAt'].toString())!)
                                    : orderData['timestamp'] != null
                                        ? DateFormat('dd MMM yyyy, hh:mm a')
                                            .format(DateTime.tryParse(
                                                orderData['timestamp']
                                                    .toString())!)
                                        : 'N/A',
                                style: AdminTheme.bodySmall,
                              ),
                              if (orderData['partnerName'] != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.delivery_dining_rounded,
                                        size: 14,
                                        color:
                                            AdminTheme.blue.withOpacity(0.7)),
                                    const SizedBox(width: 5),
                                    Text(orderData['partnerName'],
                                        style: AdminTheme.bodySmall
                                            .copyWith(color: AdminTheme.blue)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewOrderDetails(String orderId, Map<String, dynamic> orderData) {
    final statusColor = _getStatusColor(orderData['status'] ?? 'pending');
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AdminTheme.bgCard,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AdminTheme.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.assignment_rounded,
                            color: AdminTheme.blue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              orderId.length > 8
                                  ? 'Order #${orderId.substring(0, 8)}'
                                  : 'Order #$orderId',
                              style: AdminTheme.heading2)),
                      AdminStatusBadge(
                          label: (orderData['status'] ?? 'pending')
                              .toString()
                              .toUpperCase(),
                          color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.04)),
                  const SizedBox(height: 12),
                  AdminDetailRow(
                      label: 'Customer', value: orderData['userName'] ?? 'N/A'),
                  AdminDetailRow(
                      label: 'Phone', value: orderData['userPhone'] ?? 'N/A'),
                  AdminDetailRow(
                      label: 'Pickup',
                      value: orderData['pickupAddress'] ?? 'N/A'),
                  AdminDetailRow(
                      label: 'Delivery',
                      value: orderData['deliveryAddress'] ?? 'N/A'),
                  if (orderData['partnerName'] != null)
                    AdminDetailRow(
                        label: 'Partner', value: orderData['partnerName']),
                  AdminDetailRow(
                    label: 'Order Date',
                    value: orderData['createdAt'] != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(
                            DateTime.tryParse(
                                orderData['createdAt'].toString())!)
                        : orderData['timestamp'] != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(
                                DateTime.tryParse(
                                    orderData['timestamp'].toString())!)
                            : 'N/A',
                  ),
                  const SizedBox(height: 16),

                  // Payment Details
                  const AdminSectionHeader(
                      title: 'Payment Info', icon: Icons.payment_rounded),
                  if (orderData['payment'] != null) ...[
                    AdminDetailRow(
                        label: 'Method',
                        value: (orderData['payment']['method'] ?? 'N/A')
                            .toUpperCase()),
                    if (orderData['payment']['method'] == 'bkash') ...[
                      AdminDetailRow(
                          label: 'TRXID',
                          value: orderData['payment']['trxId'] ?? 'N/A'),
                      AdminDetailRow(
                          label: 'Sender',
                          value: orderData['payment']['senderNumber'] ?? 'N/A'),
                    ],
                    AdminDetailRow(
                        label: 'Status',
                        value: (orderData['payment']['status'] ?? 'pending')
                            .toUpperCase()),
                  ],
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    double fare = 0.0;
                    if (orderData['payment'] != null &&
                        orderData['payment']['fare'] != null) {
                      fare = (orderData['payment']['fare'] as num).toDouble();
                    } else {
                      fare =
                          (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;
                    }
                    return BillingBreakdownWidget(fare: fare);
                  }),
                  const SizedBox(height: 20),
                  const AdminSectionHeader(
                      title: 'Update Status', icon: Icons.edit_rounded),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusButton('Pending', 'pending', orderId),
                      _buildStatusButton('Accepted', 'accepted', orderId),
                      _buildStatusButton('Picked Up', 'picked_up', orderId),
                      _buildStatusButton('Completed', 'completed', orderId),
                      _buildStatusButton('Cancelled', 'cancelled', orderId),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                      ),
                      child: const Text('Close',
                          style: TextStyle(color: AdminTheme.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, String status, String orderId) {
    final color = _getStatusColor(status);
    return GestureDetector(
      onTap: () => _updateOrderStatus(orderId, status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AdminTheme.orange;
      case 'accepted':
        return AdminTheme.blue;
      case 'picked_up':
        return AdminTheme.purple;
      case 'completed':
        return AdminTheme.green;
      case 'cancelled':
        return AdminTheme.red;
      default:
        return AdminTheme.textMuted;
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await SupabaseService.updateOrder(orderId, {
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      Get.back();
    // ignore: empty_catches
    } catch (e) {}
  }
}
