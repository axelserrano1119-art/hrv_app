import 'package:flutter/material.dart';
import '../services/readiness_checker.dart';

class ReadinessOverlay extends StatelessWidget {
  final ReadinessChecker readiness;

  const ReadinessOverlay({
    super.key,
    required this.readiness,
  });

  Widget _item(String label, bool ok) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          color: ok ? Colors.green : Colors.white70,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: ok ? Colors.green : Colors.white70,
            fontSize: 14,
            fontWeight: ok ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 220,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _item("Finger detected", readiness.fingerDetected),
            _item("Flash stable", readiness.flashStable),
            _item("Exposure stable", readiness.exposureStable),
            _item("Pulse waveform", readiness.waveformDetected),
            _item("Low movement", readiness.movementLow),
            _item("Signal quality", readiness.signalQualityGood),

            const SizedBox(height: 8),

            Text(
              readiness.ready ? "READY" : "NOT READY",
              style: TextStyle(
                color: readiness.ready ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}