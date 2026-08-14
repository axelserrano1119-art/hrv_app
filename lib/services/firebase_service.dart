import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/measurement.dart';
import '../models/user.dart';

class FirebaseService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================
  // SAVE / UPDATE STUDENT
  // ==========================================

  Future<void> saveStudent(User user) async {
    if (!user.isStudent) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.id)
        .set({
      'id': user.id,
      'name': user.name,
      'studentId': user.studentId,
      'email': user.email,
      'role': 'student',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================================
  // SAVE MEASUREMENT
  // ==========================================

  Future<void> saveMeasurement(
      Measurement measurement) async {

    // Make sure the student exists.
    await _firestore
        .collection('users')
        .doc(measurement.userId)
        .set({
      'id': measurement.userId,
      'name': measurement.userName,
      'role': 'student',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Save measurement under the student.
    await _firestore
        .collection('users')
        .doc(measurement.userId)
        .collection('measurements')
        .doc(measurement.id)
        .set({
      'id': measurement.id,
      'userId': measurement.userId,
      'userName': measurement.userName,
      'timestamp': Timestamp.fromDate(
        measurement.timestamp,
      ),
      'heartRate': measurement.heartRate,
      'hrvRmssd': measurement.hrvRmssd,
      'hrvSdnn': measurement.hrvSdnn,
      'hrvPnn50': measurement.hrvPnn50,
      'hrvSd1': measurement.hrvSd1,
      'hrvSd2': measurement.hrvSd2,
      'lfPower': measurement.lfPower,
      'hfPower': measurement.hfPower,
      'lfHfRatio': measurement.lfhfRatio,
      'rrIntervals': measurement.rrIntervals,
      'bpmHistory': measurement.bpmHistory,
      'qualityScore': measurement.qualityScore,
      'valid': measurement.valid,
      'durationSeconds': measurement.durationSeconds,
      'notes': measurement.notes,
    });
  }

  // ==========================================
  // GET ALL STUDENTS
  // ==========================================

  Future<List<User>> getStudents() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return User(
        id: data['id'] ?? doc.id,
        name: data['name'] ?? '',
        role: data['role'] ?? 'student',
        studentId: data['studentId'],
        email: data['email'],
      );
    }).toList();
  }

  // ==========================================
  // GET STUDENT MEASUREMENTS
  // ==========================================

  Future<List<Measurement>> getMeasurementsForUser(
      String userId) async {

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .orderBy('timestamp')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Measurement(
        id: data['id'] ?? doc.id,
        userId: data['userId'] ?? userId,
        userName: data['userName'] ?? '',
        timestamp:
            (data['timestamp'] as Timestamp).toDate(),
        heartRate:
            (data['heartRate'] ?? 0).toDouble(),
        hrvRmssd:
            (data['hrvRmssd'] ?? 0).toDouble(),
        hrvSdnn:
            data['hrvSdnn']?.toDouble(),
        hrvPnn50:
            data['hrvPnn50']?.toDouble(),
        hrvSd1:
            data['hrvSd1']?.toDouble(),
        hrvSd2:
            data['hrvSd2']?.toDouble(),
        lfPower:
            data['lfPower']?.toDouble(),
        hfPower:
            data['hfPower']?.toDouble(),
        lfhfRatio:
            data['lfHfRatio']?.toDouble(),
        rrIntervals:
            List<double>.from(
          data['rrIntervals'] ?? [],
        ),
        bpmHistory:
            List<double>.from(
          data['bpmHistory'] ?? [],
        ),
        qualityScore:
            (data['qualityScore'] ?? 0).toDouble(),
        valid:
            data['valid'] ?? true,
        durationSeconds:
            data['durationSeconds'] ?? 45,
        notes:
            data['notes'],
      );
    }).toList();
  }
}