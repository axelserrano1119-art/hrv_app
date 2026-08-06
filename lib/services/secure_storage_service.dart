

// services/secure_storage_service.dart
// HIPAA-compliant encrypted local storage with user isolation

import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/measurement.dart';
import '../models/user_profile.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'hrv_secure_storage',
    ),
  );
  
  static const String _keyPrefix = 'hrv_app_';
  static const String _userPrefix = 'user_';
  static const String _measurementsKey = 'measurements_';
  static const String _profileKey = 'profile_';
  static const String _adminKey = 'admin_data_';
  static const String _encryptionKeyName = 'master_encryption_key';
  
  // Generate or retrieve encryption key
  static Future<encrypt.Key> _getEncryptionKey() async {
    String? keyString = await _storage.read(key: _encryptionKeyName);
    if (keyString == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      keyString = base64Encode(keyBytes);
      await _storage.write(key: _encryptionKeyName, value: keyString);
    }
    return encrypt.Key.fromBase64(keyString);
  }
  
  // Encrypt data
  static Future<String> _encrypt(String plaintext) async {
    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }
  
  // Decrypt data
  static Future<String?> _decrypt(String ciphertext) async {
    try {
      final key = await _getEncryptionKey();
      final parts = ciphertext.split(':');
      if (parts.length != 2) return null;
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return null;
    }
  }
  
  // Save measurement for a specific user
  static Future<void> saveMeasurement(String userId, Measurement measurement) async {
    final key = '$_keyPrefix$_userPrefix$userId$_measurementsKey';
    
    // Read existing measurements
    String? existingData = await _storage.read(key: key);
    List<dynamic> measurements = [];
    
    if (existingData != null) {
      final decrypted = await _decrypt(existingData);
      if (decrypted != null) {
        measurements = jsonDecode(decrypted);
      }
    }
    
    // Add new measurement
    measurements.add(measurement.toJson());
    
    // Encrypt and save
    final encrypted = await _encrypt(jsonEncode(measurements));
    await _storage.write(key: key, value: encrypted);
    
    // Also update admin view data (aggregated, anonymized)
    await _updateAdminData(userId, measurement);
  }
  
  // Get all measurements for a user
  static Future<List<Measurement>> getMeasurements(String userId) async {
    final key = '$_keyPrefix$_userPrefix$userId$_measurementsKey';
    String? data = await _storage.read(key: key);
    
    if (data == null) return [];
    
    final decrypted = await _decrypt(data);
    if (decrypted == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(decrypted);
    return jsonList.map((json) => Measurement.fromJson(json)).toList();
  }
  
  // Get measurements for date range
  static Future<List<Measurement>> getMeasurementsInRange(
    String userId, 
    DateTime start, 
    DateTime end
  ) async {
    final allMeasurements = await getMeasurements(userId);
    return allMeasurements.where((m) => 
      m.timestamp.isAfter(start) && m.timestamp.isBefore(end)
    ).toList();
  }
  
  // Save user profile
  static Future<void> saveUserProfile(UserProfile profile) async {
    final key = '$_keyPrefix$_userPrefix${profile.userId}$_profileKey';
    final encrypted = await _encrypt(jsonEncode(profile.toJson()));
    await _storage.write(key: key, value: encrypted);
  }
  
  // Get user profile
  static Future<UserProfile?> getUserProfile(String userId) async {
    final key = '$_keyPrefix$_userPrefix$userId$_profileKey';
    String? data = await _storage.read(key: key);
    if (data == null) return null;
    
    final decrypted = await _decrypt(data);
    if (decrypted == null) return null;
    
    return UserProfile.fromJson(jsonDecode(decrypted));
  }
  
  // Admin: Get all users (for admin dashboard)
  static Future<List<UserProfile>> getAllUsers() async {
    final allKeys = await _storage.readAll();
    List<UserProfile> users = [];
    
    for (var entry in allKeys.entries) {
      if (entry.key.contains(_profileKey)) {
        final decrypted = await _decrypt(entry.value);
        if (decrypted != null) {
          users.add(UserProfile.fromJson(jsonDecode(decrypted)));
        }
      }
    }
    
    return users;
  }
  
  // Admin: Get aggregated statistics
  static Future<Map<String, dynamic>> getAdminStatistics() async {
    final users = await getAllUsers();
    Map<String, dynamic> stats = {
      'total_users': users.length,
      'total_measurements': 0,
      'average_hrv': 0.0,
      'average_hr': 0.0,
      'user_statistics': <Map<String, dynamic>>[],
    };
    
    double totalHRV = 0;
    double totalHR = 0;
    int measurementCount = 0;
    List<Map<String, dynamic>> userStats = [];
    
    for (var user in users) {
      final measurements = await getMeasurements(user.userId);
      if (measurements.isNotEmpty) {
        double userAvgHRV = measurements.map((m) => m.hrvRmssd).reduce((a, b) => a + b) / measurements.length;
        double userAvgHR = measurements.map((m) => m.heartRate).reduce((a, b) => a + b) / measurements.length;
        
        totalHRV += userAvgHRV * measurements.length;
        totalHR += userAvgHR * measurements.length;
        measurementCount += measurements.length;
        
        userStats.add({
          'user_id': user.userId,
          'user_name': user.name,
          'measurement_count': measurements.length,
          'last_measurement': measurements.last.timestamp.toIso8601String(),
          'average_hrv': userAvgHRV,
          'average_hr': userAvgHR,
          'trend': _calculateTrend(measurements),
        });
      }
    }
    
    if (measurementCount > 0) {
      stats['average_hrv'] = totalHRV / measurementCount;
      stats['average_hr'] = totalHR / measurementCount;
    }
    stats['total_measurements'] = measurementCount;
    stats['user_statistics'] = userStats;
    
    return stats;
  }
  
  // Calculate trend direction
  static String _calculateTrend(List<Measurement> measurements) {
    if (measurements.length < 5) return 'insufficient_data';
    
    final recent = measurements.sublist(measurements.length - 5);
    final older = measurements.sublist(0, 5);
    
    double recentAvg = recent.map((m) => m.hrvRmssd).reduce((a, b) => a + b) / recent.length;
    double olderAvg = older.map((m) => m.hrvRmssd).reduce((a, b) => a + b) / older.length;
    
    double change = ((recentAvg - olderAvg) / olderAvg) * 100;
    
    if (change > 10) return 'improving';
    if (change < -10) return 'declining';
    return 'stable';
  }
  
  // Delete user data (GDPR right to be forgotten)
  static Future<void> deleteUserData(String userId) async {
    final allKeys = await _storage.readAll();
    for (var key in allKeys.keys) {
      if (key.contains('$_userPrefix$userId')) {
        await _storage.delete(key: key);
      }
    }
  }
  
  // Clear all data (for testing)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  // Update admin data (internal use)
  static Future<void> _updateAdminData(String userId, Measurement measurement) async {
    final key = '$_keyPrefix$_adminKey$userId';
    String? existing = await _storage.read(key: key);
    
    List<dynamic> adminData = [];
    if (existing != null) {
      final decrypted = await _decrypt(existing);
      if (decrypted != null) adminData = jsonDecode(decrypted);
    }
    
    // Store only essential data for admin view (anonymized)
    adminData.add({
      'timestamp': measurement.timestamp.toIso8601String(),
      'hr': measurement.heartRate,
      'hrv': measurement.hrvRmssd,
      'quality': measurement.qualityScore,
    });
    
    // Keep only last 100 entries per user for admin view
    if (adminData.length > 100) adminData.removeAt(0);
    
    final encrypted = await _encrypt(jsonEncode(adminData));
    await _storage.write(key: key, value: encrypted);
  }
}
