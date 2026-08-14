// screens/admin_dashboard_screen.dart
// Administrator view for student HR/HRV, wellness,
// bio-factors, athlete flagging, and sustained alerts.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';

import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/measurement.dart';
import '../instructions_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {

  final FirebaseService _firebaseService =
      FirebaseService();

  List<User> _students = [];

  User? _selectedStudent;

  List<Measurement> _selectedMeasurements = [];

  bool _isLoadingStudents = true;
  bool _isLoadingMeasurements = false;

  int _selectedTimeRange = 7;

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  // ============================================================
  // LOAD STUDENTS
  // ============================================================

  Future<void> _loadStudents() async {
    if (mounted) {
      setState(() {
        _isLoadingStudents = true;
      });
    }

    try {
      final students =
          await _firebaseService.getStudents();

      if (!mounted) return;

      setState(() {
        _students = students;
        _isLoadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingStudents = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load students: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SELECT STUDENT
  // ============================================================

  Future<void> _selectStudent(User student) async {
    setState(() {
      _selectedStudent = student;
      _isLoadingMeasurements = true;
      _selectedMeasurements = [];
    });

    try {
      final measurements =
          await _firebaseService
              .getMeasurementsForUser(student.id);

      if (!mounted) return;

      final now = DateTime.now();

      final startDate = now.subtract(
        Duration(days: _selectedTimeRange),
      );

      final filteredMeasurements =
          measurements.where((measurement) {
        return measurement.timestamp
                .isAfter(startDate) &&
            measurement.timestamp.isBefore(now);
      }).toList();

      filteredMeasurements.sort(
        (a, b) =>
            a.timestamp.compareTo(b.timestamp),
      );

      setState(() {
        _selectedMeasurements =
            filteredMeasurements;

        _isLoadingMeasurements = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMeasurements = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load measurements: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // TIME RANGE
  // ============================================================

  void _changeTimeRange(int days) {
    setState(() {
      _selectedTimeRange = days;
    });

    if (_selectedStudent != null) {
      _selectStudent(_selectedStudent!);
    }
  }

  // ============================================================
  // ATHLETE STATUS
  // ============================================================

  String _getAthleteStatus(
    List<Measurement> measurements,
  ) {
    if (measurements.isEmpty) {
      return 'normal';
    }

    final recent = measurements.length <= 3
        ? measurements
        : measurements.sublist(
            measurements.length - 3,
          );

    int concernCount = 0;
    int severeCount = 0;

    for (final measurement in recent) {
      final wellness =
          measurement.wellness;

      // ------------------------------------------
      // WELLNESS CONCERNS
      // ------------------------------------------

      if (wellness != null) {
        if (wellness.fatigue >= 4) {
          concernCount++;
        }

        if (wellness.soreness >= 4) {
          concernCount++;
        }

        if (wellness.stress >= 4) {
          concernCount++;
        }

        if (wellness.sleep <= 2) {
          concernCount++;
        }

        if (wellness.overall <= 2) {
          concernCount++;
        }

        if (wellness.fatigue >= 5 ||
            wellness.soreness >= 5 ||
            wellness.overall <= 1) {
          severeCount++;
        }
      }

      // ------------------------------------------
      // BIO-FACTORS
      // ------------------------------------------

      for (final factor
          in measurement.bioFactors) {
        if (factor.severity >= 3) {
          concernCount++;
        }

        if (factor.severity >= 4) {
          severeCount++;
        }
      }

      // ------------------------------------------
      // HR / HRV BASIC SANITY FLAGS
      // ------------------------------------------

      if (measurement.heartRate > 100 ||
          measurement.heartRate < 45) {
        concernCount++;
      }

      if (measurement.hrvRmssd > 0 &&
          measurement.hrvRmssd < 20) {
        concernCount++;
      }
    }

    // Sustained alert:
    // repeated concern across recent measurements.
    if (recent.length >= 3) {
      int measurementsWithConcern = 0;

      for (final measurement in recent) {
        bool concern = false;

        final wellness =
            measurement.wellness;

        if (wellness != null) {
          if (wellness.fatigue >= 4 ||
              wellness.soreness >= 4 ||
              wellness.stress >= 4 ||
              wellness.sleep <= 2 ||
              wellness.overall <= 2) {
            concern = true;
          }
        }

        for (final factor
            in measurement.bioFactors) {
          if (factor.severity >= 3) {
            concern = true;
          }
        }

        if (measurement.heartRate > 100 ||
            measurement.heartRate < 45) {
          concern = true;
        }

        if (measurement.hrvRmssd > 0 &&
            measurement.hrvRmssd < 20) {
          concern = true;
        }

        if (concern) {
          measurementsWithConcern++;
        }
      }

      if (measurementsWithConcern >= 2 &&
          (severeCount >= 2 ||
              concernCount >= 4)) {
        return 'alert';
      }
    }

    if (concernCount >= 2 ||
        severeCount >= 1) {
      return 'monitor';
    }

    return 'normal';
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'alert':
        return Colors.redAccent;

      case 'monitor':
        return Colors.orangeAccent;

      default:
        return Colors.greenAccent;
    }
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _statusLabel(String status) {
    switch (status) {
      case 'alert':
        return 'Sustained Alert';

      case 'monitor':
        return 'Monitor';

      default:
        return 'Normal';
    }
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _statusIcon(String status) {
    switch (status) {
      case 'alert':
        return Icons.warning_rounded;

      case 'monitor':
        return Icons.visibility;

      default:
        return Icons.check_circle;
    }
  }

  // ============================================================
  // GET ALERT REASONS
  // ============================================================

  List<String> _getAlertReasons(
    List<Measurement> measurements,
  ) {
    if (measurements.isEmpty) {
      return [];
    }

    final recent = measurements.length <= 3
        ? measurements
        : measurements.sublist(
            measurements.length - 3,
          );

    final List<String> reasons = [];

    // ------------------------------------------
    // WELLNESS
    // ------------------------------------------

    int highFatigue = 0;
    int highStress = 0;
    int highSoreness = 0;
    int poorSleep = 0;
    int poorOverall = 0;

    // ------------------------------------------
    // BIO FACTORS
    // ------------------------------------------

    final Map<String, int> bodyPartCounts = {};

    for (final measurement in recent) {
      final wellness =
          measurement.wellness;

      if (wellness != null) {
        if (wellness.fatigue >= 4) {
          highFatigue++;
        }

        if (wellness.stress >= 4) {
          highStress++;
        }

        if (wellness.soreness >= 4) {
          highSoreness++;
        }

        if (wellness.sleep <= 2) {
          poorSleep++;
        }

        if (wellness.overall <= 2) {
          poorOverall++;
        }
      }

      for (final factor
          in measurement.bioFactors) {
        if (factor.severity >= 3) {
          bodyPartCounts[factor.bodyPart] =
              (bodyPartCounts[factor.bodyPart] ??
                      0) +
                  1;
        }
      }
    }

    if (highFatigue >= 2) {
      reasons.add(
        'Fatigue has remained elevated across multiple measurements.',
      );
    } else if (highFatigue == 1) {
      reasons.add(
        'Elevated fatigue was reported.',
      );
    }

    if (highStress >= 2) {
      reasons.add(
        'Stress has remained elevated across multiple measurements.',
      );
    } else if (highStress == 1) {
      reasons.add(
        'Elevated stress was reported.',
      );
    }

    if (highSoreness >= 2) {
      reasons.add(
        'Muscle soreness has remained elevated.',
      );
    } else if (highSoreness == 1) {
      reasons.add(
        'Elevated soreness was reported.',
      );
    }

    if (poorSleep >= 2) {
      reasons.add(
        'Poor sleep has been reported repeatedly.',
      );
    } else if (poorSleep == 1) {
      reasons.add(
        'Poor sleep was reported.',
      );
    }

    if (poorOverall >= 2) {
      reasons.add(
        'Overall wellness has remained low.',
      );
    } else if (poorOverall == 1) {
      reasons.add(
        'Low overall wellness was reported.',
      );
    }

    bodyPartCounts.forEach(
      (bodyPart, count) {
        if (count >= 2) {
          reasons.add(
            '$bodyPart has been reported as a recurring physical concern.',
          );
        }
      },
    );

    // ------------------------------------------
    // CURRENT BIO FACTORS
    // ------------------------------------------

    final latest = recent.last;

    for (final factor
        in latest.bioFactors) {
      if (factor.severity >= 4) {
        reasons.add(
          '${factor.bodyPart}: ${factor.issue}, severity ${factor.severity}/5.',
        );
      }
    }

    // ------------------------------------------
    // HR
    // ------------------------------------------

    final highHRCount =
        recent.where(
      (m) => m.heartRate > 100,
    ).length;

    if (highHRCount >= 2) {
      reasons.add(
        'Heart rate has remained elevated across multiple measurements.',
      );
    }

    // ------------------------------------------
    // HRV
    // ------------------------------------------

    final lowHRVCount =
        recent.where(
      (m) =>
          m.hrvRmssd > 0 &&
          m.hrvRmssd < 20,
    ).length;

    if (lowHRVCount >= 2) {
      reasons.add(
        'HRV has remained low across multiple measurements.',
      );
    }

    return reasons;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width;

    final bool isMobile = width < 900;

    if (isMobile) {
      return _buildMobileDashboard();
    }

    return _buildDesktopDashboard();
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
        ),
        backgroundColor:
            Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: _loadStudents,
          ),
        ],
      ),

      drawer: Drawer(
        backgroundColor:
            Colors.grey[900],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color:
                          Colors.deepPurpleAccent,
                      size: 28,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Text(
                      'Athletes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: _buildStudentList(
                  closeDrawerAfterSelection:
                      true,
                ),
              ),
            ],
          ),
        ),
      ),

      body:
          _selectedStudent == null
              ? _buildWelcomeScreen()
              : _isLoadingMeasurements
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : _buildStudentDashboard(),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
        ),
        backgroundColor:
            Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: _loadStudents,
          ),
        ],
      ),

      body: Row(
        children: [
          Container(
            width: 310,
            color: Colors.grey[900],
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color:
                            Colors.deepPurpleAccent,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      const Text(
                        'Athletes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                Expanded(
                  child: _buildStudentList(),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                _selectedStudent == null
                    ? _buildWelcomeScreen()
                    : _isLoadingMeasurements
                        ? const Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        : _buildStudentDashboard(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT LIST
  // ============================================================

  Widget _buildStudentList({
    bool closeDrawerAfterSelection = false,
  }) {
    if (_isLoadingStudents) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Text(
          'No athletes found',
          style: TextStyle(
            color:
                Colors.grey[500],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount:
          _students.length,
      itemBuilder:
          (context, index) {
        final student =
            _students[index];

        final selected =
            _selectedStudent?.id ==
                student.id;

        return FutureBuilder<List<Measurement>>(
          future: _firebaseService
              .getMeasurementsForUser(
            student.id,
          ),
          builder:
              (context, snapshot) {
            final measurements =
                snapshot.data ?? [];

            final status =
                _getAthleteStatus(
              measurements,
            );

            return ListTile(
              selected: selected,

              selectedTileColor:
                  Colors.deepPurple
                      .withOpacity(0.25),

              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Colors.deepPurple,
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0]
                              .toUpperCase()
                          : '?',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                      ),
                    ),
                  ),

                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration:
                          BoxDecoration(
                        color:
                            _statusColor(
                          status,
                        ),
                        shape:
                            BoxShape.circle,
                        border: Border.all(
                          color:
                              Colors.grey[900]!,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              title: Text(
                student.name,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              subtitle: Text(
                _statusLabel(status),
                style: TextStyle(
                  color:
                      _statusColor(
                    status,
                  ),
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              trailing:
                  const Icon(
                Icons.chevron_right,
                color:
                    Colors.grey,
              ),

              onTap: () async {
                await _selectStudent(
                  student,
                );

                if (closeDrawerAfterSelection &&
                    mounted) {
                  Navigator.of(
                    context,
                  ).pop();
                }
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 90,
              color:
                  Colors.grey[700],
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              'Select an athlete',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.grey[400],
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Select an athlete to view HR, HRV, wellness, bio-factors, notes, and alerts.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey[600],
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            ElevatedButton.icon(
              onPressed:
                  _takeAdminMeasurement,
              icon: const Icon(
                Icons.favorite,
              ),
              label: const Text(
                'Take My Own Measurement',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT DASHBOARD
  // ============================================================

  Widget _buildStudentDashboard() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildNavigationRow(),

          const SizedBox(
            height: 16,
          ),

          _buildStudentHeader(),

          const SizedBox(
            height: 16,
          ),

          _buildAthleteAlertCard(),

          const SizedBox(
            height: 24,
          ),

          _buildTimeRangeSelector(),

          const SizedBox(
            height: 24,
          ),

          _buildSummaryCards(),

          const SizedBox(
            height: 24,
          ),

          _buildWellnessCard(),

          const SizedBox(
            height: 24,
          ),

          _buildBioFactorsCard(),

          const SizedBox(
            height: 24,
          ),

          _buildHRVChart(),

          const SizedBox(
            height: 24,
          ),

          _buildHRChart(),

          const SizedBox(
            height: 24,
          ),

          _buildMeasurementsTable(),

          const SizedBox(
            height: 30,
          ),

          Center(
            child: OutlinedButton.icon(
              onPressed:
                  _takeAdminMeasurement,
              icon: const Icon(
                Icons.favorite,
              ),
              label: const Text(
                'Take My Own Measurement',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION ROW
  // ============================================================

  Widget _buildNavigationRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _selectedStudent = null;
              _selectedMeasurements = [];
            });
          },
          icon: const Icon(
            Icons.arrow_back,
          ),
          label: const Text(
            'Back to Athletes',
          ),
        ),

        ElevatedButton.icon(
          onPressed:
              _takeAdminMeasurement,
          icon: const Icon(
            Icons.favorite,
          ),
          label: const Text(
            'Take My Own Measurement',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADMIN MEASUREMENT
  // ============================================================

  Future<void> _takeAdminMeasurement() async {
    try {
      final cameras =
          await availableCameras();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InstructionsPage(
            isAdmin: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open measurement: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // STUDENT HEADER
  // ============================================================

  Widget _buildStudentHeader() {
    final student =
        _selectedStudent!;

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor:
                  Colors.deepPurple,
              child: Text(
                student.name.isNotEmpty
                    ? student.name[0]
                        .toUpperCase()
                    : '?',
                style:
                    const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              width: 18,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (student.studentId != null)
                    Text(
                      'Student ID: ${student.studentId}',
                      style: TextStyle(
                        color:
                            Colors.grey[400],
                      ),
                    ),

                  if (student.email != null)
                    Text(
                      student.email!,
                      style: TextStyle(
                        color:
                            Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ATHLETE ALERT CARD
  // ============================================================

  Widget _buildAthleteAlertCard() {
    final status =
        _getAthleteStatus(
      _selectedMeasurements,
    );

    final reasons =
        _getAlertReasons(
      _selectedMeasurements,
    );

    final color =
        _statusColor(status);

    return Card(
      color: color.withOpacity(0.10),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
        side: BorderSide(
          color:
              color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _statusIcon(status),
                  color: color,
                  size: 30,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            if (status == 'alert') ...[
              const SizedBox(
                height: 8,
              ),

              Text(
                'A sustained concern has been detected across recent measurements.',
                style: TextStyle(
                  color:
                      Colors.grey[300],
                ),
              ),
            ],

            if (status == 'monitor') ...[
              const SizedBox(
                height: 8,
              ),

              Text(
                'Some wellness, physical, or physiological concerns should be monitored.',
                style: TextStyle(
                  color:
                      Colors.grey[300],
                ),
              ),
            ],

            if (status == 'normal') ...[
              const SizedBox(
                height: 8,
              ),

              Text(
                'No significant recurring concerns detected in the available measurements.',
                style: TextStyle(
                  color:
                      Colors.grey[300],
                ),
              ),
            ],

            if (reasons.isNotEmpty) ...[
              const SizedBox(
                height: 16,
              ),

              const Text(
                'Reasons:',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              ...reasons.map(
                (reason) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 6,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: color,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              color:
                                  Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIME RANGE
  // ============================================================

  Widget _buildTimeRangeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const Text(
          'Time Range:',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        ChoiceChip(
          label:
              const Text('7 Days'),
          selected:
              _selectedTimeRange == 7,
          onSelected: (_) =>
              _changeTimeRange(7),
        ),

        ChoiceChip(
          label:
              const Text('30 Days'),
          selected:
              _selectedTimeRange == 30,
          onSelected: (_) =>
              _changeTimeRange(30),
        ),

        ChoiceChip(
          label:
              const Text('90 Days'),
          selected:
              _selectedTimeRange == 90,
          onSelected: (_) =>
              _changeTimeRange(90),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCards() {
    if (_selectedMeasurements.isEmpty) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _summaryCard(
            'Measurements',
            '0',
            Icons.analytics,
          ),
        ],
      );
    }

    final avgHRV =
        _selectedMeasurements
                .map(
                  (m) => m.hrvRmssd,
                )
                .reduce(
                  (a, b) => a + b,
                ) /
            _selectedMeasurements
                .length;

    final avgHR =
        _selectedMeasurements
                .map(
                  (m) => m.heartRate,
                )
                .reduce(
                  (a, b) => a + b,
                ) /
            _selectedMeasurements
                .length;

    final latest =
        _selectedMeasurements.last;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard(
          'Measurements',
          '${_selectedMeasurements.length}',
          Icons.analytics,
        ),

        _summaryCard(
          'Average HRV',
          '${avgHRV.toStringAsFixed(1)} ms',
          Icons.favorite,
        ),

        _summaryCard(
          'Average HR',
          '${avgHR.toStringAsFixed(1)} BPM',
          Icons.monitor_heart,
        ),

        _summaryCard(
          'Latest HRV',
          '${latest.hrvRmssd.toStringAsFixed(1)} ms',
          Icons.show_chart,
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return SizedBox(
      width: 165,
      child: Card(
        color:
            Colors.grey[900],
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    Colors.tealAccent,
                size: 28,
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                value,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                title,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WELLNESS
  // ============================================================

  Widget _buildWellnessCard() {
    if (_selectedMeasurements.isEmpty) {
      return const SizedBox();
    }

    final latest =
        _selectedMeasurements.last;

    final wellness =
        latest.wellness;

    if (wellness == null) {
      return Card(
        color: Colors.grey[900],
        child: const Padding(
          padding:
              EdgeInsets.all(20),
          child: Text(
            'No wellness information was recorded for this measurement.',
          ),
        ),
      );
    }

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Wellness Report',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              DateFormat(
                'MMM dd, yyyy HH:mm',
              ).format(
                latest.timestamp,
              ),
              style: TextStyle(
                color:
                    Colors.grey[500],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _wellnessValue(
                  'Sleep',
                  wellness.sleep,
                ),
                _wellnessValue(
                  'Energy',
                  wellness.energy,
                ),
                _wellnessValue(
                  'Stress',
                  wellness.stress,
                ),
                _wellnessValue(
                  'Soreness',
                  wellness.soreness,
                ),
                _wellnessValue(
                  'Fatigue',
                  wellness.fatigue,
                ),
                _wellnessValue(
                  'Overall',
                  wellness.overall,
                ),
              ],
            ),

            if (wellness.notes != null &&
                wellness.notes!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: 20,
              ),

              const Text(
                'Student Notes',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey[850],
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),
                child: Text(
                  wellness.notes!,
                  style: TextStyle(
                    color:
                        Colors.grey[300],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _wellnessValue(
    String title,
    int value,
  ) {
    Color color;

    if (title == 'Stress' ||
        title == 'Soreness' ||
        title == 'Fatigue') {
      if (value >= 4) {
        color =
            Colors.redAccent;
      } else if (value == 3) {
        color =
            Colors.orangeAccent;
      } else {
        color =
            Colors.greenAccent;
      }
    } else {
      if (value <= 2) {
        color =
            Colors.orangeAccent;
      } else {
        color =
            Colors.greenAccent;
      }
    }

    return Container(
      width: 130,
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            Colors.grey[850],
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color:
                  Colors.grey[400],
              fontSize: 12,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            '$value / 5',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BIO FACTORS
  // ============================================================

  Widget _buildBioFactorsCard() {
    if (_selectedMeasurements.isEmpty) {
      return const SizedBox();
    }

    final latest =
        _selectedMeasurements.last;

    final factors =
        latest.bioFactors;

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Bio-Factors',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            if (factors.isEmpty)
              Text(
                'No physical concerns were reported.',
                style: TextStyle(
                  color:
                      Colors.grey[500],
                ),
              )
            else
              ...factors.map(
                (factor) {
                  final Color severityColor =
                      factor.severity >= 4
                          ? Colors.redAccent
                          : factor.severity >= 3
                              ? Colors.orangeAccent
                              : Colors.greenAccent;

                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding:
                        const EdgeInsets.all(14),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.grey[850],
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                      border:
                          Border.all(
                        color:
                            severityColor
                                .withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons
                                  .warning_amber,
                              color:
                                  severityColor,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                factor.bodyPart,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),

                            Text(
                              '${factor.severity}/5',
                              style: TextStyle(
                                color:
                                    severityColor,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          factor.issue,
                          style: TextStyle(
                            color:
                                Colors.grey[300],
                          ),
                        ),

                        if (factor.notes != null &&
                            factor.notes!
                                .trim()
                                .isNotEmpty) ...[
                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            'Notes: ${factor.notes}',
                            style:
                                TextStyle(
                              color:
                                  Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HRV GRAPH
  // ============================================================

  Widget _buildHRVChart() {
    if (_selectedMeasurements.isEmpty) {
      return _buildEmptyChart(
        'No HRV data available',
      );
    }

    final spots =
        _selectedMeasurements
            .asMap()
            .entries
            .map(
              (entry) => FlSpot(
                entry.key.toDouble(),
                entry.value.hrvRmssd,
              ),
            )
            .toList();

    return _buildChartCard(
      title: 'HRV Trend',
      subtitle:
          'Heart Rate Variability (RMSSD)',
      spots: spots,
      lineColor:
          Colors.tealAccent,
      yLabel: 'HRV (ms)',
    );
  }

  // ============================================================
  // HR GRAPH
  // ============================================================

  Widget _buildHRChart() {
    if (_selectedMeasurements.isEmpty) {
      return _buildEmptyChart(
        'No Heart Rate data available',
      );
    }

    final spots =
        _selectedMeasurements
            .asMap()
            .entries
            .map(
              (entry) => FlSpot(
                entry.key.toDouble(),
                entry.value.heartRate,
              ),
            )
            .toList();

    return _buildChartCard(
      title: 'Heart Rate Trend',
      subtitle:
          'Resting Heart Rate (BPM)',
      spots: spots,
      lineColor:
          Colors.redAccent,
      yLabel: 'BPM',
    );
  }

  // ============================================================
  // CHART CARD
  // ============================================================

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required List<FlSpot> spots,
    required Color lineColor,
    required String yLabel,
  }) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              subtitle,
              style: TextStyle(
                color:
                    Colors.grey[500],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              height: 300,
              width:
                  double.infinity,
              child: LineChart(
                LineChartData(
                  gridData:
                      FlGridData(
                    show: true,
                    drawVerticalLine:
                        false,
                  ),

                  titlesData:
                      FlTitlesData(
                    leftTitles:
                        AxisTitles(
                      axisNameWidget:
                          Text(yLabel),
                      sideTitles:
                          const SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                      ),
                    ),

                    bottomTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget:
                            (value, meta) {
                          final index =
                              value.toInt();

                          if (index < 0 ||
                              index >=
                                  _selectedMeasurements
                                      .length) {
                            return const SizedBox();
                          }

                          final date =
                              _selectedMeasurements[
                                      index]
                                  .timestamp;

                          return Text(
                            DateFormat(
                              'MM/dd',
                            ).format(date),
                            style:
                                TextStyle(
                              color:
                                  Colors.grey[500],
                              fontSize:
                                  10,
                            ),
                          );
                        },
                      ),
                    ),

                    rightTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),

                    topTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),

                  borderData:
                      FlBorderData(
                    show: true,
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      dotData:
                          const FlDotData(
                        show: true,
                      ),
                      belowBarData:
                          BarAreaData(
                        show: true,
                        color: lineColor
                            .withOpacity(
                          0.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildMeasurementsTable() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Measurement History',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            if (_selectedMeasurements.isEmpty)
              Text(
                'No measurements available.',
                style: TextStyle(
                  color:
                      Colors.grey[500],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(
                      label:
                          Text('Date'),
                    ),
                    DataColumn(
                      label:
                          Text('HR'),
                    ),
                    DataColumn(
                      label:
                          Text('HRV'),
                    ),
                    DataColumn(
                      label:
                          Text('Quality'),
                    ),
                    DataColumn(
                      label:
                          Text('Duration'),
                    ),
                  ],
                  rows:
                      _selectedMeasurements
                          .reversed
                          .map(
                    (measurement) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              DateFormat(
                                'MMM dd, yyyy HH:mm',
                              ).format(
                                measurement
                                    .timestamp,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              '${measurement.heartRate.toStringAsFixed(1)} BPM',
                            ),
                          ),

                          DataCell(
                            Text(
                              '${measurement.hrvRmssd.toStringAsFixed(1)} ms',
                            ),
                          ),

                          DataCell(
                            Text(
                              '${(measurement.qualityScore * 100).toStringAsFixed(0)}%',
                            ),
                          ),

                          DataCell(
                            Text(
                              '${measurement.durationSeconds}s',
                            ),
                          ),
                        ],
                      );
                    },
                  ).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY CHART
  // ============================================================

  Widget _buildEmptyChart(
    String message,
  ) {
    return Card(
      color: Colors.grey[900],
      child: SizedBox(
        height: 250,
        width:
            double.infinity,
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Text(
              message,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}