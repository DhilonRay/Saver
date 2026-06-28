import 'dart:async';
import 'package:get/get.dart';
import '../services/supabase_service.dart';

class AdminController extends GetxController {
  // Dashboard Stats
  var activeAmbulances = 0.obs;
  var totalTripsToday = 0.obs;
  var totalUsers = 0.obs;
  var totalGLMs = 0.obs;
  var totalRevenue = 0.0.obs;
  var totalProfit = 0.0.obs;
  var revenueToday = 0.0.obs;
  var revenueMonth = 0.0.obs;
  var selectedRevenuePeriod = 'today'.obs; // 'today' or 'month'

  // Alert notifications
  var alerts = <Map<String, dynamic>>[].obs;

  // Filter
  var selectedFilter = 'week'.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _alertsSubscription;

  @override
  void onInit() {
    super.onInit();
    loadDashboardStats();
    listenForAlerts();
  }

  @override
  void onClose() {
    _alertsSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadDashboardStats() async {
    try {
      // Active ambulances
      final ambSnap = await SupabaseService.query(
        'partners',
        filters: {'is_online': true},
      );

      int activeCount = 0;
      final tenMinsAgo = DateTime.now().subtract(const Duration(minutes: 10));
      for (var item in ambSnap) {
        final data = SupabaseService.toCamelCase(item);
        final lastUpdated = data['lastUpdated'];
        if (lastUpdated != null) {
          final date = DateTime.tryParse(lastUpdated.toString());
          if (date != null && date.isAfter(tenMinsAgo)) {
            activeCount++;
          }
        }
      }
      activeAmbulances.value = activeCount;

      // Today's trips
      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      DateTime monthStart = DateTime(now.year, now.month, 1);

      final tripsSnap = await SupabaseService.client
          .from('orders')
          .select()
          .gte('timestamp', todayStart.toIso8601String());
      totalTripsToday.value = tripsSnap.length;

      // Total users
      final usersSnap = await SupabaseService.client.from('users').select();
      totalUsers.value = usersSnap.length;

      // Total GLMs
      final glmSnap = await SupabaseService.client.from('glm_accounts').select();
      totalGLMs.value = glmSnap.length;

      // Revenue
      final allTrips = await SupabaseService.query(
        'orders',
        filters: {'status': 'completed'},
      );
      
      double revToday = 0;
      double revMonth = 0;
      double revTotal = 0;
      
      for (var item in allTrips) {
        final data = SupabaseService.toCamelCase(item);
        double fare = (data['fareAmount'] ?? data['finalFare'] ?? data['confirmedFare'] ?? data['fare'] ?? 0).toDouble();
        revTotal += fare;
        
        final ts = data['timestamp'];
        if (ts != null) {
          DateTime? date = DateTime.tryParse(ts.toString());
          if (date != null) {
            if (date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart)) {
              revToday += fare;
            }
            if (date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart)) {
              revMonth += fare;
            }
          }
        }
      }
      
      revenueToday.value = revToday;
      revenueMonth.value = revMonth;
      totalRevenue.value = revTotal;
      totalProfit.value = revTotal * 0.05; // 5% commission
    } catch (e) {
      print('Error loading dashboard stats: $e');
    }
  }

  void listenForAlerts() {
    _alertsSubscription = SupabaseService.client
        .from('admin_alerts')
        .stream(primaryKey: ['id'])
        .eq('is_read', false)
        .listen((list) {
      var alertList = list
          .map((item) => SupabaseService.toCamelCase(item))
          .toList();
      // Sort locally to avoid needing a composite index
      alertList.sort((a, b) {
        final aTimeStr = a['createdAt'];
        final bTimeStr = b['createdAt'];
        if (aTimeStr == null) return 1;
        if (bTimeStr == null) return -1;
        final aTime = DateTime.tryParse(aTimeStr.toString());
        final bTime = DateTime.tryParse(bTimeStr.toString());
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      alerts.value = alertList;
    }, onError: (e) {
      print('Alerts listener error (ignored): $e');
      alerts.value = [];
    });
  }

  Future<void> markAlertRead(String alertId) async {
    await SupabaseService.client
        .from('admin_alerts')
        .update({'is_read': true})
        .eq('id', alertId);
  }

  // Finance helpers
  Future<Map<String, dynamic>> getFinanceData(String period) async {
    DateTime now = DateTime.now();
    DateTime start;
    switch (period) {
      case 'week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = now.subtract(const Duration(days: 7));
    }

    final allCompleted = await SupabaseService.query(
      'orders',
      filters: {'status': 'completed'},
    );

    double revenue = 0;
    int tripCount = 0;
    Map<String, double> ambulanceEarnings = {};

    for (var item in allCompleted) {
      final data = SupabaseService.toCamelCase(item);
      // Filter by date locally to avoid composite index requirement
      if (data['timestamp'] != null) {
        DateTime? tripDate = DateTime.tryParse(data['timestamp'].toString());
        if (tripDate != null && tripDate.isBefore(start)) continue;
      }
      double fare = (data['fareAmount'] ?? data['finalFare'] ?? data['confirmedFare'] ?? data['fare'] ?? 0).toDouble();
      revenue += fare;
      tripCount++;

      String ambName = data['ambulanceName'] ?? data['driverName'] ?? data['companyName'] ?? 'Unknown';
      ambulanceEarnings[ambName] = (ambulanceEarnings[ambName] ?? 0) + fare;
    }

    String topEarner = 'N/A';
    double topEarning = 0;
    ambulanceEarnings.forEach((name, earning) {
      if (earning > topEarning) {
        topEarning = earning;
        topEarner = name;
      }
    });

    return {
      'revenue': revenue,
      'profit': revenue * 0.05,
      'tripCount': tripCount,
      'topEarner': topEarner,
      'topEarning': topEarning,
    };
  }

  // GLM account creation
  Future<void> createGLMAccount({
    required String name,
    required String phone,
    required String hospital,
    required String glmId,
    required String password,
  }) async {
    await SupabaseService.client.from('glm_accounts').insert({
      'name': name,
      'phone': phone,
      'hospital': hospital,
      'glm_id': glmId,
      'password': password,
      'total_income': 0,
      'total_trips_ordered': 0,
      'score': 0,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
