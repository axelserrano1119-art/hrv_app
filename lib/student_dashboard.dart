import 'package:flutter/material.dart';
import 'instructions_page.dart';
import 'pages/history_page.dart';
//import 'pages/wellness_input_page.dart';


class StudentDashboard extends StatelessWidget {

  const StudentDashboard({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Student Portal",
        ),
      ),


      body: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [


            const Text(
              "Student Dashboard",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 30),



            ElevatedButton(

              onPressed: (){

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const InstructionsPage(
                      isAdmin: false,
                    ),
                  ),
                );

              },


              child: const Text(
                "Start HRV Measurement",
              ),

            ),



            const SizedBox(height:20),



            ElevatedButton(

              onPressed: (){

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const HistoryPage(),
                  ),
                );

              },


              child: const Text(
                "View My History",
              ),

            ),


          ],

        ),

      ),

    );

  }

}