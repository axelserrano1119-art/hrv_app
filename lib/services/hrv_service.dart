import 'dart:math';
import 'package:flutter/foundation.dart';

class HrvService {

  List<double> frameIntervalsToRR(
    List<int> peakIndices,
    double fps,
) {

  if (peakIndices.length < 2) {
    return [];
  }

  List<double> rrIntervals = [];


  for (int i = 1; i < peakIndices.length; i++) {

    double frameDifference =
        (peakIndices[i] - peakIndices[i - 1])
            .toDouble();


    double seconds =
        frameDifference / fps;


    double milliseconds =
        seconds * 1000;


    // Fix #1:
    // Reject impossible human RR intervals
    if (milliseconds >= 300 &&
        milliseconds <= 2000) {

      rrIntervals.add(milliseconds);

    }
  }


  // Fix #2:
  // Remove sudden beat-to-beat artifacts

  List<double> cleanIntervals = [];

  for (double rr in rrIntervals) {

  if (rr >= 400 && rr <= 1500) {
    cleanIntervals.add(rr);
  }
}
debugPrint(
  "HRV CLEAN RR: ${cleanIntervals.length}"
);

debugPrint(
  "HRV CLEAN VALUES: $cleanIntervals"
);

return cleanIntervals;
}

  double calculateRMSSD(List<double> rrIntervals) {

    if (rrIntervals.length < 2) {
      return 0;
    }

    double sumSquares = 0;

    for (int i = 1; i < rrIntervals.length; i++) {

      double difference =
          rrIntervals[i] - rrIntervals[i - 1];

      sumSquares += difference * difference;
    }


    double meanSquare =
        sumSquares / (rrIntervals.length - 1);


    return sqrt(meanSquare);
  }

}