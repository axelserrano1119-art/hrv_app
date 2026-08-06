

// screens/admin_dashboard_screen.dart
// Administrator view for viewing all user data and trends

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/secure_storage_service.dart';
import '../models/user_profile.dart';
import '../models/measurement.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<UserProfile> _users = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  UserProfile? _selectedUser;
  List<Measurement> _selectedUserMeasurements = [];
  int _selectedTimeRange = 7; // days

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final users = await SecureStorageService.getAllUsers();
    final stats = await SecureStorageService.getAdminStatistics();
    
    setState(() {
      _users = users;
      _statistics = stats;
      _isLoading = false;
    });
  }

  Future<void> _selectUser(UserProfile user) async {
    setState(() => _isLoading = true);
    
    final end = DateTime.now();
    final start = end.subtract(Duration(days: _selectedTimeRange));
    final measurements = await SecureStorageService.getMeasurementsInRange(user.userId, start, end);
    
    setState(() {
      _selectedUser = user;
      _selectedUserMeasurements = measurements;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // User List Sidebar
                Container(
                  width: 300,
                  color: Colors.grey[900],
                  child: Column(
                    children: [
                      // Statistics Summary Card
                      _buildStatsSummary(),
                      const Divider(color: Colors.grey),
                      // User List
                      Expanded(
                        child: ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isSelected = _selectedUser?.userId == user.userId;
                            
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.deepPurple.withOpacity(0.3),
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text(user.name[0].toUpperCase()),
                              ),
                              title: Text(user.name),
                              subtitle: Text(user.email),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(user),
                              ),
                              onTap: () => _selectUser(user),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content Area
                Expanded(
                  child: _selectedUser == null
                      ? _buildWelcomeView()
                      : _buildUserDetailView(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsSummary() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _statCard('Total Users', '${_statistics['total_users'] ?? 0}'),
          _statCard('Total Measurements', '${_statistics['total_measurements'] ?? 0}'),
          _statCard('Avg HRV', '${(_statistics['average_hrv'] ?? 0).toStringAsFixed(1)} ms'),
          _statCard('Avg HR', '${(_statistics['average_hr'] ?? 0).toStringAsFixed(1)} BPM'),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'Select a user to view details',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.deepPurple,
                child: Text(
                  _selectedUser!.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedUser!.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _selectedUser!.email,
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  Text(
                    'Member since ${DateFormat('MMM yyyy').format(_selectedUser!.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Time Range Selector
          _buildTimeRangeSelector(),
          const SizedBox(height: 24),
          
          // HRV Trend Chart
          _buildHRVChart(),
          const SizedBox(height: 24),
          
          // Heart Rate Trend Chart
          _buildHRChart(),
          const SizedBox(height: 24),
          
          // Measurements Table
          _buildMeasurementsTable(),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(
      children: [
        const Text('Time Range:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('7 Days'),
          selected: _selectedTimeRange == 7,
          onSelected: (_) => _changeTimeRange(7),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('30 Days'),
          selected: _selectedTimeRange == 30,
          onSelected: (_) => _changeTimeRange(30),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('90 Days'),
          selected: _selectedTimeRange == 90,
          onSelected: (_) => _changeTimeRange(90),
        ),
      ],
    );
  }

  void _changeTimeRange(int days) {
    setState(() => _selectedTimeRange = days);
    if (_selectedUser != null) {
      _selectUser(_selectedUser!);
    }
  }

  Widget _buildHRVChart() {
    if (_selectedUserMeasurements.isEmpty) {
      return _buildEmptyChart('No HRV data available');
    }

    final spots = _selectedUserMeasurements.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.hrvRmssd);
    }).toList();

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HRV Trend (RMSSD)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.tealAccent,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.tealAccent.withOpacity(0.2),
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

  Widget _buildHRChart() {
    if (_selectedUserMeasurements.isEmpty) {
      return _buildEmptyChart('No Heart Rate data available');
    }

    final spots = _selectedUserMeasurements.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.heartRate);
    }).toList();

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Heart Rate Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.redAccent,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.redAccent.withOpacity(0.2),
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

  Widget _buildMeasurementsTable() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Measurement History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('HR (BPM)')),
                  DataColumn(label: Text('HRV (ms)')),
                  DataColumn(label: Text('Quality')),
                  DataColumn(label: Text('Duration')),
                ],
                rows: _selectedUserMeasurements.reversed.map((m) {
                  return DataRow(
                    cells: [
                      DataCell(Text(DateFormat('MMM dd, HH:mm').format(m.timestamp))),
                      DataCell(Text(m.heartRate.toStringAsFixed(1))),
                      DataCell(Text(m.hrvRmssd.toStringAsFixed(1))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: m.qualityScore > 0.7 ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(m.qualityScore * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(Text('${m.durationSeconds}s')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Card(
      color: Colors.grey[900],
      child: SizedBox(
        height: 250,
        child: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Data'),
        content: Text('Are you sure you want to delete all data for ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await SecureStorageService.deleteUserData(user.userId);
              Navigator.pop(context);
              _loadData();
              if (_selectedUser?.userId == user.userId) {
                setState(() => _selectedUser = null);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
