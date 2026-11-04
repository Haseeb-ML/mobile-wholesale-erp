import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityService {
  static final SecurityService instance = SecurityService._internal();
  SecurityService._internal();

  /// Generates a random salt string
  String generateSalt() {
    final rand = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hashes a PIN with a salt using SHA-256
  String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies an entered PIN against stored hash and salt
  bool verifyPin(String enteredPin, String storedHash, String storedSalt) {
    if (storedHash.isEmpty) return true; // No PIN set yet
    final computed = hashPin(enteredPin, storedSalt);
    return computed == storedHash;
  }

  /// Permissions checks
  bool canViewCostAndProfit(String role) {
    return role == 'owner' || role == 'accountant';
  }

  bool canPerformOwnerActions(String role) {
    return role == 'owner';
  }

  bool canEditSettings(String role) {
    return role == 'owner';
  }

  bool canCancelInvoice(String role) {
    return role == 'owner';
  }

  bool canAdjustStock(String role) {
    return role == 'owner' || role == 'accountant';
  }
}

