import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';


class RGBSample {

  final double red;
  final double green;
  final double blue;

  RGBSample({
    required this.red,
    required this.green,
    required this.blue,
  });

}



class RGBExtractor {


  static RGBSample extract(CameraImage image) {


    switch (image.format.group) {


      case ImageFormatGroup.bgra8888:
        return _extractBGRA(image);


      case ImageFormatGroup.yuv420:
        return _extractYUV(image);


      default:
        throw Exception(
          "Unsupported camera format: ${image.format.group}"
        );

    }

  }




  // ==============================
  // iPhone BGRA8888 extraction
  // ==============================

  static RGBSample _extractBGRA(CameraImage image) {


    final bytes = image.planes[0].bytes;

    final int bytesPerRow =
        image.planes[0].bytesPerRow;



    double totalRed = 0;
    double totalGreen = 0;
    double totalBlue = 0;

    double totalWeight = 0;

    int pixels = 0;



    // Same 100x100 region as original code

    int startX =
        (image.width / 2 - 50).round();

    int startY =
        (image.height / 2 - 50).round();


    int endX =
        (image.width / 2 + 50).round();

    int endY =
        (image.height / 2 + 50).round();




    for(int y = startY; y < endY; y++) {


      for(int x = startX; x < endX; x++) {


        final int pixelIndex =
            y * bytesPerRow + (x * 4);



        if(pixelIndex + 3 >= bytes.length)
          continue;



        // BGRA order

        double blue =
            bytes[pixelIndex].toDouble();

        double green =
            bytes[pixelIndex + 1].toDouble();

        double red =
            bytes[pixelIndex + 2].toDouble();

        if (pixels == 0) {
          debugPrint(
            "RAW PIXEL BGRA: "
            "B=$blue "
            "G=$green "
            "R=$red"
          );
        }




        // Center weighting
        double dx =
            (x - image.width / 2).abs();

        double dy =
            (y - image.height / 2).abs();


        double distance =
            sqrt(dx * dx + dy * dy);


        double weight =
            1 / (1 + distance);




        totalRed += red * weight;

        totalGreen += green * weight;

        totalBlue += blue * weight;

        totalWeight += weight;


        pixels++;

      }

    }



    return RGBSample(

      red:
        totalRed / totalWeight,

      green:
        totalGreen / totalWeight,

      blue:
        totalBlue / totalWeight,

    );

  }







  // ==============================
  // YUV420 extraction
  // Android/iPhone fallback
  // ==============================

  static RGBSample _extractYUV(CameraImage image) {


    if (image.planes.length < 3) {
      throw Exception(
        "Invalid YUV planes: ${image.planes.length}"
     );
    }

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];



    double redTotal = 0;
    double greenTotal = 0;
    double blueTotal = 0;


    int count = 0;




    int startX =
        (image.width / 2 - 50).round();

    int startY =
        (image.height / 2 - 50).round();


    int endX =
        (image.width / 2 + 50).round();

    int endY =
        (image.height / 2 + 50).round();





    for(
      int y = startY;
      y < endY;
      y += 2
    ) {


      for(
        int x = startX;
        x < endX;
        x += 2
      ) {



        int yIndex =
            y * yPlane.bytesPerRow + x;



        int uvIndex =
            (y ~/ 2) *
            uPlane.bytesPerRow +
            (x ~/ 2);




        double Y =
            yPlane.bytes[yIndex]
            .toDouble();


        double U =
            uPlane.bytes[uvIndex]
            .toDouble();


        double V =
            vPlane.bytes[uvIndex]
            .toDouble();





        double red =
            Y +
            1.402 * (V - 128);



        double green =
            Y -
            0.344136 * (U - 128) -
            0.714136 * (V - 128);



        double blue =
            Y +
            1.772 * (U - 128);




        redTotal += red;

        greenTotal += green;

        blueTotal += blue;


        count++;

      }

    }



    return RGBSample(

      red:
        redTotal / count,

      green:
        greenTotal / count,

      blue:
        blueTotal / count,

    );

  }


}
