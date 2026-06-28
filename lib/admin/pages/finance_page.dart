import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import '../admin_controller.dart';
import '../admin_theme.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final AdminController _ctrl = Get.find<AdminController>();
  String _selectedPeriod = 'week';
  bool _isLoading = true;

  double _revenue = 0;
  double _profit = 0;
  int _tripCount = 0;
  String _topEarner = 'N/A';
  double _topEarning = 0;

  @override
  void initState() {
    super.initState();
    _loadFinance();
  }

  Future<void> _loadFinance() async {
    setState(() => _isLoading = true);
    try {
      var data = await _ctrl.getFinanceData(_selectedPeriod);
      setState(() {
        _revenue = data['revenue'];
        _profit = data['profit'];
        _tripCount = data['tripCount'];
        _topEarner = data['topEarner'];
        _topEarning = data['topEarning'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AdminTheme.bgGradient),
      child: RefreshIndicator(
        onRefresh: _loadFinance,
        color: AdminTheme.accent,
        backgroundColor: AdminTheme.bgCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period filter
              Row(
                children: [
                  Text('Period', style: AdminTheme.bodySmall.copyWith(color: AdminTheme.textSecondary)),
                  const SizedBox(width: 14),
                  AdminFilterChip(label: 'Week', selected: _selectedPeriod == 'week', onTap: () { setState(() => _selectedPeriod = 'week'); _loadFinance(); }),
                  const SizedBox(width: 8),
                  AdminFilterChip(label: 'Month', selected: _selectedPeriod == 'month', onTap: () { setState(() => _selectedPeriod = 'month'); _loadFinance(); }),
                  const SizedBox(width: 8),
                  AdminFilterChip(label: 'Year', selected: _selectedPeriod == 'year', onTap: () { setState(() => _selectedPeriod = 'year'); _loadFinance(); }),
                ],
              ),
              const SizedBox(height: 22),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator(color: AdminTheme.accent),
                  ),
                )
              else ...[
                // Revenue card
                _buildBigStatCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: AdminTheme.green,
                  title: 'Total Revenue',
                  value: '৳${_revenue.toStringAsFixed(0)}',
                  valueColor: AdminTheme.green,
                ),
                const SizedBox(height: 14),

                // Profit card
                _buildBigStatCard(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AdminTheme.accent,
                  title: 'Total Profit (5% Commission)',
                  value: '৳${_profit.toStringAsFixed(0)}',
                  valueColor: AdminTheme.accent,
                ),
                const SizedBox(height: 14),

                // Two column cards
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        accentColor: AdminTheme.orange,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AdminTheme.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.route_rounded, color: AdminTheme.orange, size: 22),
                            ),
                            const SizedBox(height: 10),
                            Text('Total Trips', style: AdminTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              '$_tripCount',
                              style: AdminTheme.stat.copyWith(color: AdminTheme.orange, fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GlassCard(
                        accentColor: AdminTheme.amber,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AdminTheme.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.emoji_events_rounded, color: AdminTheme.amber, size: 22),
                            ),
                            const SizedBox(height: 10),
                            Text('Top Earner', style: AdminTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              _topEarner,
                              style: AdminTheme.heading3.copyWith(color: AdminTheme.amber, fontSize: 14),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '৳${_topEarning.toStringAsFixed(0)}',
                              style: AdminTheme.bodySmall.copyWith(color: AdminTheme.amber.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // Recent completed trips
                const AdminSectionHeader(
                  title: 'Recent Completed Trips',
                  icon: Icons.check_circle_outline_rounded,
                  color: AdminTheme.green,
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseService.client
                      .from('orders')
                      .stream(primaryKey: ['id'])
                      .eq('status', 'completed'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AdminTheme.accent));
                    }
                    // Sort locally to avoid composite index requirement
                    var trips = List<Map<String, dynamic>>.from(snapshot.data ?? []);
                    trips.sort((a, b) {
                      try {
                        final aTStr = a['timestamp'] ?? a['created_at'];
                        final bTStr = b['timestamp'] ?? b['created_at'];
                        if (aTStr == null) return 1;
                        if (bTStr == null) return -1;
                        final aT = DateTime.tryParse(aTStr.toString());
                        final bT = DateTime.tryParse(bTStr.toString());
                        if (aT == null) return 1;
                        if (bT == null) return -1;
                        return bT.compareTo(aT);
                      } catch (_) { return 0; }
                    });
                    if (trips.length > 15) trips = trips.sublist(0, 15);
                    if (trips.isEmpty) {
                      return GlassCard(
                        child: const Center(
                          child: Text('No completed trips yet', style: AdminTheme.body),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        var t = SupabaseService.toCamelCase(trips[index]);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AdminTheme.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: AdminTheme.green, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t['ambulanceName'] ?? t['driverName'] ?? t['companyName'] ?? 'Ambulance',
                                        style: AdminTheme.heading3.copyWith(fontSize: 13),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${t['pickupAddress'] ?? 'N/A'} → ${t['destinationAddress'] ?? 'N/A'}',
                                        style: AdminTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '৳${t['fareAmount'] ?? t['finalFare'] ?? t['confirmedFare'] ?? t['fare'] ?? 0}',
                                  style: AdminTheme.heading3.copyWith(color: AdminTheme.green),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return GlassCard(
      accentColor: iconColor,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AdminTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: AdminTheme.stat.copyWith(color: valueColor, fontSize: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
