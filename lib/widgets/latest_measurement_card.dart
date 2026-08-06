import 'package:flutter/material.dart';

import '../services/measurement_storage.dart';
import '../services/measurement_events.dart';
import '../models/measurement.dart';


class LatestMeasurementCard extends StatefulWidget {

  const LatestMeasurementCard({
    super.key,
  });


  @override
  State<LatestMeasurementCard> createState() =>
      _LatestMeasurementCardState();

}



class _LatestMeasurementCardState
    extends State<LatestMeasurementCard> {


  final MeasurementStorage storage =
      MeasurementStorage();


  Measurement? latest;

  int totalTests = 0;



  @override
  void initState() {

    super.initState();

    _loadData();


    MeasurementEvents.measurementSaved
        .addListener(
          _loadData,
        );

  }





  Future<void> _loadData() async {


    final latestMeasurement =
        await storage.getLatestMeasurement();


    final allMeasurements =
        await storage.loadMeasurements();



    if (!mounted) return;



    setState(() {

      latest = latestMeasurement;

      totalTests =
          allMeasurements.length;

    });


  }





  @override
  Widget build(BuildContext context) {


    if (latest == null) {

      return const SizedBox();

    }



    return Card(

      color: Colors.black87,


      child: Padding(

        padding:
            const EdgeInsets.all(16),


        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,


          children: [


            const Text(

              "Latest Saved Result",

              style: TextStyle(
                fontSize:20,
                fontWeight:
                    FontWeight.bold,
              ),

            ),



            const SizedBox(
              height:10,
            ),



            Text(
              "❤️ HR: "
              "${latest!.heartRate.toStringAsFixed(1)} BPM",
            ),



            Text(
              "🫀 HRV: "
              "${latest!.hrvRmssd.toStringAsFixed(1)} ms",
            ),



            Text(
              "Tests Completed: $totalTests",
            ),


          ],

        ),

      ),

    );

  }





  @override
  void dispose() {


    MeasurementEvents.measurementSaved
        .removeListener(
          _loadData,
        );


    super.dispose();

  }


}