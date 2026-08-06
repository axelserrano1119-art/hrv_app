import 'package:flutter/material.dart';

import '../services/measurement_storage.dart';
import '../models/measurement.dart';

import 'heart_rate_chart.dart';
import 'hrv_chart.dart';



class HistoryDashboard extends StatefulWidget {

  const HistoryDashboard({
    super.key,
  });



  @override
  State<HistoryDashboard> createState() =>
      _HistoryDashboardState();

}




class _HistoryDashboardState
    extends State<HistoryDashboard>{


  final MeasurementStorage storage =
      MeasurementStorage();


  List<Measurement> measurements = [];



  @override
  void initState(){

    super.initState();

    load();

  }



  Future<void> load() async {


    final data =
        await storage.loadMeasurements();


    if(!mounted)return;


    setState((){

      measurements=data;

    });


  }




  @override
  Widget build(BuildContext context){


    return Column(

      children:[


        HeartRateChart(
          measurements:
              measurements,
        ),


        HrvChart(
          measurements:
              measurements,
        ),


      ],

    );

  }

}