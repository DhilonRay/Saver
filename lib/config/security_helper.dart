import 'dart:convert';
import 'package:crypto/crypto.dart';

/// SecurityHelper — Password hashing utility
/// SHA-256 hashing করে password secure রাখে।
class SecurityHelper {
  /// একটি plain text password কে SHA-256 hash করে return করে।
  static String hashPassword(String plainText) {
    final bytes = utf8.encode(plainText.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// দুটো password compare করে — plain text vs stored hash
  static bool verifyPassword(String plainText, String storedHash) {
    return hashPassword(plainText) == storedHash;
  }
}
