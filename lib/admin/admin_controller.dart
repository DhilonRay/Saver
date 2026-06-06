import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      QuerySnapshot ambSnap = await _firestore
          .collection('partners')
          .where('isOnline', isEqualTo: true)
          .get();

      int activeCount = 0;
      final tenMinsAgo = DateTime.now().subtract(const Duration(minutes: 10));
      for (var doc in ambSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastUpdated = data['lastUpdated'] as Timestamp?;
        if (lastUpdated != null && lastUpdated.toDate().isAfter(tenMinsAgo)) {
          activeCount++;
        }
      }
      activeAmbulances.value = activeCount;

      // Today's trips
      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      DateTime monthStart = DateTime(now.year, now.month, 1);

      QuerySnapshot tripsSnap = await _firestore
          .collection('orders')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();
      totalTripsToday.value = tripsSnap.size;

      // Total users
      QuerySnapshot usersSnap = await _firestore.collection('users').get();
      totalUsers.value = usersSnap.size;

      // Total GLMs
      QuerySnapshot glmSnap = await _firestore.collection('glm_accounts').get();
      totalGLMs.value = glmSnap.size;

      // Revenue
      QuerySnapshot allTrips = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'completed')
          .get();
      
      double revToday = 0;
      double revMonth = 0;
      double revTotal = 0;
      
      for (var doc in allTrips.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double fare = (data['fareAmount'] ?? data['finalFare'] ?? data['confirmedFare'] ?? data['fare'] ?? 0).toDouble();
        revTotal += fare;
        
        Timestamp? ts = data['timestamp'] as Timestamp?;
        if (ts != null) {
          DateTime date = ts.toDate();
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
    _firestore
        .collection('admin_alerts')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      var alertList = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      // Sort locally to avoid needing a composite Firestore index
      alertList.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
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
    await _firestore.collection('admin_alerts').doc(alertId).update({
      'isRead': true,
    });
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

    QuerySnapshot allCompleted = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .get();

    double revenue = 0;
    int tripCount = 0;
    Map<String, double> ambulanceEarnings = {};

    for (var doc in allCompleted.docs) {
      var data = doc.data() as Map<String, dynamic>;
      // Filter by date locally to avoid composite index requirement
      if (data['timestamp'] != null) {
        DateTime tripDate = (data['timestamp'] as Timestamp).toDate();
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
    await _firestore.collection('glm_accounts').doc(glmId).set({
      'name': name,
      'phone': phone,
      'hospital': hospital,
      'glmId': glmId,
      'password': password,
      'totalIncome': 0,
      'totalTripsOrdered': 0,
      'score': 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
