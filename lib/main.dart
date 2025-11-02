import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saver/splash_page/splash_page.dart';
import 'package:saver/accept_maps/accept_maps.dart';
import 'package:saver/services/notification_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

 
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  //06d22db9f1e31db564c7cd0ba23662f000b8f0a8

  // Initialize comprehensive FCM setup
  await NotificationService.setupFCMOnAppStart();

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 BACKGROUND MESSAGE RECEIVED: ${message.messageId}');
  print('📩 Message data: ${message.data}');
  print('📩 Message notification: ${message.notification?.title} - ${message.notification?.body}');

  // Initialize local notifications if needed
  await NotificationService.initializeLocalNotificationsForBackground();

  // Show local notification for background messages
  await NotificationService.showBackgroundNotification(message);
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
      home:  SplashPage(),
      getPages: [
        GetPage(name: '/accept-maps', page: () => AcceptMapsPage()),
      ],
    );
  }
}