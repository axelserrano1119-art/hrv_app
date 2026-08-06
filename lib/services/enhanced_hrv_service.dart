

// services/enhanced_hrv_service.dart
// Implements comprehensive HRV analysis with artifact correction and multiple metrics

import 'dart:math';
import 'enhanced_signal_processor.dart';

class HRVMetrics {
  final double rmssd;           // Root Mean Square of Successive Differences
  final double sdnn;            // Standard Deviation of NN intervals
  final double pnn50;           // Percentage of successive RR intervals that differ by more than 50 ms
  final double sd1;             // Poincaré plot SD1 (short-term variability)
  final double sd2;             // Poincaré plot SD2 (long-term variability)
  final double sd1sd2Ratio;     // SD1/SD2 ratio
  final double lfPower;         // Low Frequency power (0.04-0.15 Hz)
  final double hfPower;         // High Frequency power (0.15-0.4 Hz)
  final double lfhfRatio;       // LF/HF ratio
  final double meanHR;          // Mean heart rate
  final double meanRR;          // Mean RR interval
  final int totalBeats;         // Total number of beats analyzed
  final double qualityScore;    // Overall quality score
  final DateTime timestamp;
  
  HRVMetrics({
    required this.rmssd,
    required this.sdnn,
    required this.pnn50,
    required this.sd1,
    required this.sd2,
    required this.sd1sd2Ratio,
    required this.lfPower,
    required this.hfPower,
    required this.lfhfRatio,
    required this.meanHR,
    required this.meanRR,
    required this.totalBeats,
    required this.qualityScore,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'rmssd': rmssd,
    'sdnn': sdnn,
    'pnn50': pnn50,
    'sd1': sd1,
    'sd2': sd2,
    'sd1sd2_ratio': sd1sd2Ratio,
    'lf_power': lfPower,
    'hf_power': hfPower,
    'lf_hf_ratio': lfhfRatio,
    'mean_hr': meanHR,
    'mean_rr': meanRR,
    'total_beats': totalBeats,
    'quality_score': qualityScore,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory HRVMetrics.fromJson(Map<String, dynamic> json) => HRVMetrics(
    rmssd: json['rmssd'],
    sdnn: json['sdnn'],
    pnn50: json['pnn50'],
    sd1: json['sd1'],
    sd2: json['sd2'],
    sd1sd2Ratio: json['sd1sd2_ratio'],
    lfPower: json['lf_power'],
    hfPower: json['hf_power'],
    lfhfRatio: json['lf_hf_ratio'],
    meanHR: json['mean_hr'],
    meanRR: json['mean_rr'],
    totalBeats: json['total_beats'],
    qualityScore: json['quality_score'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class EnhancedHRVService {
  
  // Calculate all HRV metrics from RR intervals
  static HRVMetrics calculateAllMetrics(
    List<double> rrIntervals, {
    double samplingRate = 30.0,
  }) {
    if (rrIntervals.length < 5) {
      return HRVMetrics(
        rmssd: 0, sdnn: 0, pnn50: 0, sd1: 0, sd2: 0, sd1sd2Ratio: 0,
        lfPower: 0, hfPower: 0, lfhfRatio: 0, meanHR: 0, meanRR: 0,
        totalBeats: rrIntervals.length, qualityScore: 0,
        timestamp: DateTime.now(),
      );
    }
    
    // Step 1: Artifact correction using Kubios-style method
    List<double> correctedRR = EnhancedSignalProcessor.correctArtifacts(rrIntervals);
    
    // Step 2: Cubic spline interpolation for accurate frequency analysis
    List<double> interpolatedRR = EnhancedSignalProcessor.cubicSplineInterpolate(correctedRR, 256);
    
    // Step 3: Calculate time-domain metrics
    double meanRR = correctedRR.reduce((a, b) => a + b) / correctedRR.length;
    double meanHR = 60000 / meanRR;
    
    // SDNN
    double variance = correctedRR.map((x) => pow(x - meanRR, 2)).reduce((a, b) => a + b) / correctedRR.length;
    double sdnn = sqrt(variance);
    
    // RMSSD
    double sumSquaredDiff = 0;
    for (int i = 1; i < correctedRR.length; i++) {
      sumSquaredDiff += pow(correctedRR[i] - correctedRR[i-1], 2);
    }
    double rmssd = sqrt(sumSquaredDiff / (correctedRR.length - 1));
    
    // pNN50
    int nn50 = 0;
    for (int i = 1; i < correctedRR.length; i++) {
      if ((correctedRR[i] - correctedRR[i-1]).abs() > 50) nn50++;
    }
    double pnn50 = (nn50 / (correctedRR.length - 1)) * 100;
    
    // Poincaré plot metrics (SD1, SD2)
    List<double> rrDiff = [];
    List<double> rrPlus = [];
    for (int i = 1; i < correctedRR.length; i++) {
      rrDiff.add(correctedRR[i] - correctedRR[i-1]);
      rrPlus.add((correctedRR[i] + correctedRR[i-1]) / 2);
    }
    
    double sd1 = _calculateSD(rrDiff) / sqrt(2);
    double sd2 = _calculateSD(rrPlus) / sqrt(2);
    double sd1sd2Ratio = sd2 > 0 ? sd1 / sd2 : 0;
    
    // Frequency domain analysis using Lomb-Scargle periodogram
    // (better for unevenly sampled RR intervals than FFT)
    Map<String, double> freqMetrics = _lombScarglePeriodogram(correctedRR);
    
    // Quality score based on multiple factors
    double qualityScore = _calculateQualityScore(
      correctedRR, rmssd, sdnn, freqMetrics['lf_power']!, freqMetrics['hf_power']!
    );
    
    return HRVMetrics(
      rmssd: rmssd,
      sdnn: sdnn,
      pnn50: pnn50,
      sd1: sd1,
      sd2: sd2,
      sd1sd2Ratio: sd1sd2Ratio,
      lfPower: freqMetrics['lf_power']!,
      hfPower: freqMetrics['hf_power']!,
      lfhfRatio: freqMetrics['lf_hf_ratio']!,
      meanHR: meanHR,
      meanRR: meanRR,
      totalBeats: correctedRR.length,
      qualityScore: qualityScore,
      timestamp: DateTime.now(),
    );
  }
  
  // Lomb-Scargle periodogram for unevenly sampled data
  static Map<String, double> _lombScarglePeriodogram(List<double> rrIntervals) {
    // Create time axis (cumulative)
    List<double> time = [0];
    for (int i = 0; i < rrIntervals.length; i++) {
      time.add(time.last + rrIntervals[i] / 1000); // seconds
    }
    time.removeAt(0);
    
    // Frequency ranges
    double lfMin = 0.04, lfMax = 0.15;  // Low frequency
    double hfMin = 0.15, hfMax = 0.4;   // High frequency
    
    double lfPower = 0, hfPower = 0;
    int lfCount = 0, hfCount = 0;
    
    // Sample frequencies
    for (double freq = 0.01; freq <= 0.5; freq += 0.005) {
      double power = _lombPower(time, rrIntervals, freq);
      
      if (freq >= lfMin && freq <= lfMax) {
        lfPower += power;
        lfCount++;
      }
      if (freq >= hfMin && freq <= hfMax) {
        hfPower += power;
        hfCount++;
      }
    }
    
    lfPower = lfCount > 0 ? lfPower / lfCount : 0;
    hfPower = hfCount > 0 ? hfPower / hfCount : 0;
    double lfhfRatio = hfPower > 0 ? lfPower / hfPower : 0;
    
    return {
      'lf_power': lfPower,
      'hf_power': hfPower,
      'lf_hf_ratio': lfhfRatio,
    };
  }
  
  static double _lombPower(List<double> time, List<double> values, double freq) {
    double omega = 2 * pi * freq;
    double tau = atan2(
      _sum(values.map((v, i) => sin(2 * omega * time[i])).toList()),
      _sum(values.map((v, i) => cos(2 * omega * time[i])).toList())
    ) / (2 * omega);
    
    double ct = cos(omega * (time[0] - tau));
    double st = sin(omega * (time[0] - tau));
    
    double yc = 0, ys = 0, cc = 0, ss = 0, cs = 0;
    
    for (int i = 0; i < time.length; i++) {
      double c = cos(omega * (time[i] - tau));
      double s = sin(omega * (time[i] - tau));
      yc += values[i] * c;
      ys += values[i] * s;
      cc += c * c;
      ss += s * s;
      cs += c * s;
    }
    
    double d = cc * ss - cs * cs;
    if (d < 1e-10) return 0;
    
    return 0.5 * (
      (yc * yc * ss + ys * ys * cc - 2 * yc * ys * cs) / d
    );
  }
  
  static double _sum(List<double> values) => values.reduce((a, b) => a + b);
  
  static double _calculateSD(List<double> values) {
    if (values.isEmpty) return 0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    double variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }
  
  static double _calculateQualityScore(
    List<double> rrIntervals,
    double rmssd,
    double sdnn,
    double lfPower,
    double hfPower,
  ) {
    // Quality based on:
    // 1. Number of intervals (need at least 30 for reliable HRV)
    double nScore = rrIntervals.length >= 30 ? 0.3 : (rrIntervals.length / 30) * 0.3;
    
    // 2. Physiological plausibility of RMSSD (typical range 15-100ms for healthy adults)
    double rmssdScore = (rmssd >= 10 && rmssd <= 150) ? 0.3 : 0.15;
    
    // 3. Frequency domain power (should have some power in both bands)
    double powerScore = (lfPower > 0 && hfPower > 0) ? 0.2 : 0.1;
    
    // 4. Consistency of RR intervals
    double cv = sdnn / (rrIntervals.reduce((a, b) => a + b) / rrIntervals.length);
    double consistencyScore = cv < 0.2 ? 0.2 : max(0, 0.2 - (cv - 0.2));
    
    return (nScore + rmssdScore + powerScore + consistencyScore).clamp(0.0, 1.0);
  }
  
  // Convert frame indices to RR intervals (from your original code, enhanced)
  static List<double> frameIntervalsToRR(List<int> peakIndices, double fps) {
    List<double> rrIntervals = [];
    for (int i = 1; i < peakIndices.length; i++) {
      double intervalMs = (peakIndices[i] - peakIndices[i-1]) / fps * 1000;
      // Filter physiologically impossible intervals
      if (intervalMs >= 300 && intervalMs <= 1500) { // 40-200 BPM
        rrIntervals.add(intervalMs);
      }
    }
    return rrIntervals;
  }
}
