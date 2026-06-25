import 'api_keys_secret.dart';

/// API Keys Configuration
/// 
/// Real values are loaded from the git-ignored 'api_keys_secret.dart' file.
class ApiKeys {
  // Gemini AI API Key
  static const String geminiApiKey = ApiKeysSecret.geminiApiKey;
  
  // Google Maps API Key
  static const String googleMapsApiKey = ApiKeysSecret.googleMapsApiKey;

  // Supabase Configuration
  static const String supabaseUrl = ApiKeysSecret.supabaseUrl;
  static const String supabaseAnonKey = ApiKeysSecret.supabaseAnonKey;
}
