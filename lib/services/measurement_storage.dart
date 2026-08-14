import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/measurement.dart';
import '../services/firebase_service.dart';

class MeasurementStorage {
  static const String fileName = "measurements.json";

  // ==========================================
  // GET STORAGE FILE
  // ==========================================

  Future<File> _getFile() async {
    final directory =
        await getApplicationDocumentsDirectory();

    return File(
      "${directory.path}/$fileName",
    );
  }

  // ==========================================
  // SAVE MEASUREMENT
  // ==========================================

  Future<void> saveMeasurement(
    Measurement measurement,
  ) async {
    // ==========================================
    // SAVE LOCALLY
    // ==========================================

    final file = await _getFile();

    List<Measurement> measurements =
        await loadMeasurements();

    measurements.add(measurement);

    final jsonList = measurements
        .map((e) => e.toJson())
        .toList();

    await file.writeAsString(
      jsonEncode(jsonList),
    );

    debugPrint(
      "Measurement saved locally",
    );

    debugPrint(
      "Total local measurements: ${measurements.length}",
    );

    // ==========================================
    // SAVE TO FIREBASE
    // ==========================================

    try {
      debugPrint("================================");
      debugPrint("STARTING FIREBASE SAVE");
      debugPrint("User ID: ${measurement.userId}");
      debugPrint("User Name: ${measurement.userName}");
      debugPrint(
        "Heart Rate: ${measurement.heartRate}",
      );
      debugPrint(
        "HRV: ${measurement.hrvRmssd}",
      );

      final firebaseService =
          FirebaseService();

      await firebaseService.saveMeasurement(
        measurement,
      );

      debugPrint(
        "FIREBASE SAVE SUCCESSFUL",
      );

      debugPrint("================================");
    } catch (e, stackTrace) {
      debugPrint("================================");
      debugPrint("FIREBASE SAVE FAILED");
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: $stackTrace");
      debugPrint("================================");
    }
  }

  // ==========================================
  // LOAD ALL MEASUREMENTS
  // ==========================================

  Future<List<Measurement>> loadMeasurements() async {
    final file = await _getFile();

    if (!await file.exists()) {
      return [];
    }

    final contents =
        await file.readAsString();

    if (contents.isEmpty) {
      return [];
    }

    final List decoded =
        jsonDecode(contents);

    return decoded
        .map(
          (item) =>
              Measurement.fromJson(item),
        )
        .toList();
  }

  // ==========================================
  // GET MOST RECENT MEASUREMENT
  // ==========================================

  Future<Measurement?>
      getLatestMeasurement() async {
    final measurements =
        await loadMeasurements();

    if (measurements.isEmpty) {
      return null;
    }

    measurements.sort(
      (a, b) =>
          b.timestamp.compareTo(a.timestamp),
    );

    return measurements.first;
  }

  // ==========================================
  // DELETE ALL DATA
  // ==========================================

  Future<void> clearMeasurements() async {
    final file = await _getFile();

    if (await file.exists()) {
      await file.delete();

      debugPrint(
        "All measurements cleared",
      );
    }
  }

  Future<void> deleteAllMeasurements() async {
    await clearMeasurements();
  }

  // ==========================================
  // GENERAL USER STATISTICS
  // ==========================================

  Future<double>
      getAverageHeartRate() async {
    final measurements =
        await loadMeasurements();

    if (measurements.isEmpty) {
      return 0;
    }

    double total = 0;

    for (var m in measurements) {
      total += m.heartRate;
    }

    return total / measurements.length;
  }

  Future<double> getAverageHRV() async {
    final measurements =
        await loadMeasurements();

    if (measurements.isEmpty) {
      return 0;
    }

    double total = 0;

    for (var m in measurements) {
      total += m.hrvRmssd;
    }

    return total / measurements.length;
  }

  // ==========================================
  // ADMIN FUNCTIONS
  // ==========================================

  // Get all measurements from one student

  Future<List<Measurement>>
      getMeasurementsForUser(
    String userId,
  ) async {
    final measurements =
        await loadMeasurements();

    return measurements
        .where(
          (m) => m.userId == userId,
        )
        .toList();
  }

  // ==========================================
  // GET ALL STUDENT NAMES
  // ==========================================

  Future<List<String>> getStudentNames() async {
    final measurements =
        await loadMeasurements();

    final names = measurements
        .map(
          (m) => m.userName,
        )
        .where(
          (name) => name.isNotEmpty,
        )
        .toSet()
        .toList();

    return names;
  }

  // ==========================================
  // GET ALL UNIQUE STUDENT IDS
  // ==========================================

  Future<List<String>> getStudentIDs() async {
    final measurements =
        await loadMeasurements();

    final ids = measurements
        .map(
          (m) => m.userId,
        )
        .where(
          (id) => id.isNotEmpty,
        )
        .toSet()
        .toList();

    return ids;
  }

  // ==========================================
  // STUDENT AVERAGE HR
  // ==========================================

  Future<double> getUserAverageHR(
    String userId,
  ) async {
    final data =
        await getMeasurementsForUser(
      userId,
    );

    if (data.isEmpty) {
      return 0;
    }

    double total = 0;

    for (var m in data) {
      total += m.heartRate;
    }

    return total / data.length;
  }

  // ==========================================
  // STUDENT AVERAGE HRV
  // ==========================================

  Future<double> getUserAverageHRV(
    String userId,
  ) async {
    final data =
        await getMeasurementsForUser(
      userId,
    );

    if (data.isEmpty) {
      return 0;
    }

    double total = 0;

    for (var m in data) {
      total += m.hrvRmssd;
    }

    return total / data.length;
  }

  // ==========================================
  // GET STUDENT HISTORY FOR GRAPHS
  // ==========================================

  Future<List<Measurement>>
      getStudentHistory(
    String userId,
  ) async {
    final data =
        await getMeasurementsForUser(
      userId,
    );

    data.sort(
      (a, b) =>
          a.timestamp.compareTo(b.timestamp),
    );

    return data;
  }
}