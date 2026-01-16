import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      QuerySnapshot allOrdersSnapshot =
          await _firestore.collection('orders').get();
      totalOrders = allOrdersSnapshot.size;

      // Calculate revenues
      double allRevenue = 0.0;
      double todayRev = 0.0;
      double weekRev = 0.0;
      double monthRev = 0.0;
      int todayCount = 0;
      int weekCount = 0;
      int monthCount = 0;

      for (var doc in allOrdersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['status'] == 'completed') {
          double amount = (data['totalAmount'] ?? 0).toDouble();
          allRevenue += amount;

          if (data['createdAt'] != null) {
            DateTime orderDate = (data['createdAt'] as Timestamp).toDate();

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

      totalRevenue = allRevenue;
      todayRevenue = todayRev;
      weekRevenue = weekRev;
      monthRevenue = monthRev;
      todayOrders = todayCount;
      weekOrders = weekCount;
      monthOrders = monthCount;

      // Get users stats
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      totalUsers = usersSnapshot.size;
      activeUsers = usersSnapshot.docs
          .where(
              (doc) => (doc.data() as Map<String, dynamic>)['isActive'] ?? true)
          .length;

      // Get partners stats
      QuerySnapshot partnersSnapshot =
          await _firestore.collection('partners').get();
      totalPartners = partnersSnapshot.size;
      activePartners = partnersSnapshot.docs
          .where((doc) =>
              ((doc.data() as Map<String, dynamic>)['isActive'] ?? true) &&
              ((doc.data() as Map<String, dynamic>)['isApproved'] ?? false))
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
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue Section
                    const Text(
                      'Revenue Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildRevenueRow(
                                'Total Revenue', totalRevenue, Colors.green),
                            const Divider(),
                            _buildRevenueRow(
                                'Today', todayRevenue, Colors.blue),
                            const Divider(),
                            _buildRevenueRow(
                                'This Week', weekRevenue, Colors.purple),
                            const Divider(),
                            _buildRevenueRow(
                                'This Month', monthRevenue, Colors.orange),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Orders Section
                    const Text(
                      'Orders Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Total Orders',
                          totalOrders.toString(),
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Today',
                          todayOrders.toString(),
                          Icons.today,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'This Week',
                          weekOrders.toString(),
                          Icons.calendar_view_week,
                          Colors.purple,
                        ),
                        _buildStatCard(
                          'This Month',
                          monthOrders.toString(),
                          Icons.calendar_month,
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Users & Partners Section
                    const Text(
                      'Users & Partners',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 48,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    totalUsers.toString(),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const Text(
                                    'Total Users',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$activeUsers Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.delivery_dining,
                                    size: 48,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    totalPartners.toString(),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const Text(
                                    'Total Partners',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$activePartners Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top Partners Section
                    const Text(
                      'Top Performing Partners',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('partners')
                          .orderBy('completedOrders', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var partners = snapshot.data!.docs;

                        if (partners.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'No partner data available',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ),
                          );
                        }

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: partners.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              var partnerData = partners[index].data()
                                  as Map<String, dynamic>;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade100,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  partnerData['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Vehicle: ${partnerData['vehicleType'] ?? 'N/A'}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${partnerData['completedOrders'] ?? 0} orders',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    Text(
                                      '৳${partnerData['totalEarnings'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Recent Orders Section
                    const Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('orders')
                          .orderBy('createdAt', descending: true)
                          .limit(10)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var orders = snapshot.data!.docs;

                        if (orders.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'No orders yet',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ),
                          );
                        }

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orders.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              var orderData =
                                  orders[index].data() as Map<String, dynamic>;
                              var orderId = orders[index].id;

                              return ListTile(
                                leading: Icon(
                                  Icons.shopping_bag,
                                  color: _getStatusColor(
                                      orderData['status'] ?? 'pending'),
                                ),
                                title: Text(
                                  'Order #${orderId.substring(0, 8)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  orderData['userName'] ?? 'Unknown',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '৳${orderData['totalAmount'] ?? 0}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      orderData['status']
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _getStatusColor(
                                            orderData['status'] ?? 'pending'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRevenueRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '৳${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'picked_up':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
