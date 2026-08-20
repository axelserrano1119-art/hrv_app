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
    final data =
        await MeasurementStorage().loadMeasurements();

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

    if (!mounted) return;

    setState(() {
      history = data;
    });
  }

  // ============================================================
  // BOTTOM TITLES
  // ============================================================

  Widget _bottomTitles(
    double value,
    TitleMeta meta,
  ) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        "T${value.toInt() + 1}",
        style: const TextStyle(
          fontSize: 10,
        ),
      ),
    );
  }

  // ============================================================
  // RR INTERVAL GRAPH
  // ============================================================

  Widget _buildRRIntervalChart() {
    final rrIntervals =
        widget.measurement.rrIntervals;

    if (rrIntervals.isEmpty) {
      return Card(
        child: SizedBox(
          height: 250,
          width: double.infinity,
          child: Center(
            child: Text(
              "No RR interval data available",
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    final spots = List.generate(
      rrIntervals.length,
      (index) => FlSpot(
        index.toDouble(),
        rrIntervals[index],
      ),
    );

    final minRR =
        rrIntervals.reduce(
          (a, b) => a < b ? a : b,
        );

    final maxRR =
        rrIntervals.reduce(
          (a, b) => a > b ? a : b,
        );

    double chartMinY =
        (minRR - 100).clamp(0, double.infinity);

    double chartMaxY =
        maxRR + 100;

    if (chartMaxY - chartMinY < 200) {
      final center =
          (chartMaxY + chartMinY) / 2;

      chartMinY =
          (center - 100).clamp(
        0,
        double.infinity,
      );

      chartMaxY =
          center + 100;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "RR Interval",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "Beat-to-beat RR interval variation",
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 5),

            Text(
              "${rrIntervals.length} RR intervals",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX:
                      rrIntervals.length > 1
                          ? (rrIntervals.length - 1)
                              .toDouble()
                          : 1,

                  minY: chartMinY,
                  maxY: chartMaxY,

                  gridData: FlGridData(
                    show: true,
                  ),

                  borderData:
                      FlBorderData(
                    show: true,
                  ),

                  titlesData:
                      FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),

                    rightTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),

                    leftTitles:
                        AxisTitles(
                      axisNameWidget:
                          const Text(
                        "RR (ms)",
                      ),
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                      ),
                    ),

                    bottomTitles:
                        AxisTitles(
                      axisNameWidget:
                          const Text(
                        "Beat / Interval",
                      ),
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval:
                            rrIntervals.length > 10
                                ? (rrIntervals.length /
                                        5)
                                    .ceilToDouble()
                                : 1,
                        getTitlesWidget:
                            (value, meta) {
                          return Text(
                            "${value.toInt() + 1}",
                            style:
                                const TextStyle(
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 2,
                      color:
                          Colors.blueAccent,
                      dotData:
                          const FlDotData(
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Measurement Results",
        ),

        // NEW BACK BUTTON
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          tooltip: "Back",
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            // ==================================================
            // CURRENT MEASUREMENT
            // ==================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "${widget.measurement.heartRate.toStringAsFixed(0)} BPM",
                      style:
                          const TextStyle(
                        fontSize: 42,
                        fontWeight:
                            FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      "HRV RMSSD: ${widget.measurement.hrvRmssd.toStringAsFixed(1)} ms",
                      style:
                          const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // HEART RATE HISTORY
            // ==================================================

            const Text(
              "Heart Rate History",
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 0,

                  maxX: history.isEmpty
                      ? 1
                      : (history.length - 1)
                          .toDouble(),

                  minY: 40,
                  maxY: 180,

                  gridData:
                      FlGridData(
                    show: true,
                  ),

                  borderData:
                      FlBorderData(
                    show: true,
                  ),

                  titlesData:
                      FlTitlesData(
                    topTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),

                    rightTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),

                    leftTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),

                    bottomTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget:
                            _bottomTitles,
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          List.generate(
                        history.length,
                        (index) =>
                            FlSpot(
                          index.toDouble(),
                          history[index]
                              .heartRate,
                        ),
                      ),

                      isCurved: false,

                      barWidth: 0,

                      dotData:
                          const FlDotData(
                        show: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            // ==================================================
            // HRV HISTORY
            // ==================================================

            const Text(
              "HRV History",
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 0,

                  maxX: history.isEmpty
                      ? 1
                      : (history.length - 1)
                          .toDouble(),

                  minY: 0,

                  maxY: history.isEmpty
                      ? 100
                      : history
                              .map(
                                (e) =>
                                    e.hrvRmssd,
                              )
                              .reduce(
                                (a, b) =>
                                    a > b
                                        ? a
                                        : b,
                              ) +
                          10,

                  gridData:
                      FlGridData(
                    show: true,
                  ),

                  borderData:
                      FlBorderData(
                    show: true,
                  ),

                  titlesData:
                      FlTitlesData(
                    topTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),

                    rightTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: false,
                      ),
                    ),

                    leftTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),

                    bottomTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget:
                            _bottomTitles,
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          List.generate(
                        history.length,
                        (index) =>
                            FlSpot(
                          index.toDouble(),
                          history[index]
                              .hrvRmssd,
                        ),
                      ),

                      isCurved: false,

                      barWidth: 0,

                      dotData:
                          const FlDotData(
                        show: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            // ==================================================
            // NEW RR INTERVAL GRAPH
            // ==================================================

            _buildRRIntervalChart(),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}