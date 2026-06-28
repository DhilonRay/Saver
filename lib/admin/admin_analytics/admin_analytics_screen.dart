import 'package:flutter/material.dart';
import '../admin_theme.dart';
import '../../services/supabase_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  // Analytics Data
  int totalOrders = 0;
  int todayOrders = 0;
  int weekOrders = 0;
  int monthOrders = 0;

  double totalRevenue = 0.0;
  double todayRevenue = 0.0;
  double weekRevenue = 0.0;
  double monthRevenue = 0.0;

  int totalUsers = 0;
  int activeUsers = 0;
  int totalPartners = 0;
  int activePartners = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
      DateTime monthStart = DateTime(now.year, now.month, 1);

      // Get all orders
      final allOrdersSnapshot =
          await SupabaseService.client.from('orders').select();
      totalOrders = allOrdersSnapshot.length;

      // Calculate revenues
      double allRevenue = 0.0;
      double todayRev = 0.0;
      double weekRev = 0.0;
      double monthRev = 0.0;
      int todayCount = 0;
      int weekCount = 0;
      int monthCount = 0;

      for (var item in allOrdersSnapshot) {
        var data = SupabaseService.toCamelCase(item);
        if (data['status'] == 'completed') {
          double amount = (data['totalAmount'] ?? 0).toDouble();
          allRevenue += amount;

          final timeVal = data['createdAt'] ?? data['timestamp'];
          if (timeVal != null) {
            DateTime? orderDate = DateTime.tryParse(timeVal.toString());

            if (orderDate != null) {
              if (orderDate.isAfter(todayStart)) {
                todayRev += amount;
                todayCount++;
              }
              if (orderDate.isAfter(weekStart)) {
                weekRev += amount;
                weekCount++;
              }
              if (orderDate.isAfter(monthStart)) {
                monthRev += amount;
                monthCount++;
              }
            }
          }
        }
      }

      totalRevenue = allRevenue;
      todayRevenue = todayRev;
      weekRevenue = weekRev;
      monthRevenue = monthRev;
      todayOrders = todayCount;
      weekOrders = weekCount;
      monthOrders = monthCount;

      // Get users stats
      final usersSnapshot = await SupabaseService.client.from('users').select();
      totalUsers = usersSnapshot.length;
      activeUsers = usersSnapshot
          .where(
              (item) => (SupabaseService.toCamelCase(item))['isActive'] ?? true)
          .length;

      // Get partners stats
      final partnersSnapshot =
          await SupabaseService.client.from('partners').select();
      totalPartners = partnersSnapshot.length;
      activePartners = partnersSnapshot
          .where((item) {
            final data = SupabaseService.toCamelCase(item);
            return (data['isActive'] ?? true) && (data['isApproved'] ?? false);
          })
          .length;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: AdminAppBar(
        title: 'Analytics & Reports',
        actions: [
          GestureDetector(
            onTap: _loadAnalytics,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminTheme.bgSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded, color: AdminTheme.textSecondary, size: 22),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AdminTheme.accent))
          : Container(
              decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
              child: RefreshIndicator(
                onRefresh: _loadAnalytics,
                color: AdminTheme.accent,
                backgroundColor: AdminTheme.bgCard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Revenue Section
                      const AdminSectionHeader(title: 'Revenue Analytics', icon: Icons.trending_up_rounded, color: AdminTheme.green),
                      GlassCard(
                        accentColor: AdminTheme.green,
                        child: Column(
                          children: [
                            _buildRevenueRow('Total Revenue', totalRevenue, AdminTheme.green),
                            Divider(color: Colors.white.withOpacity(0.04), height: 24),
                            _buildRevenueRow('Today', todayRevenue, AdminTheme.blue),
                            Divider(color: Colors.white.withOpacity(0.04), height: 24),
                            _buildRevenueRow('This Week', weekRevenue, AdminTheme.purple),
                            Divider(color: Colors.white.withOpacity(0.04), height: 24),
                            _buildRevenueRow('This Month', monthRevenue, AdminTheme.orange),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Orders Section
                      const AdminSectionHeader(title: 'Orders Analytics', icon: Icons.shopping_bag_rounded, color: AdminTheme.blue),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.35,
                        children: [
                          AdminStatCard(title: 'Total Orders', value: totalOrders.toString(), icon: Icons.shopping_bag_rounded, color: AdminTheme.blue),
                          AdminStatCard(title: 'Today', value: todayOrders.toString(), icon: Icons.today_rounded, color: AdminTheme.green),
                          AdminStatCard(title: 'This Week', value: weekOrders.toString(), icon: Icons.calendar_view_week_rounded, color: AdminTheme.purple),
                          AdminStatCard(title: 'This Month', value: monthOrders.toString(), icon: Icons.calendar_month_rounded, color: AdminTheme.orange),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Users & Partners Section
                      const AdminSectionHeader(title: 'Users & Partners', icon: Icons.people_rounded, color: AdminTheme.accent),
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              accentColor: AdminTheme.blue,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AdminTheme.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.people_rounded, size: 28, color: AdminTheme.blue),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(totalUsers.toString(), style: AdminTheme.stat.copyWith(color: AdminTheme.blue)),
                                  const Text('Total Users', style: AdminTheme.bodySmall),
                                  const SizedBox(height: 4),
                                  AdminMiniTag(text: '$activeUsers Active', color: AdminTheme.green),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: GlassCard(
                              accentColor: AdminTheme.green,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AdminTheme.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.delivery_dining_rounded, size: 28, color: AdminTheme.green),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(totalPartners.toString(), style: AdminTheme.stat.copyWith(color: AdminTheme.green)),
                                  const Text('Total Partners', style: AdminTheme.bodySmall),
                                  const SizedBox(height: 4),
                                  AdminMiniTag(text: '$activePartners Active', color: AdminTheme.green),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Top Partners
                      const AdminSectionHeader(title: 'Top Performing Partners', icon: Icons.emoji_events_rounded, color: AdminTheme.amber),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('partners')
                            .orderBy('completedOrders', descending: true)
                            .limit(5)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));

                          var partners = snapshot.data!.docs;
                          if (partners.isEmpty) {
                            return GlassCard(
                              child: const Center(child: Text('No partner data available', style: AdminTheme.body)),
                            );
                          }

                          return GlassCard(
                            accentColor: AdminTheme.amber,
                            child: Column(
                              children: partners.asMap().entries.map((entry) {
                                var partnerData = entry.value.data() as Map<String, dynamic>;
                                List<String> emojis = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: entry.key < partners.length - 1 ? 12 : 0,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(emojis[entry.key], style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(partnerData['name'] ?? 'Unknown', style: AdminTheme.heading3.copyWith(fontSize: 13)),
                                            Text('Vehicle: ${partnerData['vehicleType'] ?? 'N/A'}', style: AdminTheme.bodySmall),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('${partnerData['completedOrders'] ?? 0} orders', style: AdminTheme.bodySmall.copyWith(color: AdminTheme.blue, fontWeight: FontWeight.w600)),
                                          Text('৳${partnerData['totalEarnings'] ?? 0}', style: AdminTheme.bodySmall.copyWith(color: AdminTheme.green)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Recent Orders
                      const AdminSectionHeader(title: 'Recent Orders', icon: Icons.receipt_long_rounded, color: AdminTheme.blue),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('orders')
                            .orderBy('createdAt', descending: true)
                            .limit(10)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));

                          var orders = snapshot.data!.docs;
                          if (orders.isEmpty) {
                            return GlassCard(child: const Center(child: Text('No orders yet', style: AdminTheme.body)));
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              var orderData = orders[index].data() as Map<String, dynamic>;
                              var orderId = orders[index].id;
                              final statusColor = _getStatusColor(orderData['status'] ?? 'pending');

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.shopping_bag_rounded, color: statusColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Order #${orderId.substring(0, 8)}',
                                              style: AdminTheme.heading3.copyWith(fontSize: 13),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(orderData['userName'] ?? 'Unknown', style: AdminTheme.bodySmall),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '৳${orderData['totalAmount'] ?? 0}',
                                            style: AdminTheme.heading3.copyWith(color: AdminTheme.green, fontSize: 13),
                                          ),
                                          const SizedBox(height: 3),
                                          AdminStatusBadge(
                                            label: (orderData['status'] ?? 'pending').toString().toUpperCase(),
                                            color: statusColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildRevenueRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AdminTheme.body),
        Text(
          '৳${amount.toStringAsFixed(2)}',
          style: AdminTheme.heading3.copyWith(color: color),
        ),
      ],
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
}
