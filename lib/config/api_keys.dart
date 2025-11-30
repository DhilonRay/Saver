/// API Keys Configuration
/// 
/// IMPORTANT: This file contains placeholder API keys.
/// For production, create a file named 'api_keys_secret.dart' in the same folder
/// with the actual API keys. That file is git-ignored.
/// 
/// Example api_keys_secret.dart content:
/// ```dart
/// class ApiKeysSecret {
///   static const String geminiApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
/// }
/// ```

class ApiKeys {
  // Gemini AI API Key
  // Get your free API key from: https://aistudio.google.com/app/apikey
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Empty = use local responses
  );
  
  // Google Maps API Key (already used elsewhere in the app)
  static const String googleMapsApiKey = 'AIzaSyBA3JoadngwpKChme9kg0_Z4_hWO1dXg6o';
}
