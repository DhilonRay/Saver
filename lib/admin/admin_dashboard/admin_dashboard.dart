import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_users/admin_users_screen.dart';
import '../admin_orders/admin_orders_screen.dart';
import '../admin_partners/admin_partners_screen.dart';
import '../admin_tracking/admin_tracking_screen.dart';
import '../admin_notifications/admin_notifications_screen.dart';
import '../admin_analytics/admin_analytics_screen.dart';
import '../../auth/log_in/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Statistics
  int totalUsers = 0;
  int totalPartners = 0;
  int totalOrders = 0;
  int activeOrders = 0;
  int completedOrders = 0;
  double totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      // Get total users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      totalUsers = usersSnapshot.size;

      // Get total partners
      QuerySnapshot partnersSnapshot =
          await _firestore.collection('partners').get();
      totalPartners = partnersSnapshot.size;

      // Get total orders
      QuerySnapshot ordersSnapshot =
          await _firestore.collection('orders').get();
      totalOrders = ordersSnapshot.size;

      // Get active orders
      QuerySnapshot activeOrdersSnapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: ['pending', 'accepted', 'picked_up']).get();
      activeOrders = activeOrdersSnapshot.size;

      // Get completed orders
      QuerySnapshot completedOrdersSnapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .get();
      completedOrders = completedOrdersSnapshot.size;

      // Calculate total revenue
      double revenue = 0.0;
      for (var doc in completedOrdersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        revenue += (data['totalAmount'] ?? 0).toDouble();
      }
      totalRevenue = revenue;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade900],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back, Admin!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your application from here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Section
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Statistics Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Partners',
                    totalPartners.toString(),
                    Icons.delivery_dining,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Total Orders',
                    totalOrders.toString(),
                    Icons.shopping_bag,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Active Orders',
                    activeOrders.toString(),
                    Icons.local_shipping,
                    Colors.purple,
                  ),
                  _buildStatCard(
                    'Completed',
                    completedOrders.toString(),
                    Icons.check_circle,
                    Colors.teal,
                  ),
                  _buildStatCard(
                    'Revenue',
                    '৳${totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Management Options
              const Text(
                'Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildMenuTile(
                'User Management',
                'View and manage all users',
                Icons.people_alt,
                Colors.blue,
                () => Get.to(() => const AdminUsersScreen()),
              ),
              _buildMenuTile(
                'Order Management',
                'Track and manage orders',
                Icons.assignment,
                Colors.orange,
                () => Get.to(() => const AdminOrdersScreen()),
              ),
              _buildMenuTile(
                'Partner Management',
                'Manage delivery partners',
                Icons.delivery_dining,
                Colors.green,
                () => Get.to(() => const AdminPartnersScreen()),
              ),
              _buildMenuTile(
                'Live Tracking',
                'Track active deliveries',
                Icons.map,
                Colors.purple,
                () => Get.to(() => const AdminTrackingScreen()),
              ),
              _buildMenuTile(
                'Send Notifications',
                'Send push notifications',
                Icons.notifications_active,
                Colors.red,
                () => Get.to(() => const AdminNotificationsScreen()),
              ),
              _buildMenuTile(
                'Analytics & Reports',
                'View detailed analytics',
                Icons.analytics,
                Colors.teal,
                () => Get.to(() => const AdminAnalyticsScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
