import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart'; // Imports CameraTestApp

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  Future<void> _startTest(BuildContext context) async {
    // Fetch the cameras list right before starting the test view
    final cameras = await availableCameras();
    
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CameraTestApp(cameras: cameras),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Instructions")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.favorite_border, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text("How to take the HRV Test:", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            const Text("1. Ensure your index finger entirely covers the rear camera lens and flash.", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Text("2. Keep perfectly still and hold steady during the full 45-second countdown.", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Text("3. Read the real-time PPG signal on the graph to ensure stability.", style: TextStyle(fontSize: 16)),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _startTest(context),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green),
              child: const Text("I'm Ready, Start Test", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}