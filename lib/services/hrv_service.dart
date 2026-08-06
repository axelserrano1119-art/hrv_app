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
        
    if (milliseconds >= 300 &&
        milliseconds <= 2000) {

      rrIntervals.add(milliseconds);

    }
  }


  if (rrIntervals.length < 5) {
    return [];
  }


  // Remove RR artifacts
  List<double> cleanIntervals = [];

  for(double rr in rrIntervals){

    // physiological limits
    if(rr < 500 || rr > 1400){
      continue;
    }


    // first interval accepted
    if(cleanIntervals.isEmpty){
      cleanIntervals.add(rr);
      continue;
    }


    // median-based artifact rejection
    List<double> temp =
        List.from(cleanIntervals)..sort();


    double median =
        temp[temp.length ~/ 2];


    double difference =
        ((rr - median).abs()) / median;


    // reject sudden beat changes
    if(difference > 0.15){
      continue;
    }


    cleanIntervals.add(rr);
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
