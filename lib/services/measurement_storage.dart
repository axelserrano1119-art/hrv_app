import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/measurement.dart';


class MeasurementStorage {

  static const String fileName =
      "measurements.json";



  Future<File> _getFile() async {

    final directory =
        await getApplicationDocumentsDirectory();

    return File(
      "${directory.path}/$fileName",
    );

  }





  Future<void> saveMeasurement(
      Measurement measurement) async {


    final file =
        await _getFile();


    List<Measurement> measurements =
        await loadMeasurements();



    measurements.add(measurement);



    debugPrint(
      "Total saved measurements: "
      "${measurements.length}",
    );



    final jsonList =
        measurements
            .map((e) => e.toJson())
            .toList();



    await file.writeAsString(
      jsonEncode(jsonList),
    );


    debugPrint(
      "Measurement saved successfully",
    );

  }






  Future<void> clearMeasurements() async {

    final file =
        await _getFile();


    if (await file.exists()) {

      await file.delete();

      debugPrint(
        "All measurements cleared",
      );

    }

  }






  Future<List<Measurement>>
      loadMeasurements() async {


    final file =
        await _getFile();



    if (!await file.exists()) {

      return [];

    }



    final contents =
        await file.readAsString();



    if (contents.isEmpty) {

      return [];

    }



    final List decoded =
        jsonDecode(contents);



    return decoded
        .map(
          (item) =>
              Measurement.fromJson(item),
        )
        .toList();

  }






  Future<Measurement?>
      getLatestMeasurement() async {


    final measurements =
        await loadMeasurements();



    if (measurements.isEmpty) {

      return null;

    }



    measurements.sort(
      (a,b) =>
          b.timestamp
          .compareTo(a.timestamp),
    );



    return measurements.first;

  }







  Future<double>
      getAverageHeartRate() async {


    final measurements =
        await loadMeasurements();



    if (measurements.isEmpty) {

      return 0;

    }



    double total = 0;


    for (var m in measurements) {

      total += m.heartRate;

    }



    return total / measurements.length;

  }








  Future<double>
      getAverageHRV() async {


    final measurements =
        await loadMeasurements();



    if (measurements.isEmpty) {

      return 0;

    }



    double total = 0;


    for (var m in measurements) {

      total += m.hrvRmssd;

    }



    return total / measurements.length;

  }






  Future<void>
      deleteAllMeasurements() async {


    await clearMeasurements();

  }


}