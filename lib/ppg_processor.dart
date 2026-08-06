import 'dart:math';
import 'package:flutter/material.dart';

class PpgState {
  final bool fingerDetected;
  final bool flashStable;
  final bool exposureStable;
  final bool lowMovement;
  final double signalQuality;
  final int currentBPM;
  final bool isTestReady;

  PpgState({
    required this.fingerDetected,
    required this.flashStable,
    required this.exposureStable,
    required this.lowMovement,
    required this.signalQuality,
    required this.currentBPM,
    required this.isTestReady,
  });
}

class PpgProcessor {
  // Your existing variables shifted here
  final List<double> _recentWindow = [];
  final List<int> _peakIndices = [];
  DateTime? _lastBeatTime;
  
  // New stabilization metrics
  double _prevBrightness = 0.0;
  int _stableFramesCount = 0;

  // Callback to update the UI when state changes
  final Function(PpgState) onStateChanged;

  PpgProcessor({required this.onStateChanged});

  void processFrame(double r, double g, double b, int sampleIndex) {
    // 1. Finger Detection Logic
    bool fingerDetected = r > 200 && g < 30; // Your existing logic

    // 2. Flash & Exposure Stability Check
    double brightness = (r + g + b) / 3;
    double brightnessDiff = (brightness - _prevBrightness).abs();
    _prevBrightness = brightness;

    bool exposureStable = brightnessDiff < 0.5; // Threshold for flickering
    if (exposureStable && fingerDetected) {
      _stableFramesCount++;
    } else {
      _stableFramesCount = 0;
    }

    bool flashStable = _stableFramesCount > 60; // Stable for ~2-3 seconds

    // 3. Run your signal filtering & peak detection math here...
    // [Your filter and peak math from previous steps goes here]

    int calculatedBpm = 62; // Placeholder for your actual running BPM calculation
    double qualityScore = 0.85; // Placeholder based on your signal range validation
    bool lowMovement = brightnessDiff < 1.5; // Quick proxy for macro hand shakes

    // 4. Determine readiness
    bool isTestReady = fingerDetected && flashStable && exposureStable && lowMovement && (qualityScore > 0.70);

    // 5. Notify the main UI
    onStateChanged(
      PpgState(
        fingerDetected: fingerDetected,
        flashStable: flashStable,
        exposureStable: exposureStable,
        lowMovement: lowMovement,
        signalQuality: qualityScore,
        currentBPM: calculatedBpm,
        isTestReady: isTestReady,
      ),
    );
  }
}