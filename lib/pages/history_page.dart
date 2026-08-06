import 'package:flutter/material.dart';

import '../models/measurement.dart';
import '../services/measurement_storage.dart';


class HistoryPage extends StatefulWidget {

  const HistoryPage({super.key});


  @override
  State<HistoryPage> createState() =>
      _HistoryPageState();
}



class _HistoryPageState extends State<HistoryPage> {

  final MeasurementStorage storage =
      MeasurementStorage();


  List<Measurement> measurements = [];

  bool loading = true;



  @override
  void initState() {
    super.initState();

    _loadMeasurements();
  }



  Future<void> _loadMeasurements() async {

    final data =
        await storage.loadMeasurements();


    // newest first
    data.sort(
      (a,b) =>
          b.timestamp.compareTo(a.timestamp),
    );


    setState(() {

      measurements = data;

      loading = false;

    });
  }




  String _formatDate(DateTime date) {

    return "${date.month}/${date.day}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2,'0')}";

  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Measurement History",
        ),
      ),


      body: loading

          ? const Center(
              child:
              CircularProgressIndicator(),
            )


          : measurements.isEmpty

          ? const Center(

              child: Text(
                "No measurements yet",
                style: TextStyle(
                  fontSize:18,
                ),
              ),

            )


          : RefreshIndicator(

              onRefresh:
                  _loadMeasurements,


              child: ListView.builder(

                padding:
                    const EdgeInsets.all(16),


                itemCount:
                    measurements.length,


                itemBuilder:
                    (context,index){


                  final measurement =
                      measurements[index];



                  return Card(

                    elevation:4,

                    margin:
                        const EdgeInsets.only(
                          bottom:16,
                        ),


                    child: Padding(

                      padding:
                          const EdgeInsets.all(16),


                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,


                        children:[


                          Text(

                            _formatDate(
                              measurement.timestamp,
                            ),

                            style:
                              const TextStyle(
                                fontSize:16,
                                fontWeight:
                                  FontWeight.bold,
                              ),

                          ),



                          const SizedBox(
                            height:12,
                          ),




                          Row(

                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,


                            children:[


                              _metricBox(

                                title:"Heart Rate",

                                value:
                                  "${measurement.heartRate.toStringAsFixed(1)} BPM",

                                icon:
                                  Icons.favorite,

                              ),



                              _metricBox(

                                title:"HRV",

                                value:
                                  "${measurement.hrvRmssd.toStringAsFixed(1)} ms",

                                icon:
                                  Icons.monitor_heart,

                              ),

                            ],

                          ),




                          const SizedBox(
                            height:12,
                          ),



                          Text(

                            "Duration: "
                            "${measurement.durationSeconds}s",

                          ),



                          Text(

                            "Quality: "
                            "${(measurement.qualityScore * 100).toStringAsFixed(0)}%",

                          ),



                          Text(

                            measurement.valid
                                ? "Status: Valid"
                                : "Status: Invalid",

                            style: TextStyle(

                              color:
                              measurement.valid
                                  ? Colors.green
                                  : Colors.red,

                            ),

                          ),


                        ],

                      ),

                    ),

                  );

                },

              ),

            ),

    );

  }






Widget _metricBox({

  required String title,

  required String value,

  required IconData icon,

}){


return Column(

  children:[

    Icon(
      icon,
      size:32,
      color:Colors.red,
    ),


    const SizedBox(
      height:5,
    ),


    Text(
      title,
      style:
        const TextStyle(
          fontSize:14,
        ),
    ),


    Text(

      value,

      style:
        const TextStyle(
          fontSize:18,
          fontWeight:
            FontWeight.bold,
        ),

    ),

  ],

);


}


}