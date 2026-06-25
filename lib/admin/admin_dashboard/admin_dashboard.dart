import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin_controller.dart';
import '../admin_theme.dart';
import '../pages/home_page.dart';
import '../pages/ambulances_page.dart';
import '../pages/finance_page.dart';
import '../pages/users_page.dart';
import '../pages/glm_page.dart';
import '../pages/reviews_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/log_in/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  late final AdminController _controller;

  final List<Widget> _pages = [
    const AdminHomePage(),
    const AmbulancesPage(),
    const FinancePage(),
    const UsersPage(),
    const GLMPage(),
    const ReviewsPage(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_rounded, Icons.dashboard_rounded, 'Home'),
    _NavItem(Icons.local_hospital_outlined, Icons.local_hospital_rounded,
        'Ambulances'),
    _NavItem(Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet_rounded, 'Finance'),
    _NavItem(Icons.people_outline_rounded, Icons.people_rounded, 'Users'),
    _NavItem(
        Icons.business_center_outlined, Icons.business_center_rounded, 'GLM'),
    _NavItem(Icons.star_outline_rounded, Icons.star_rounded, 'Reviews'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(AdminController());
  }

  Future<void> _logout() async {
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AdminTheme.bgCard,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminTheme.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AdminTheme.red, size: 28),
                ),
                const SizedBox(height: 16),
                const Text('Log Out', style: AdminTheme.heading2),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to logout from the admin panel?',
                  style:
                      AdminTheme.body.copyWith(color: AdminTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(color: AdminTheme.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isAdminLoggedIn', false);
                          await Supabase.instance.client.auth.signOut();
                          Get.offAll(() => const LoginPage());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Log Out',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgDeep,
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AdminTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AdminTheme.accent, Color(0xFF80DEEA)],
              ).createShader(bounds),
              child: const Icon(Icons.local_hospital_rounded,
                  size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _getTitle(),
            style: AdminTheme.heading2,
          ),
        ],
      ),
      backgroundColor: AdminTheme.bgDeep,
      elevation: 0,
      iconTheme: const IconThemeData(color: AdminTheme.textPrimary),
      actions: [
        // Alert bell
        Obx(() {
          int alertCount = _controller.alerts.length;
          return GestureDetector(
            onTap: () => _showAlerts(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alertCount > 0
                    ? AdminTheme.red.withOpacity(0.1)
                    : AdminTheme.bgSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: alertCount > 0
                        ? AdminTheme.red
                        : AdminTheme.textSecondary,
                    size: 22,
                  ),
                  if (alertCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AdminTheme.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AdminTheme.red.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _controller.loadDashboardStats(),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminTheme.bgSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: AdminTheme.textSecondary, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _logout,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminTheme.bgSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.logout_rounded,
                color: AdminTheme.textSecondary, size: 22),
          ),
        ),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.bgDeep,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.04))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 18 : 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AdminTheme.accent.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? AdminTheme.accent
                            : AdminTheme.textMuted,
                        size: isSelected ? 24 : 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: AdminTheme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Ambulances';
      case 2:
        return 'Finance';
      case 3:
        return 'Users';
      case 4:
        return 'GLM Info';
      case 5:
        return 'Reviews';
      default:
        return 'Admin';
    }
  }

  void _showAlerts() {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(Get.context!).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: AdminTheme.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminTheme.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AdminTheme.amber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Active Alerts', style: AdminTheme.heading2),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.04), height: 1),
            Obx(() {
              if (_controller.alerts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AdminTheme.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded,
                            color: AdminTheme.green, size: 36),
                      ),
                      const SizedBox(height: 14),
                      const Text('All systems normal', style: AdminTheme.body),
                    ],
                  ),
                );
              }
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _controller.alerts.length,
                  itemBuilder: (context, index) {
                    var alert = _controller.alerts[index];
                    bool isRedAlert = alert['type'] == 'ambulance_inactive';
                    final color =
                        isRedAlert ? AdminTheme.red : AdminTheme.orange;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.12)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isRedAlert
                                ? Icons.error_outline_rounded
                                : Icons.warning_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          alert['title'] ?? 'Alert',
                          style: AdminTheme.heading3
                              .copyWith(color: color, fontSize: 14),
                        ),
                        subtitle: Text(
                          alert['message'] ?? '',
                          style: AdminTheme.bodySmall,
                        ),
                        trailing: GestureDetector(
                          onTap: () => _controller.markAlertRead(alert['id']),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AdminTheme.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: AdminTheme.green, size: 18),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
