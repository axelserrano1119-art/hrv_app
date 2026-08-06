import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/measurement.dart';



class HrvChart extends StatelessWidget {


  final List<Measurement> measurements;



  const HrvChart({

    super.key,

    required this.measurements,

  });





  @override
  Widget build(BuildContext context) {


    if(measurements.isEmpty){

      return const SizedBox();

    }



    final spots =
        List.generate(
          measurements.length,
          (index){

            return FlSpot(

              index.toDouble(),

              measurements[index].hrvRmssd,

            );

          },

        );




    return Card(

      color:
          Colors.black87,


      child:
      Padding(

        padding:
            const EdgeInsets.all(16),


        child:
        Column(

          children:[


            const Text(

              "HRV History",

              style:
              TextStyle(

                fontSize:20,

                fontWeight:
                    FontWeight.bold,

              ),

            ),



            SizedBox(

              height:200,


              child:
              LineChart(

                LineChartData(

                  lineBarsData:[


                    LineChartBarData(

                      spots:spots,

                      isCurved:true,

                      dotData:
                      FlDotData(
                        show:false,
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

}