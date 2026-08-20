import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/measurement.dart';
import '../models/user.dart';
import '../models/wellness_data.dart';
import '../models/bio_factor.dart';
import '../models/class_group.dart';

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
  // SAVE / UPDATE ADMIN
  // ==========================================

  Future<void> saveAdmin({
    required String adminId,
    required String adminName,
    String? email,
  }) async {
    await _firestore
        .collection('users')
        .doc(adminId)
        .set({
      'id': adminId,
      'name': adminName,
      'email': email,
      'role': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================================
  // CREATE CLASS
  // ==========================================

  Future<ClassGroup> createClass({
    required String adminId,
    required String adminName,
    required String className,
    required String classCode,
  }) async {
    final normalizedCode =
        classCode.trim().toUpperCase();

    // Prevent duplicate class codes.
    final existingClass = await getClassByCode(
      normalizedCode,
    );

    if (existingClass != null) {
      throw Exception(
        'A class with code $normalizedCode already exists.',
      );
    }

    final classRef =
        _firestore.collection('classes').doc();

    final classGroup = ClassGroup(
      id: classRef.id,
      name: className.trim(),
      classCode: normalizedCode,
      adminId: adminId,
      adminName: adminName,
    );

    await classRef.set(
      classGroup.toJson(),
    );

    return classGroup;
  }

  // ==========================================
  // FIND CLASS BY CODE
  // ==========================================

  Future<ClassGroup?> getClassByCode(
    String classCode,
  ) async {
    final normalizedCode =
        classCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection('classes')
        .where(
          'classCode',
          isEqualTo: normalizedCode,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    final data = doc.data();

    // Make sure the document ID is available
    // even if an older class document did not
    // store its own ID.
    data['id'] ??= doc.id;

    return ClassGroup.fromJson(
      data,
    );
  }

  // ==========================================
  // JOIN CLASS
  // ==========================================

  Future<void> joinClass({
    required String studentId,
    required String classCode,
  }) async {
    final normalizedCode =
        classCode.trim().toUpperCase();

    if (studentId.trim().isEmpty) {
      throw Exception(
        'Student ID is required.',
      );
    }

    if (normalizedCode.isEmpty) {
      throw Exception(
        'Class code is required.',
      );
    }

    final classGroup =
        await getClassByCode(
      normalizedCode,
    );

    if (classGroup == null) {
      throw Exception(
        'Class code not found.',
      );
    }

    // Store the student's class relationship
    // directly on the student's user document.
    await _firestore
        .collection('users')
        .doc(studentId)
        .set({
      'classId': classGroup.id,
      'classCode': classGroup.classCode,
      'className': classGroup.name,
      'adminId': classGroup.adminId,
      'adminName': classGroup.adminName,
      'updatedAt':
          FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================================
  // GET CLASS FOR STUDENT
  // ==========================================
  //
  // This is intentionally defined ONLY ONCE.
  //
  // It looks at the student's user document,
  // finds their classId, and then retrieves the
  // corresponding ClassGroup.
  //
  // ==========================================

  Future<ClassGroup?> getClassForStudent(
    String studentId,
  ) async {
    if (studentId.trim().isEmpty) {
      return null;
    }

    final studentDoc = await _firestore
        .collection('users')
        .doc(studentId)
        .get();

    if (!studentDoc.exists) {
      return null;
    }

    final studentData =
        studentDoc.data();

    if (studentData == null) {
      return null;
    }

    final classId =
        studentData['classId'];

    if (classId == null ||
        classId.toString().trim().isEmpty) {
      return null;
    }

    final classDoc = await _firestore
        .collection('classes')
        .doc(
          classId.toString(),
        )
        .get();

    if (!classDoc.exists) {
      return null;
    }

    final classData =
        classDoc.data();

    if (classData == null) {
      return null;
    }

    classData['id'] ??= classDoc.id;

    return ClassGroup.fromJson(
      classData,
    );
  }

  // ==========================================
  // GET CLASSES FOR ADMIN
  // ==========================================

  Future<List<ClassGroup>>
      getClassesForAdmin(
    String adminId,
  ) async {
    if (adminId.trim().isEmpty) {
      return [];
    }

    final snapshot =
        await _firestore
            .collection('classes')
            .where(
              'adminId',
              isEqualTo: adminId,
            )
            .get();

    return snapshot.docs.map(
      (doc) {
        final data =
            doc.data();

        data['id'] ??= doc.id;

        return ClassGroup.fromJson(
          data,
        );
      },
    ).toList();
  }

  // ==========================================
  // GET STUDENTS IN CLASS
  // ==========================================

  Future<List<User>>
      getStudentsForClass(
    String classId,
  ) async {
    if (classId.trim().isEmpty) {
      return [];
    }

    final snapshot =
        await _firestore
            .collection('users')
            .where(
              'role',
              isEqualTo: 'student',
            )
            .where(
              'classId',
              isEqualTo: classId,
            )
            .get();

    return snapshot.docs.map(
      (doc) {
        final data =
            doc.data();

        return User(
          id: data['id'] ??
              doc.id,
          name:
              data['name'] ?? '',
          role:
              data['role'] ??
                  'student',
          studentId:
              data['studentId'],
          email:
              data['email'],
        );
      },
    ).toList();
  }

  // ==========================================
  // GET STUDENTS FOR ADMIN
  // ==========================================
  //
  // Convenience method:
  // Gets every class belonging to this admin,
  // then gets the students belonging to those
  // classes.
  //
  // This is useful for the Admin Dashboard.
  //
  // ==========================================

  Future<List<User>>
      getStudentsForAdmin(
    String adminId,
  ) async {
    final classes =
        await getClassesForAdmin(
      adminId,
    );

    if (classes.isEmpty) {
      return [];
    }

    final classIds =
        classes.map(
          (classGroup) =>
              classGroup.id,
        ).toSet();

    final snapshot =
        await _firestore
            .collection('users')
            .where(
              'role',
              isEqualTo: 'student',
            )
            .get();

    return snapshot.docs
        .where(
          (doc) {
            final data =
                doc.data();

            final classId =
                data['classId'];

            return classId != null &&
                classIds.contains(
                  classId.toString(),
                );
          },
        )
        .map(
          (doc) {
            final data =
                doc.data();

            return User(
              id:
                  data['id'] ??
                      doc.id,
              name:
                  data['name'] ?? '',
              role:
                  data['role'] ??
                      'student',
              studentId:
                  data['studentId'],
              email:
                  data['email'],
            );
          },
        )
        .toList();
  }

  // ==========================================
  // SAVE MEASUREMENT
  // ==========================================

  Future<void> saveMeasurement(
    Measurement measurement,
  ) async {
    // Make sure the student's user document
    // exists before saving the measurement.
    await _firestore
        .collection('users')
        .doc(measurement.userId)
        .set({
      'id':
          measurement.userId,
      'name':
          measurement.userName,
      'role':
          'student',
      'updatedAt':
          FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Save the measurement under the student's
    // own document.
    await _firestore
        .collection('users')
        .doc(measurement.userId)
        .collection('measurements')
        .doc(measurement.id)
        .set({
      'id':
          measurement.id,

      'userId':
          measurement.userId,

      'userName':
          measurement.userName,

      'timestamp':
          Timestamp.fromDate(
        measurement.timestamp,
      ),

      'heartRate':
          measurement.heartRate,

      'hrvRmssd':
          measurement.hrvRmssd,

      'hrvSdnn':
          measurement.hrvSdnn,

      'hrvPnn50':
          measurement.hrvPnn50,

      'hrvSd1':
          measurement.hrvSd1,

      'hrvSd2':
          measurement.hrvSd2,

      'lfPower':
          measurement.lfPower,

      'hfPower':
          measurement.hfPower,

      'lfHfRatio':
          measurement.lfhfRatio,

      'rrIntervals':
          measurement.rrIntervals,

      'bpmHistory':
          measurement.bpmHistory,

      'qualityScore':
          measurement.qualityScore,

      'valid':
          measurement.valid,

      'durationSeconds':
          measurement.durationSeconds,

      'notes':
          measurement.notes,

      'wellness':
          measurement.wellness
              ?.toJson(),

      'bioFactors':
          measurement.bioFactors
              .map(
                (factor) =>
                    factor.toJson(),
              )
              .toList(),
    });
  }

  // ==========================================
  // GET ALL STUDENTS
  // ==========================================

  Future<List<User>>
      getStudents() async {
    final snapshot =
        await _firestore
            .collection('users')
            .where(
              'role',
              isEqualTo: 'student',
            )
            .get();

    return snapshot.docs.map(
      (doc) {
        final data =
            doc.data();

        return User(
          id:
              data['id'] ??
                  doc.id,
          name:
              data['name'] ?? '',
          role:
              data['role'] ??
                  'student',
          studentId:
              data['studentId'],
          email:
              data['email'],
        );
      },
    ).toList();
  }

  // ==========================================
  // GET STUDENT MEASUREMENTS
  // ==========================================

  Future<List<Measurement>>
      getMeasurementsForUser(
    String userId,
  ) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('measurements')
            .orderBy('timestamp')
            .get();

    return snapshot.docs.map(
      (doc) {
        final data =
            doc.data();

        return Measurement(
          id:
              data['id'] ??
                  doc.id,

          userId:
              data['userId'] ??
                  userId,

          userName:
              data['userName'] ??
                  '',

          timestamp:
              (data['timestamp']
                      as Timestamp)
                  .toDate(),

          heartRate:
              (data['heartRate'] ??
                      0)
                  .toDouble(),

          hrvRmssd:
              (data['hrvRmssd'] ??
                      0)
                  .toDouble(),

          hrvSdnn:
              data['hrvSdnn']
                  ?.toDouble(),

          hrvPnn50:
              data['hrvPnn50']
                  ?.toDouble(),

          hrvSd1:
              data['hrvSd1']
                  ?.toDouble(),

          hrvSd2:
              data['hrvSd2']
                  ?.toDouble(),

          lfPower:
              data['lfPower']
                  ?.toDouble(),

          hfPower:
              data['hfPower']
                  ?.toDouble(),

          lfhfRatio:
              data['lfHfRatio']
                  ?.toDouble(),

          rrIntervals:
              List<double>.from(
            data['rrIntervals'] ??
                [],
          ),

          bpmHistory:
              List<double>.from(
            data['bpmHistory'] ??
                [],
          ),

          qualityScore:
              (data['qualityScore'] ??
                      0)
                  .toDouble(),

          valid:
              data['valid'] ??
                  true,

          durationSeconds:
              data['durationSeconds'] ??
                  45,

          notes:
              data['notes'],

          wellness:
              data['wellness'] !=
                      null
                  ? WellnessData
                      .fromJson(
                      Map<String,
                              dynamic>.from(
                        data[
                            'wellness'],
                      ),
                    )
                  : null,

          bioFactors:
              (data['bioFactors']
                          as List?)
                      ?.map(
                        (item) =>
                            BioFactor
                                .fromJson(
                          Map<String,
                                  dynamic>.from(
                            item,
                          ),
                        ),
                      )
                      .toList() ??
                  const [],
        );
      },
    ).toList();
  }
}