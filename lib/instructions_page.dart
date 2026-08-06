import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart';

class InstructionsPage extends StatelessWidget {

  final String? userId;
  final String? userName;
  final bool isAdmin;


  const InstructionsPage({
    super.key,
    this.userId,
    this.userName,
    this.isAdmin = false,
  });



  Future<void> _startTest(BuildContext context) async {


    final cameras =
        await availableCameras();



    if(context.mounted){

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(
          builder: (context)=>

              CameraTestApp(

                cameras: cameras,

                userId: userId,

                userName: userName,

                isAdmin: isAdmin,

              ),

        ),

      );

    }

  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar:
          AppBar(
            title:
              Text(
                isAdmin
                ? "Admin Test Instructions"
                : "Test Instructions",
              ),
          ),



      body:
      Padding(

        padding:
            const EdgeInsets.all(24),


        child:
        Column(

          mainAxisAlignment:
              MainAxisAlignment.center,


          crossAxisAlignment:
              CrossAxisAlignment.stretch,


          children:[



            Icon(

              Icons.favorite_border,

              size:80,

              color:
              isAdmin
              ? Colors.purple
              : Colors.red,

            ),



            const SizedBox(height:24),



            Text(

              isAdmin
              ? "Admin HRV Test"
              : "How to take the HRV Test:",


              style:
              const TextStyle(

                fontSize:22,

                fontWeight:
                    FontWeight.bold,

              ),


              textAlign:
                  TextAlign.center,

            ),



            const SizedBox(height:24),




            const Text(
              "1. Ensure your index finger entirely covers the rear camera lens and flash.",
              style:
              TextStyle(fontSize:16),
            ),



            const SizedBox(height:12),




            const Text(
              "2. Keep perfectly still and hold steady during the full 45-second countdown.",
              style:
              TextStyle(fontSize:16),
            ),



            const SizedBox(height:12),




            const Text(
              "3. Read the real-time PPG signal on the graph to ensure stability.",
              style:
              TextStyle(fontSize:16),
            ),




            const Spacer(),




            ElevatedButton(

              onPressed:
                  ()=>_startTest(context),


              style:
              ElevatedButton.styleFrom(

                padding:
                const EdgeInsets.symmetric(
                    vertical:16
                ),


                backgroundColor:

                isAdmin
                ? Colors.purple
                : Colors.green,

              ),



              child:
              Text(

                isAdmin
                ? "Start Admin Test"
                : "I'm Ready, Start Test",


                style:
                const TextStyle(
                    fontSize:18
                ),

              ),

            ),


          ],

        ),

      ),

    );

  }

}