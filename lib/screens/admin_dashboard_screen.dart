// screens/admin_dashboard_screen.dart
// Administrator view for viewing student data and HR/HRV trends

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/measurement.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {

  final FirebaseService _firebaseService = FirebaseService();

  // All students from Firebase
  List<User> _students = [];

  // Currently selected student
  User? _selectedStudent;

  // Selected student's measurements
  List<Measurement> _selectedMeasurements = [];

  bool _isLoadingStudents = true;
  bool _isLoadingMeasurements = false;

  int _selectedTimeRange = 7;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  // ============================================================
  // LOAD STUDENTS
  // ============================================================

  Future<void> _loadStudents() async {

    setState(() {
      _isLoadingStudents = true;
    });

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
          await _firebaseService.getMeasurementsForUser(
        student.id,
      );

      if (!mounted) return;

      // Apply selected time range
      final now = DateTime.now();

      final startDate =
          now.subtract(
        Duration(days: _selectedTimeRange),
      );

      final filteredMeasurements =
          measurements.where((measurement) {

        return measurement.timestamp
                .isAfter(startDate) &&
            measurement.timestamp.isBefore(now);

      }).toList();

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
  // CHANGE TIME RANGE
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {

    final screenWidth =
        MediaQuery.of(context).size.width;

    // Phones and smaller tablets use a drawer.
    // Desktop keeps the permanent sidebar.
    final bool isMobile =
        screenWidth < 900;

    if (isMobile) {
      return _buildMobileDashboard();
    }

    return _buildDesktopDashboard();
  }

  // ============================================================
  // MOBILE DASHBOARD
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

            onPressed:
                _loadStudents,
          ),
        ],
      ),

      // --------------------------------------------------------
      // STUDENT DRAWER
      // --------------------------------------------------------

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
                      'Students',
                      style:
                          TextStyle(
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

      // --------------------------------------------------------
      // FULL-SCREEN DASHBOARD
      // --------------------------------------------------------

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
  // DESKTOP DASHBOARD
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

            onPressed:
                _loadStudents,
          ),
        ],
      ),

      body: Row(

        children: [

          // ======================================================
          // STUDENT SIDEBAR
          // ======================================================

          Container(
            width: 300,

            color:
                Colors.grey[900],

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
                        'Students',
                        style:
                            TextStyle(
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
                  child:
                      _buildStudentList(),
                ),
              ],
            ),
          ),

          // ======================================================
          // MAIN CONTENT
          // ======================================================

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
          'No students found',

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

        return ListTile(

          selected:
              selected,

          selectedTileColor:
              Colors.deepPurple
                  .withOpacity(0.25),

          leading:
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

          title: Text(
            student.name,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          subtitle:
              Text(

            student.studentId ??
                student.email ??
                '',

            style:
                TextStyle(
              color:
                  Colors.grey[500],
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

              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  // ============================================================
  // WELCOME SCREEN
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
              'Select a student',

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
              'Select a student from the list to view their HR and HRV data.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    Colors.grey[600],
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

          // Student information
          _buildStudentHeader(),

          const SizedBox(
            height: 24,
          ),

          // Time range
          _buildTimeRangeSelector(),

          const SizedBox(
            height: 24,
          ),

          // Summary
          _buildSummaryCards(),

          const SizedBox(
            height: 24,
          ),

          // HRV graph
          _buildHRVChart(),

          const SizedBox(
            height: 24,
          ),

          // HR graph
          _buildHRChart(),

          const SizedBox(
            height: 24,
          ),

          // Measurement table
          _buildMeasurementsTable(),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT HEADER
  // ============================================================

  Widget _buildStudentHeader() {

    final student =
        _selectedStudent!;

    return Card(

      color:
          Colors.grey[900],

      child: Padding(

        padding:
            const EdgeInsets.all(20),

        child: Row(

          crossAxisAlignment:
              CrossAxisAlignment.start,

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

                  const SizedBox(
                    height: 4,
                  ),

                  if (student.studentId != null)
                    Text(

                      'Student ID: ${student.studentId}',

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          TextStyle(
                        color:
                            Colors.grey[400],
                      ),
                    ),

                  if (student.email != null)
                    Text(

                      student.email!,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          TextStyle(
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
  // TIME RANGE
  // ============================================================

  Widget _buildTimeRangeSelector() {

    return Wrap(

      spacing: 8,

      runSpacing: 8,

      crossAxisAlignment:
          WrapCrossAlignment.center,

      children: [

        const Text(
          'Time Range:',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        ChoiceChip(

          label:
              const Text(
            '7 Days',
          ),

          selected:
              _selectedTimeRange == 7,

          onSelected: (_) =>
              _changeTimeRange(7),
        ),

        ChoiceChip(

          label:
              const Text(
            '30 Days',
          ),

          selected:
              _selectedTimeRange == 30,

          onSelected: (_) =>
              _changeTimeRange(30),
        ),

        ChoiceChip(

          label:
              const Text(
            '90 Days',
          ),

          selected:
              _selectedTimeRange == 90,

          onSelected: (_) =>
              _changeTimeRange(90),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards() {

    if (_selectedMeasurements.isEmpty) {

      return Wrap(

        spacing: 12,

        runSpacing: 12,

        children: [

          SizedBox(
            width: 160,

            child: _summaryCard(
              'Measurements',
              '0',
              Icons.analytics,
            ),
          ),
        ],
      );
    }

    final avgHRV =
        _selectedMeasurements
                .map((m) => m.hrvRmssd)
                .reduce(
                    (a, b) => a + b) /
            _selectedMeasurements.length;

    final avgHR =
        _selectedMeasurements
                .map((m) => m.heartRate)
                .reduce(
                    (a, b) => a + b) /
            _selectedMeasurements.length;

    final latest =
        _selectedMeasurements.last;

    return Wrap(

      spacing: 12,

      runSpacing: 12,

      children: [

        SizedBox(
          width: 160,

          child: _summaryCard(
            'Measurements',
            '${_selectedMeasurements.length}',
            Icons.analytics,
          ),
        ),

        SizedBox(
          width: 160,

          child: _summaryCard(
            'Average HRV',
            '${avgHRV.toStringAsFixed(1)} ms',
            Icons.favorite,
          ),
        ),

        SizedBox(
          width: 160,

          child: _summaryCard(
            'Average HR',
            '${avgHR.toStringAsFixed(1)} BPM',
            Icons.monitor_heart,
          ),
        ),

        SizedBox(
          width: 160,

          child: _summaryCard(
            'Latest HRV',
            '${latest.hrvRmssd.toStringAsFixed(1)} ms',
            Icons.show_chart,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {

    return Card(

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

    return Card(

      color:
          Colors.grey[900],

      child: Padding(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              'HRV Trend',

              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              'Heart Rate Variability (RMSSD)',

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
                          const Text(
                        'HRV (ms)',
                      ),

                      sideTitles:
                          SideTitles(
                        showTitles:
                            true,

                        reservedSize:
                            50,
                      ),
                    ),

                    bottomTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            true,

                        reservedSize:
                            40,

                        getTitlesWidget:
                            (value, meta) {

                          final index =
                              value.toInt();

                          if (index <
                                  0 ||
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
                            ).format(
                              date,
                            ),

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
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            false,
                      ),
                    ),

                    topTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            false,
                      ),
                    ),
                  ),

                  borderData:
                      FlBorderData(
                    show: true,
                  ),

                  lineBarsData: [

                    LineChartBarData(

                      spots:
                          spots,

                      isCurved:
                          true,

                      color:
                          Colors.tealAccent,

                      barWidth:
                          3,

                      dotData:
                          FlDotData(
                        show:
                            true,
                      ),

                      belowBarData:
                          BarAreaData(
                        show:
                            true,

                        color: Colors
                            .tealAccent
                            .withOpacity(
                                0.15),
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
  // HEART RATE GRAPH
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

    return Card(

      color:
          Colors.grey[900],

      child: Padding(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              'Heart Rate Trend',

              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              'Resting Heart Rate (BPM)',

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
                          const Text(
                        'BPM',
                      ),

                      sideTitles:
                          SideTitles(
                        showTitles:
                            true,

                        reservedSize:
                            50,
                      ),
                    ),

                    bottomTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            true,

                        reservedSize:
                            40,

                        getTitlesWidget:
                            (value, meta) {

                          final index =
                              value.toInt();

                          if (index <
                                  0 ||
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
                            ).format(
                              date,
                            ),

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
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            false,
                      ),
                    ),

                    topTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            false,
                      ),
                    ),
                  ),

                  borderData:
                      FlBorderData(
                    show: true,
                  ),

                  lineBarsData: [

                    LineChartBarData(

                      spots:
                          spots,

                      isCurved:
                          true,

                      color:
                          Colors.redAccent,

                      barWidth:
                          3,

                      dotData:
                          FlDotData(
                        show:
                            true,
                      ),

                      belowBarData:
                          BarAreaData(
                        show:
                            true,

                        color: Colors
                            .redAccent
                            .withOpacity(
                                0.15),
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
  // MEASUREMENT TABLE
  // ============================================================

  Widget _buildMeasurementsTable() {

    return Card(

      color:
          Colors.grey[900],

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

              Padding(

                padding:
                    const EdgeInsets.all(20),

                child: Text(
                  'No measurements available.',

                  style: TextStyle(
                    color:
                        Colors.grey[500],
                  ),
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

                      final quality =
                          measurement
                              .qualityScore;

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
                              '${(quality * 100).toStringAsFixed(0)}%',
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
  // EMPTY GRAPH
  // ============================================================

  Widget _buildEmptyChart(
    String message,
  ) {

    return Card(

      color:
          Colors.grey[900],

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