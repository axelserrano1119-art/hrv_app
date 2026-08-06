import 'package:flutter/material.dart';
import 'instructions_page.dart';
import 'pages/history_page.dart';


class AdminDashboard extends StatelessWidget {

  const AdminDashboard({super.key});


  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Admin Portal",
        ),

      ),



      body: Padding(

        padding: const EdgeInsets.all(24),


        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.stretch,


          children: [


            const Text(
              "Admin Dashboard",
              style: TextStyle(
                fontSize:26,
                fontWeight:FontWeight.bold,
              ),
            ),



            const SizedBox(height:30),



            ElevatedButton(

              onPressed: (){


                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const InstructionsPage(),
                  ),
                );


              },

              child: const Text(
                "Run HRV Test",
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
                "View Student Records",
              ),

            ),



          ],

        ),

      ),

    );

  }

}