

// screens/history_screen.dart
// User-facing history and trend analysis

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/secure_storage_service.dart';
import '../models/measurement.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;
  
  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Measurement> _measurements = [];
  bool _isLoading = true;
  int _selectedTimeRange = 7;
  String _selectedMetric = 'hrv'; // 'hrv' or 'hr'

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    
    final end = DateTime.now();
    final start = end.subtract(Duration(days: _selectedTimeRange));
    final measurements = await SecureStorageService.getMeasurementsInRange(
      widget.userId, start, end
    );
    
    setState(() {
      _measurements = measurements;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Health History'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMeasurements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _measurements.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No measurements yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Take your first measurement to see trends here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 24),
          
          // Time Range & Metric Selector
          _buildControls(),
          const SizedBox(height: 24),
          
          // Main Trend Chart
          _buildMainChart(),
          const SizedBox(height: 24),
          
          // HRV vs HR Scatter Plot
          _buildCorrelationChart(),
          const SizedBox(height: 24),
          
          // Daily Breakdown
          _buildDailyBreakdown(),
          const SizedBox(height: 24),
          
          // Measurement List
          _buildMeasurementList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final avgHRV = _measurements.map((m) => m.hrvRmssd).reduce((a, b) => a + b) / _measurements.length;
    final avgHR = _measurements.map((m) => m.heartRate).reduce((a, b) => a + b) / _measurements.length;
    final latestHRV = _measurements.last.hrvRmssd;
    final latestHR = _measurements.last.heartRate;
    
    // Calculate trend
    final hrvTrend = latestHRV > avgHRV ? 'up' : 'down';
    final hrTrend = latestHR < avgHR ? 'up' : 'down'; // Lower HR is better
    
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Latest HRV',
            '${latestHRV.toStringAsFixed(1)} ms',
            hrvTrend == 'up' ? Icons.trending_up : Icons.trending_down,
            hrvTrend == 'up' ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Latest HR',
            '${latestHR.toStringAsFixed(0)} BPM',
            hrTrend == 'up' ? Icons.trending_down : Icons.trending_up,
            hrTrend == 'up' ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Measurements',
            '${_measurements.length}',
            Icons.fact_check,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        // Time Range
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7D')),
            ButtonSegment(value: 30, label: Text('30D')),
            ButtonSegment(value: 90, label: Text('90D')),
          ],
          selected: {_selectedTimeRange},
          onSelectionChanged: (Set<int> newSelection) {
            setState(() {
              _selectedTimeRange = newSelection.first;
            });
            _loadMeasurements();
          },
        ),
        const Spacer(),
        // Metric Toggle
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'hrv', label: Text('HRV')),
            ButtonSegment(value: 'hr', label: Text('HR')),
          ],
          selected: {_selectedMetric},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() => _selectedMetric = newSelection.first);
          },
        ),
      ],
    );
  }

  Widget _buildMainChart() {
    final data = _selectedMetric == 'hrv'
        ? _measurements.map((m) => m.hrvRmssd).toList()
        : _measurements.map((m) => m.heartRate).toList();
    
    final color = _selectedMetric == 'hrv' ? Colors.tealAccent : Colors.redAccent;
    final title = _selectedMetric == 'hrv' ? 'HRV (RMSSD)' : 'Heart Rate';
    final unit = _selectedMetric == 'hrv' ? 'ms' : 'BPM';
    
    final spots = data.asMap().entries.map((e) => 
      FlSpot(e.key.toDouble(), e.value)
    ).toList();

    // Calculate moving average
    final maSpots = <FlSpot>[];
    int window = min(5, data.length);
    for (int i = window - 1; i < data.length; i++) {
      double avg = data.sublist(i - window + 1, i + 1).reduce((a, b) => a + b) / window;
      maSpots.add(FlSpot(i.toDouble(), avg));
    }

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title Trend',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _selectedMetric == 'hrv' ? 10 : 5,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(0)} $unit',
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < _measurements.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MM/dd').format(_measurements[idx].timestamp),
                                style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                rotation: 45,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Raw data
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color.withOpacity(0.3),
                      barWidth: 1,
                      dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      }),
                    ),
                    // Moving average
                    LineChartBarData(
                      spots: maSpots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
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

  Widget _buildCorrelationChart() {
    final hrvData = _measurements.map((m) => m.hrvRmssd).toList();
    final hrData = _measurements.map((m) => m.heartRate).toList();
    
    final spots = List.generate(_measurements.length, (i) => 
      FlSpot(hrData[i], hrvData[i])
    );

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HRV vs Heart Rate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Lower HR typically correlates with higher HRV',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: ScatterChart(
                ScatterChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(0)} ms',
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(0)} BPM',
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  scatterSpots: spots.map((spot) => ScatterSpot(
                    spot.x,
                    spot.y,
                    dotPainter: FlDotCirclePainter(
                      radius: 8,
                      color: Colors.tealAccent.withOpacity(0.6),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    // Group by day and calculate averages
    Map<String, List<Measurement>> byDay = {};
    for (var m in _measurements) {
      String day = DateFormat('yyyy-MM-dd').format(m.timestamp);
      byDay.putIfAbsent(day, () => []).add(m);
    }

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Averages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          List<String> days = byDay.keys.toList();
                          int idx = value.toInt();
                          if (idx >= 0 && idx < days.length) {
                            return Text(
                              DateFormat('MM/dd').format(DateTime.parse(days[idx])),
                              style: TextStyle(color: Colors.grey[500], fontSize: 10),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: byDay.entries.toList().asMap().entries.map((entry) {
                    int idx = entry.key;
                    var dayMeasurements = entry.value.value;
                    double avgHRV = dayMeasurements.map((m) => m.hrvRmssd).reduce((a, b) => a + b) / dayMeasurements.length;
                    
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: avgHRV,
                          color: Colors.tealAccent,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementList() {
    return Card(
      color: Colors.grey[900],
      child: ExpansionTile(
        title: const Text('All Measurements'),
        children: _measurements.reversed.map((m) {
          return ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: m.qualityScore > 0.7 ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              DateFormat('MMM dd, yyyy - HH:mm').format(m.timestamp),
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              'HR: ${m.heartRate.toStringAsFixed(0)} BPM | HRV: ${m.hrvRmssd.toStringAsFixed(1)} ms',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            trailing: Text(
              '${(m.qualityScore * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: m.qualityScore > 0.7 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _showMeasurementDetail(m),
          );
        }).toList(),
      ),
    );
  }

  void _showMeasurementDetail(Measurement measurement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Measurement Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _detailRow('Date', DateFormat('MMMM dd, yyyy HH:mm').format(measurement.timestamp)),
            _detailRow('Heart Rate', '${measurement.heartRate.toStringAsFixed(1)} BPM'),
            _detailRow('HRV (RMSSD)', '${measurement.hrvRmssd.toStringAsFixed(1)} ms'),
            if (measurement.hrvSdnn != null)
              _detailRow('HRV (SDNN)', '${measurement.hrvSdnn!.toStringAsFixed(1)} ms'),
            if (measurement.hrvPnn50 != null)
              _detailRow('pNN50', '${measurement.hrvPnn50!.toStringAsFixed(1)}%'),
            if (measurement.lfhfRatio != null)
              _detailRow('LF/HF Ratio', measurement.lfhfRatio!.toStringAsFixed(2)),
            _detailRow('Quality Score', '${(measurement.qualityScore * 100).toStringAsFixed(0)}%'),
            _detailRow('Duration', '${measurement.durationSeconds} seconds'),
            if (measurement.notes != null)
              _detailRow('Notes', measurement.notes!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
