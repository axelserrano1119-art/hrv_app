import 'dart:math';

class StatisticsService {

  double mean(List<double> values) {
    if (values.isEmpty) return 0;

    return values.reduce((a,b)=>a+b)/values.length;
  }

  double standardDeviation(List<double> values){

    if(values.length<2) return 0;

    final avg = mean(values);

    final variance = values
        .map((x)=>pow(x-avg,2))
        .reduce((a,b)=>a+b)
        /(values.length-1);

    return sqrt(variance);
  }

  double zScore(
      double value,
      double mean,
      double sd){

    if(sd==0) return 0;

    return (value-mean)/sd;
  }

  //----------------------------------------
  // New
  //----------------------------------------

  double movingAverage(List<double> values){

    if(values.isEmpty) return 0;

    return mean(values);
  }

  double trimmedMean(List<double> values){

    if(values.isEmpty) return 0;

    List<double> sorted=List.from(values);

    sorted.sort();

    if(sorted.length>5){

      int remove=(sorted.length*0.2).floor();

      sorted=sorted.sublist(
          remove,
          sorted.length-remove);
    }

    return mean(sorted);
  }
}