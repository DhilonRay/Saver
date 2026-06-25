import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class AdminController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  @override
  void onInit() {
    super.onInit();
    loadDashboardStats();
    listenForAlerts();
  }

  Future<void> loadDashboardStats() async {
    try {
      // Active ambulances
      final ambList = await _supabase
          .from('partners')
          .select()
          .eq('isOnline', true);

      int activeCount = 0;
      final tenMinsAgo = DateTime.now().subtract(const Duration(minutes: 10));
      for (var data in ambList) {
        final lastUpdatedStr = data['lastUpdated'];
        if (lastUpdatedStr != null) {
          final lastUpdated = DateTime.tryParse(lastUpdatedStr.toString());
          if (lastUpdated != null && lastUpdated.isAfter(tenMinsAgo)) {
            activeCount++;
          }
        }
      }
      activeAmbulances.value = activeCount;

      // Today's trips
      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      DateTime monthStart = DateTime(now.year, now.month, 1);

      final tripsSnap = await _supabase
          .from('orders')
          .select()
          .gte('timestamp', todayStart.toIso8601String());
      totalTripsToday.value = tripsSnap.length;

      // Total users
      final usersSnap = await _supabase.from('users').select('id');
      totalUsers.value = usersSnap.length;

      // Total GLMs
      final glmSnap = await _supabase.from('glm_accounts').select('id');
      totalGLMs.value = glmSnap.length;

      // Revenue
      final allTrips = await _supabase
          .from('orders')
          .select()
          .eq('status', 'completed');
      
      double revToday = 0;
      double revMonth = 0;
      double revTotal = 0;
      
      for (var data in allTrips) {
        double fare = (data['fareAmount'] ?? data['finalFare'] ?? data['confirmedFare'] ?? data['fare'] ?? 0).toDouble();
        revTotal += fare;
        
        final tsStr = data['timestamp'];
        if (tsStr != null) {
          DateTime date = DateTime.parse(tsStr.toString());
          if (date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart)) {
            revToday += fare;
          }
          if (date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart)) {
            revMonth += fare;
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
    _supabase
        .from('admin_alerts')
        .stream(primaryKey: ['id'])
        .eq('isRead', false)
        .listen((dataList) {
      var alertList = List<Map<String, dynamic>>.from(dataList);
      // Sort locally to avoid needing a composite Firestore index
      alertList.sort((a, b) {
        final aTimeStr = a['createdAt'];
        final bTimeStr = b['createdAt'];
        DateTime? aTime = aTimeStr != null ? DateTime.tryParse(aTimeStr.toString()) : null;
        DateTime? bTime = bTimeStr != null ? DateTime.tryParse(bTimeStr.toString()) : null;
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
    await _supabase.from('admin_alerts').update({
      'isRead': true,
    }).eq('id', alertId);
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

    final allCompleted = await _supabase
        .from('orders')
        .select()
        .eq('status', 'completed');

    double revenue = 0;
    int tripCount = 0;
    Map<String, double> ambulanceEarnings = {};

    for (var data in allCompleted) {
      // Filter by date locally to avoid composite index requirement
      if (data['timestamp'] != null) {
        DateTime tripDate = DateTime.parse(data['timestamp'].toString());
        if (tripDate.isBefore(start)) continue;
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
    await _supabase.from('glm_accounts').upsert({
      'id': glmId,
      'name': name,
      'phone': phone,
      'hospital': hospital,
      'glmId': glmId,
      'password': password,
      'totalIncome': 0,
      'totalTripsOrdered': 0,
      'score': 0,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
