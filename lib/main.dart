import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saver/config/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/splash_page/splash_page.dart';
import 'package:saver/partner_file/accept_maps/accept_maps.dart';
import 'package:saver/services/notification_service.dart';
import 'package:saver/privacy_policy/privacy_policy.dart';
import 'package:saver/terms_condition/terms_condition.dart';
import 'package:saver/feedback/feedback.dart';
import 'package:saver/partner_file/partner_profile/partner_profile.dart';
import 'package:saver/admin/admin_login/admin_login_screen.dart';
import 'package:saver/admin/admin_dashboard/admin_dashboard.dart';
import 'package:saver/admin/admin_setup_screen.dart';
import 'package:saver/admin/easy_admin_creator.dart';
import 'package:saver/fare_negotiation/fare_negotiation_page.dart';
import 'package:saver/user_tracking/user_tracking_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  // TODO: Replace Firebase Messaging with Supabase Edge Functions / OneSignal if needed
  // await NotificationService.setupFCMOnAppStart();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NeoSaver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: SplashPage(),
      getPages: [
        GetPage(name: '/accept-maps', page: () => AcceptMapsPage()),
        GetPage(name: '/admin-login', page: () => const AdminLoginScreen()),
        GetPage(name: '/admin-dashboard', page: () => const AdminDashboard()),
        GetPage(name: '/admin-setup', page: () => const AdminSetupScreen()),
        GetPage(name: '/create-admin', page: () => const EasyAdminCreator()),
        GetPage(name: '/feedback', page: () => const FeedbackPage()),
        GetPage(
            name: '/partner-profile', page: () => const PartnerProfilePage()),
        GetPage(name: '/privacy-policy', page: () => const PrivacyPolicyPage()),
        GetPage(
            name: '/terms-conditions', page: () => const TermsConditionPage()),
        GetPage(name: '/fare-negotiation', page: () => FareNegotiationPage()),
        GetPage(name: '/user-tracking', page: () => const UserTrackingPage()),
      ],
    );
  }
}
