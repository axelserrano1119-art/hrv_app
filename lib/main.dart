// Please keep this version as the backend of the code as it is currently being tested for accuracy 
// Try implementing a UI overlay that does not interfere with this original PPG code 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:fl_chart/fl_chart.dart'; 
import 'package:camera/camera.dart';
import 'models/measurement.dart';
import 'dart:math';

import 'services/hrv_service.dart';
import 'services/statistics_service.dart';
import 'services/rgb_extractor.dart';
import 'login_page.dart';
import 'services/measurement_storage.dart';
import 'pages/history_page.dart';
import 'widgets/latest_measurement_card.dart';
import 'services/measurement_events.dart';
import 'widgets/history_dashboard.dart';
import 'pages/results_page.dart';
import 'services/session.dart';
import 'models/wellness_data.dart';
import 'models/bio_factor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final cameras = await availableCameras();

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: const LoginPage(),
    ),
  );
}

class CameraTestApp extends StatefulWidget {

 final List<CameraDescription> cameras;

 final String? userId;
 final String? userName;
 final bool isAdmin;
 final WellnessData? wellness;
 final List<BioFactor> bioFactors;


 const CameraTestApp({

 super.key,

 required this.cameras,

 this.userId,

 this.userName,

 this.isAdmin = false,

 this.wellness, 

 this.bioFactors = const [],

 });





 @override
 _CameraTestAppState createState() => _CameraTestAppState();
}




class _CameraTestAppState extends State<CameraTestApp> {

 final HrvService hrvService = HrvService();
 double _lastHRV = 0;
 final StatisticsService statisticsService =
    StatisticsService();

 String? get currentUserId =>
    widget.userId;


 String? get currentUserName =>
    widget.userName;

 CameraController? _controller;
 bool _isRecording = false;
 int _secondsRemaining = 45;
 Timer? _countdownTimer;




 // Real-time RGB state variables
 List<double> _redSignalHistory = [];
List<double> _greenSignalHistory = [];
List<double> _blueSignalHistory = [];
List<double> _filteredSignalHistory = [];
List<int> _peakIndices = [];
List<int> _completedPeakIndices = [];
List<double> _bpmHistory = [];
List<double> _finalBpmHistory = [];
double _signalRange = 0;
double _lastValley = 0;
double _currentBPM = 0;
double _measuredFPS = 25;
double _previousFiltered = 0.0;
int _totalSamples = 0;
 bool _isProcessingFrame = false;
int _frameCounter = 0;
DateTime _fpsStart = DateTime.now();
DateTime? _lastBeatTime;
bool _fingerDetected = false;
bool _signalGood = false;
String _statusMessage = "Place finger over camera";


  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }


 Future<void> _initializeCamera() async {
  // Get ALL rear cameras
  final backCameras = widget.cameras.where(
    (camera) => camera.lensDirection == CameraLensDirection.back,
  ).toList();

  debugPrint("============== CAMERAS ==============");
for (var cam in widget.cameras) {
  debugPrint(
    "Name: ${cam.name} "
    "Direction: ${cam.lensDirection} "
    "Orientation: ${cam.sensorOrientation}",
  );
}
debugPrint("=====================================");

  if (backCameras.isEmpty) {
  debugPrint("No rear cameras found");
  return;
}

final selectedCamera =
    backCameras.length > 1
        ? backCameras[1]
        : backCameras.first;
  _controller = CameraController(
    selectedCamera,
    ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.bgra8888,
  );

  try {
    await _controller!.initialize();

    // Set zoom level to 1.0 
    await _controller!.setZoomLevel(1.0);

    // Lock exposure for stable PPG signal
    // await _controller!.setExposureMode(ExposureMode.locked);

    // await _controller!.setExposureOffset(-2.0);

    // Lock focus to reduce pulsing
    await _controller!.setFocusMode(FocusMode.locked);

    debugPrint("Using camera: ${selectedCamera.name}");
debugPrint(
  "Selected rear camera index: ${backCameras.indexOf(selectedCamera)}"
);

    if (mounted) {
      setState(() {});
    }
  } catch (e) {
    debugPrint("Camera initialization error: $e");
  }
}

 Future<void> _runTimedSequence() async {
 debugPrint("===== RUN TIMED SEQUENCE STARTED =====");

 if (_controller == null || !_controller!.value.isInitialized) return;
   try {
     // 1. Enable Torch (Flash)
     await _controller!.setFlashMode(FlashMode.torch);
debugPrint("Flash mode: ${_controller?.value.flashMode}");
   
     // Clear history from any previous tests
     _redSignalHistory.clear();
_greenSignalHistory.clear();
_blueSignalHistory.clear();
_finalBpmHistory.clear();
_bpmHistory.clear();


   
     setState(() {
       _isRecording = true;
       _secondsRemaining = 45;
     });




     // 2. Start Real-Time RGB Processing Frame Stream
     _startRGBStream();
   
     // 3. Start a visual countdown for the user
     _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
       if (_secondsRemaining > 1) {
         setState(() => _secondsRemaining--);
       } else {
         _countdownTimer?.cancel();
         _stopRGBSequence();
       }
     });
   } catch (e) {
     debugPrint("Recording Error: $e");
   }
 }




   void _startRGBStream() {


 debugPrint("STARTING IMAGE STREAM");
// Reset previous session
_greenSignalHistory.clear();
_filteredSignalHistory.clear();
_peakIndices.clear();
_completedPeakIndices.clear();
_currentBPM = 0;


 _controller!.startImageStream((CameraImage image) {

  if (_isProcessingFrame) return;

  _isProcessingFrame = true;


  try {

    final rgb = RGBExtractor.extract(image);


    _handleNewSignalValues(
      rgb.red,
      rgb.green,
      rgb.blue,
    );


  } catch(e){

    debugPrint(
      "Frame parsing error: $e"
    );

  }


  finally {

    _isProcessingFrame = false;

  }

});
   }

void _handleNewSignalValues(
 double redValue,
 double greenValue,
 double blueValue,
) {


 debugPrint(
   "R: ${redValue.toStringAsFixed(2)} | "
   "G: ${greenValue.toStringAsFixed(2)} | "
   "B: ${blueValue.toStringAsFixed(2)}"
 );




double brightness =
   (redValue + greenValue + blueValue) / 3;
bool fingerDetected =
    redValue > 40 &&
    brightness > 30 &&
    redValue > greenValue;
debugPrint(
 "FingerCheck "
 "R=${redValue.toStringAsFixed(1)} "
 "G=${greenValue.toStringAsFixed(1)} "
 "B=${blueValue.toStringAsFixed(1)} "
 "Brightness=${brightness.toStringAsFixed(1)} "
 "Detected=$fingerDetected"
);
if (!fingerDetected) {


 if (_fingerDetected) {


   _peakIndices.clear();
   _bpmHistory.clear();
  
   _filteredSignalHistory.clear();
   _greenSignalHistory.clear();
    _previousFiltered = 0;


   setState(() {
     _fingerDetected = false;
     _signalGood = false;
     _statusMessage = "Place finger over camera";
     _currentBPM = 0;
   });
 }


 debugPrint("NO FINGER");
 return;
}


if (!_fingerDetected) {
 setState(() {
   _fingerDetected = true;
   _statusMessage = "Finger detected";
 });
}


debugPrint("VALID FRAME");

_totalSamples++; 

// Store sample immediately
_greenSignalHistory.add(greenValue);
_redSignalHistory.add(redValue);
_blueSignalHistory.add(blueValue);


// Keep history bounded
if (_greenSignalHistory.length > 300) {
 _greenSignalHistory.removeAt(0);
 _redSignalHistory.removeAt(0);
 _blueSignalHistory.removeAt(0);
}


_frameCounter++;


if (DateTime.now().difference(_fpsStart).inSeconds >= 1) {
 final elapsed =
    DateTime.now()
        .difference(_fpsStart)
        .inMilliseconds;

_measuredFPS =
    elapsed > 0
        ? (_frameCounter * 1000) / elapsed
        : _measuredFPS;


debugPrint(
 "FPS=${_measuredFPS.toStringAsFixed(2)}"
);


_frameCounter = 0;
_fpsStart = DateTime.now();
}
debugPrint(
 "Samples: ${_greenSignalHistory.length}"
);
if (_greenSignalHistory.length < 60) {


 setState(() {
   _statusMessage = "Stabilizing signal...";
 });


 return;
}
int baselineWindow =
   _greenSignalHistory.length < 45
       ? _greenSignalHistory.length
       : 45;


  double baseline =
   _greenSignalHistory
           .sublist(
             _greenSignalHistory.length - baselineWindow,
           )
           .reduce((a, b) => a + b) /
       baselineWindow;


double filtered =
   (greenValue - baseline) / baseline;
   filtered = filtered.clamp(-1.0, 1.0);

const double alpha = 0.25;
double finalFiltered =
 alpha * filtered +
 (1 - alpha) * _previousFiltered;
//if (finalFiltered.abs() < 0.005) {
// finalFiltered = 0;
//}
// if (finalFiltered.abs() < 0.05) {
//  finalFiltered = 0;
// }
debugPrint(
 "DEBUG filtered=${filtered.toStringAsFixed(4)} "
 "prev=${_previousFiltered.toStringAsFixed(4)} "
 "final=${finalFiltered.toStringAsFixed(4)}"
);
_previousFiltered = finalFiltered;
_filteredSignalHistory.add(finalFiltered);
if (_filteredSignalHistory.length > 120) {
 _filteredSignalHistory.removeAt(0);
}
if (_filteredSignalHistory.length >= 60) {


 double minValue =
     _filteredSignalHistory.reduce(
         (a, b) => a < b ? a : b);


 double maxValue =
     _filteredSignalHistory.reduce(
         (a, b) => a > b ? a : b);


 _signalRange =
    maxValue - minValue;


 debugPrint(
   "QUALITY range=${_signalRange.toStringAsFixed(3)}"
 );


 if (_signalRange < 0.04) {


   _signalGood = false;


   setState(() {
     _statusMessage =
         "Adjust finger placement";
     _currentBPM = 0;
   });


   return;
 }


 _signalGood = true;


 setState(() {
   _statusMessage = "Measuring...";
 });
}
debugPrint(
 "baseline=${baseline.toStringAsFixed(2)} "
 "filtered=${finalFiltered.toStringAsFixed(4)}"
);
// Small smoothing window
debugPrint(
 "SignalRange raw=${greenValue.toStringAsFixed(2)} "
 "filtered=${finalFiltered.toStringAsFixed(3)}"
);
debugPrint(
 "finalFiltered=${_filteredSignalHistory.last.toStringAsFixed(4)}"
);
/*
if (_filteredSignalHistory.length > 5) {
 double smoothed =
     _filteredSignalHistory
             .sublist(_filteredSignalHistory.length - 5)
             .reduce((a, b) => a + b) /
         5;


 _filteredSignalHistory[
     _filteredSignalHistory.length - 1] = smoothed;
}
*/
if (_filteredSignalHistory.length > 10) {


 int i = _filteredSignalHistory.length - 2;


 double prev = _filteredSignalHistory[i - 1];
double current = _filteredSignalHistory[i];
double next = _filteredSignalHistory[i + 1];


debugPrint(
 "PeakCheck "
 "prev=${prev.toStringAsFixed(3)} "
 "curr=${current.toStringAsFixed(3)} "
 "next=${next.toStringAsFixed(3)}"
);


debugPrint(
 "SignalDirection=${next > current ? 'UP' : 'DOWN'}"
);
if (
   current <= prev &&
   current <= next
) {

   _lastValley = current;

   debugPrint(
      "VALLEY candidate at $i "
      "value=${current.toStringAsFixed(3)}"
   );

}

// Local maximum
int sampleIndex = _totalSamples;
debugPrint(
  "sampleIndex=$sampleIndex "
  "historySize=${_greenSignalHistory.length}"
);

List<double> recentWindow =
   _filteredSignalHistory.length > 60
       ? _filteredSignalHistory.sublist(
           _filteredSignalHistory.length - 60)
       : _filteredSignalHistory;


// use mean instead of max


double dynamicThreshold = 0;


if (recentWindow.length < 5) {
  dynamicThreshold = 0;
} else {


double mean = recentWindow.reduce((a, b) => a + b) / recentWindow.length;


// estimate variability
double variance = recentWindow
   .map((e) => (e - mean) * (e - mean))
   .reduce((a, b) => a + b) / recentWindow.length;


double std = sqrt(variance);


// NEW stable threshold
dynamicThreshold = mean + 0.25 * std;
}
double prominence =
    current - _lastValley;
bool isPeak =
    current > prev &&
    current > next;
bool isValley =
   current < prev &&
   current < next;


if (
   isPeak &&
   current.abs() > dynamicThreshold * 0.15
) {

  debugPrint(
  "Threshold=${dynamicThreshold.toStringAsFixed(3)} "
  "Current=${current.toStringAsFixed(3)} "
  "Prominence=${prominence.toStringAsFixed(3)} "
  "SignalRange=${_signalRange.toStringAsFixed(3)}"
);


debugPrint(
 "PEAK value=${current.toStringAsFixed(3)}"
);

double peakStrength = current - _lastValley;

debugPrint(
  "PeakStrength=${peakStrength.toStringAsFixed(3)} "
  "Valley=${_lastValley.toStringAsFixed(3)}"
);

debugPrint(
 "PEAK candidate at $sampleIndex value=${current.toStringAsFixed(3)}"
);




debugPrint(
 "Peak spacing check: "
 "currentIndex=$sampleIndex "
 "lastPeak=${_peakIndices.isEmpty ? -1 : _peakIndices.last} "
 "difference=${_peakIndices.isEmpty ? -1 : sampleIndex - _peakIndices.last}"
);


   // Prevent double-counting nearby peaks
   const double minBeatSeconds = 0.65;


   bool validSpacing = true;

   if (_peakIndices.isNotEmpty) {

  int frameGap =
      sampleIndex - _peakIndices.last;

  double seconds =
      frameGap / _measuredFPS;

  double bpmEstimate =
      60 / seconds;


  if (bpmEstimate > 180) {
    validSpacing = false;
  }

}

bool acceptPeak = true;

if (_peakIndices.isNotEmpty) {

  int spacing =
      sampleIndex - _peakIndices.last;

const double minBeatSeconds = 0.75;

if (spacing < (_measuredFPS * minBeatSeconds)) {

    debugPrint(
      "Rejected peak spacing=$spacing "
      "required=${(_measuredFPS * minBeatSeconds).round()}"
    );

    acceptPeak = false;
}
}

if (validSpacing && acceptPeak) {

  _peakIndices.add(sampleIndex);

  _completedPeakIndices.add(sampleIndex);

  debugPrint(
      "Accepted Peak #${_completedPeakIndices.length} "
      "frame=$sampleIndex"
  );

  _lastBeatTime = DateTime.now();

} else {

  debugPrint(
    "Peak rejected permanently"
  );

  return;
}


debugPrint("PEAK COUNT = ${_peakIndices.length}");
debugPrint("BPM HISTORY = $_bpmHistory");


debugPrint(
 "PEAK ACCEPTED "
 "index=$sampleIndex "
 "value=${current.toStringAsFixed(3)}"
);


DateTime now = DateTime.now();


debugPrint(
 "BEAT DETECTED at $sampleIndex "
 "value=${current.toStringAsFixed(3)} "
 "time=$now"
);


debugPrint(
 "Peak count = ${_peakIndices.length}"
);
while (_peakIndices.length > 120) {
 _peakIndices.removeAt(0);
}


if (_peakIndices.length >= 5) {

  debugPrint("PeakCount=${_peakIndices.length}");

  double averageFramesBetweenBeats = 0;

  for (int j = 1; j < _peakIndices.length; j++) {
    averageFramesBetweenBeats +=
        (_peakIndices[j] - _peakIndices[j - 1]);
  }

  averageFramesBetweenBeats /=
      (_peakIndices.length - 1);

  double bpm =
      60 * _measuredFPS /
      averageFramesBetweenBeats;

  if (bpm >= 40 &&
      bpm <= 180 &&
      _peakIndices.length > 20) {

    // keep only last 3 BPM values
    _bpmHistory.add(bpm);

    if (_bpmHistory.length > 3) {
      _bpmHistory.removeAt(0);
    }

    // 3-beat moving average
    final smoothBPM =
        _bpmHistory.reduce((a, b) => a + b) /
        _bpmHistory.length;

    _currentBPM = smoothBPM;

    _finalBpmHistory.add(smoothBPM);

    debugPrint(
      "Intervals: "
      "${averageFramesBetweenBeats.toStringAsFixed(2)} "
      "BPM=${smoothBPM.toStringAsFixed(1)}",
    );

    debugPrint(
      "UI BPM UPDATED: ${_currentBPM.toStringAsFixed(0)}",
    );

    if (mounted) {
      setState(() {});
    }
  }
}
}
}
if (_filteredSignalHistory.length > 300) {
 _filteredSignalHistory.removeAt(0);
}
setState(() {});
}
double calculateFinalBPM(List<double> values) {

  if (values.isEmpty) {
    return 0;
  }

  // Copy and sort BPM values
  List<double> sorted = List.from(values);
  sorted.sort();


  // Remove 20% lowest and highest values
  // (removes spikes like 10 BPM or 190 BPM)
  int removeCount = (sorted.length * 0.10).floor();


  if (sorted.length > 5) {
    sorted = sorted.sublist(
      removeCount,
      sorted.length - removeCount,
    );
  }


  // Average remaining stable BPM values
  double average =
      sorted.reduce((a, b) => a + b) /
      sorted.length;


  return average;
}

 Future<void> _stopRGBSequence() async {

  await _controller!.stopImageStream();

  await _controller!.setFlashMode(FlashMode.off);


  // Convert stored beats into RR intervals
  debugPrint("Accepted peaks: ${_completedPeakIndices.length}");
  debugPrint("Peak indices: $_completedPeakIndices");

  final rrIntervals =
    hrvService.frameIntervalsToRR(
      _completedPeakIndices,
      _measuredFPS,
    );

  debugPrint("RR interval count: ${rrIntervals.length}");
  debugPrint("RR intervals: $rrIntervals");


  // Calculate HRV
  final hrv =
      hrvService.calculateRMSSD(rrIntervals);


  debugPrint(
    "===== MEASUREMENT COMPLETE ====="
  );

  double finalBPM =
  statisticsService.trimmedMean(
    _finalBpmHistory);

// ==========================================
// DETERMINE MEASUREMENT OWNER
// ==========================================
//
// IMPORTANT:
// If an admin is taking their own measurement,
// ALWAYS use the currently logged-in admin's
// Session identity.
//
// Do NOT use the selected student from the
// admin dashboard.
//
// For normal student tests, use the userId
// passed into CameraTestApp.

late final String measurementUserId;
late final String measurementUserName;

if (widget.isAdmin) {
  // ==========================================
  // ADMIN'S OWN MEASUREMENT
  // ==========================================

  final admin = Session.currentUser;

  if (admin == null) {
    debugPrint(
      "ERROR: No logged-in admin found.",
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Unable to save admin measurement: "
            "no logged-in admin found.",
          ),
        ),
      );
    }

    return;
  }

  measurementUserId = admin.id;
  measurementUserName = admin.name;

  debugPrint(
    "================================",
  );
  debugPrint(
    "ADMIN MEASUREMENT",
  );
  debugPrint(
    "Admin ID: $measurementUserId",
  );
  debugPrint(
    "Admin Name: $measurementUserName",
  );
  debugPrint(
    "================================",
  );
} else {
  // ==========================================
  // NORMAL STUDENT MEASUREMENT
  // ==========================================

  measurementUserId =
      widget.userId ??
      Session.currentUser?.id ??
      '';

  measurementUserName =
      widget.userName ??
      Session.currentUser?.name ??
      '';

  debugPrint(
    "================================",
  );
  debugPrint(
    "STUDENT MEASUREMENT",
  );
  debugPrint(
    "Student ID: $measurementUserId",
  );
  debugPrint(
    "Student Name: $measurementUserName",
  );
  debugPrint(
    "================================",
  );
}


// ==========================================
// CREATE MEASUREMENT
// ==========================================

final Measurement measurement = Measurement(
  userId: measurementUserId,
  userName: measurementUserName,
  timestamp: DateTime.now(),
  heartRate: finalBPM,
  hrvRmssd: hrv,
  rrIntervals: rrIntervals,
  bpmHistory: _finalBpmHistory,
  durationSeconds: 45,
  valid: true,

  // Admin measurements should not inherit
  // a student's wellness information.
  wellness:
      widget.isAdmin
          ? null
          : widget.wellness,

  bioFactors:
      widget.isAdmin
          ? const []
          : widget.bioFactors,
);

  await MeasurementStorage()
      .saveMeasurement(measurement);
  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ResultsPage(
      measurement: measurement,
    ),
  ),
);

  MeasurementEvents.measurementSaved.value++;
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text(
      "Measurement saved successfully",
    ),
  ),
);

  _currentBPM = finalBPM; 


  debugPrint(
    "FINAL BPM: ${finalBPM.toStringAsFixed(1)}"
  );

  debugPrint(
    "RAW BPM VALUES: $_finalBpmHistory"
  );

  debugPrint(
    "RR intervals: ${rrIntervals.length}"
  );

  debugPrint(
    "HRV RMSSD: ${hrv.toStringAsFixed(2)} ms"
  );


  setState(() {

    _lastHRV = hrv;

    _currentBPM = finalBPM;

    _isRecording = false;
    _secondsRemaining = 45;

  });


  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        "HRV: ${hrv.toStringAsFixed(1)} ms"
      ),
    ),
  );
}




 @override
Widget build(BuildContext context) {
  if (_controller == null || !_controller!.value.isInitialized) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text("Torch Test App"),
    ),

    body: Stack(
      alignment: Alignment.center,

      children: [

        CameraPreview(_controller!),


        Positioned(
          top: 80,
          left: 20,
          right: 20,

          child: Card(
            color: Colors.black87,

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [

                  Text(
                    "${_currentBPM.toStringAsFixed(0)} BPM",

                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),


                  const SizedBox(height: 8),


                  Text(
                    _statusMessage,

                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),


                  const SizedBox(height: 8),


                  LinearProgressIndicator(
                    value: _secondsRemaining / 45,
                  ),


                  const SizedBox(height: 8),


                  Text(
                    "HRV ${_lastHRV.toStringAsFixed(1)} ms",

                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),



        Positioned(
          top: 150,

          child: Text(

            _bpmHistory.length < 3
                ? "Stabilizing..."
                : "Stable",

            style: TextStyle(

              color: _bpmHistory.length < 3
                  ? Colors.orange
                  : Colors.green,

              fontSize: 18,

            ),
          ),
        ),



        Positioned(
          top: 300,
          left: 20,
          right: 20,

          child: LatestMeasurementCard(),

        ),




        Positioned(
          bottom: 140,
          left: 10,
          right: 10,

          child: SizedBox(

            height: 200,

            child: LineChart(

              LineChartData(

                minY: -0.35,
                maxY: 0.35,

                titlesData:
                    FlTitlesData(show: false),

                borderData:
                    FlBorderData(show: false),

                gridData:
                    FlGridData(show: false),


                lineBarsData: [


                  LineChartBarData(

                    spots: List.generate(

                      _redSignalHistory.length,

                      (i) => FlSpot(

                        i.toDouble(),

                        _redSignalHistory[i],

                      ),

                    ),

                    isCurved: true,

                    dotData:
                        FlDotData(show: false),

                  ),



                  LineChartBarData(

                    spots: List.generate(

                      _filteredSignalHistory.length,

                      (i) => FlSpot(

                        i.toDouble(),

                        _filteredSignalHistory[i],

                      ),

                    ),

                    isCurved: true,

                    dotData:
                        FlDotData(show: false),

                  ),



                  LineChartBarData(

                    spots: List.generate(

                      _blueSignalHistory.length,

                      (i) => FlSpot(

                        i.toDouble(),

                        _blueSignalHistory[i],

                      ),

                    ),

                    isCurved: true,

                    dotData:
                        FlDotData(show: false),

                  ),

                ],
              ),
            ),
          ),
        ),



        Column(

          mainAxisAlignment:
              MainAxisAlignment.end,

          children: [

            if (_isRecording)

              Text(

                "REC: $_secondsRemaining",

                style: const TextStyle(

                  color: Colors.red,

                  fontSize: 32,

                  fontWeight:
                      FontWeight.bold,

                ),

              ),


            const SizedBox(height: 20),



            Padding(

              padding:
                  const EdgeInsets.only(bottom: 40),


              child: FloatingActionButton.extended(

                onPressed:
                    _isRecording
                        ? null
                        : _runTimedSequence,


                backgroundColor:
                    _isRecording
                        ? Colors.grey
                        : Colors.blue,


                label: Text(

                  _isRecording
                      ? "Capturing..."
                      : "Start Test",

                ),


                icon:
                    const Icon(Icons.videocam),

              ),

            ),

          ],

        ),

      ],

    ),

  );
}


 @override
 void dispose() {
   _controller?.dispose();
   _countdownTimer?.cancel();
   super.dispose();
 }
}
