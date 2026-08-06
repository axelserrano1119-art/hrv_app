import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/measurement.dart';
import '../services/measurement_storage.dart';

class ResultsPage extends StatefulWidget {
  final Measurement measurement;

  const ResultsPage({
    super.key,
    required this.measurement,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<Measurement> history = [];


@override
void initState() {
  super.initState();

  _loadHistory();
}

  Future<void> _loadHistory() async {
  final data = await MeasurementStorage().loadMeasurements();

  debugPrint("=================================");
  debugPrint("History length: ${data.length}");

  for (final m in data) {
    debugPrint(
      "${m.timestamp} | "
      "HR=${m.heartRate.toStringAsFixed(1)} | "
      "HRV=${m.hrvRmssd.toStringAsFixed(1)}",
    );
  }

  debugPrint("=================================");

  setState(() {
    history = data;
  });
}

  Widget _bottomTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        "T${value.toInt() + 1}",
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Measurement Results"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "${widget.measurement.heartRate.toStringAsFixed(0)} BPM",
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "HRV RMSSD: ${widget.measurement.hrvRmssd.toStringAsFixed(1)} ms",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Heart Rate History",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: history.isEmpty
                      ? 1
                      : (history.length - 1).toDouble(),

                  minY: 40,
                  maxY: 180,

                  gridData: FlGridData(show: true),

                  borderData: FlBorderData(show: true),

                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: _bottomTitles,
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        history.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          history[index].heartRate,
                        ),
                      ),

                      isCurved: false,

                      barWidth: 0,

                      dotData: const FlDotData(
                        show: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 35),

            const Text(
              "HRV History",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: history.isEmpty
                      ? 1
                      : (history.length - 1).toDouble(),

                  minY: 0,
                  maxY: history.isEmpty
                      ? 100
                      : history
                              .map((e) => e.hrvRmssd)
                              .reduce((a, b) => a > b ? a : b) +
                          10,

                  gridData: FlGridData(show: true),

                  borderData: FlBorderData(show: true),

                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: _bottomTitles,
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        history.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          history[index].hrvRmssd,
                        ),
                      ),

                      isCurved: false,

                      barWidth: 0,

                      dotData: const FlDotData(
                        show: true,
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
}