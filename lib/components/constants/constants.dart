import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

class AppConstants {
  static const bool isOtpTesting = false;
  static const bool local = false;
  static const bool production = true;
  static const String apiUrl = production
      ? 'https://backend.shopstick.store'
      : local
      ? 'http://192.168.0.140:4700'
      : 'https://backend.live.url';
  static final pdfMediaType = MediaType('application', 'pdf');
  static final jpegImageMediaType = MediaType('image', 'jpeg');
  static final jpgImageMediaType = MediaType('image', 'jpg');
  static final pngImageMediaType = MediaType('image', 'png');
  static const String notificationChannelID = 'shopstickpos';
  static const String notificationChannelName = 'Shopstick POS';
  static const String notificationChannelDescription =
      'Shopstick notification channel';
  static const String notificationChannelTicker = 'shopstickposticker';
  static const banglaLocale = Locale('bn', 'BD');
  static const englishLocale = Locale('en', 'US');
  static final apiDateTimeFormat = DateFormat(
    'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',
  );
  static final apiDateTimeFormat2 = DateFormat('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
  static const int unsetDateTimeYear = 1800;
  static final DateTime unsetDateTime = DateTime(unsetDateTimeYear);
  static const String currencySymbol = '৳';

  static const List<String> shopTypesRequiringUniqueSerial = [
    // Add more shop types here if needed
    'Electronics & Gadgets',
  ];
}
