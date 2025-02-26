import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;

class ButterflyModels {
  static late tfl.Interpreter _detectorInterpreter;
  static late tfl.Interpreter _classifierInterpreter;
  static Map<int, String> butterflyLabels = {};
  static bool _modelsLoaded = false;
  static bool _labelsLoaded = false;

  static Future<void> loadModels() async {
    if (_modelsLoaded) return; // Evita recargar si ya se hizo
    _detectorInterpreter =
        await tfl.Interpreter.fromAsset('assets/models/detector.tflite');
    _classifierInterpreter =
        await tfl.Interpreter.fromAsset('assets/models/clasificador.tflite');
    _modelsLoaded = true;
  }

  static Future<void> loadLabels() async {
    if (_labelsLoaded) return; // Evita recargar si ya se hizo
    String butterflyLabelsString =
        await rootBundle.loadString('assets/models/labels_clasificador.txt');
    List<String> labelsList =
        butterflyLabelsString.split('\n').map((e) => e.trim()).toList();
    butterflyLabels = {
      for (int i = 0; i < labelsList.length; i++) i: labelsList[i]
    };
    _labelsLoaded = true;
  }

  static Future<Map<String, dynamic>?> detectButterfly(File imageFile) async {
    if (!_modelsLoaded) {
      throw Exception("El modelo de detección no está cargado.");
    }

    img.Image imageInput = img.decodeImage(imageFile.readAsBytesSync())!;
    img.Image resizedImage =
        img.copyResize(imageInput, width: 640, height: 640);
    var detectorInput =
        _imageToByteListFloat32(resizedImage, 640, 127.5, 127.5);

    var outputDetections = List.generate(
        1, (_) => List.generate(5, (_) => List.filled(8400, 0.0)));
    _detectorInterpreter.run(detectorInput, outputDetections);

    List<Map<String, dynamic>> detections = [];
    for (int i = 0; i < 8400; i++) {
      double score = outputDetections[0][4][i];
      if (score > 0.7) {
        detections.add({
          'score': score,
          'top': outputDetections[0][1][i],
          'left': outputDetections[0][0][i],
          'bottom': outputDetections[0][3][i],
          'right': outputDetections[0][2][i]
        });
      }
    }

    if (detections.isEmpty) return null;

    Map<String, dynamic> bestDetection =
        detections.reduce((a, b) => a['score'] > b['score'] ? a : b);

    double top = bestDetection['top'].toDouble();
    double left = bestDetection['left'].toDouble();
    double bottom = bestDetection['bottom'].toDouble();
    double right = bestDetection['right'].toDouble();

    double cropWidth = right - left;
    double cropHeight = bottom - top;

    if (cropWidth > 0 && cropHeight > 0) {
      return {
        "top": top,
        "left": left,
        "width": cropWidth,
        "height": cropHeight
      };
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> classifyButterfly(File imageFile) async {
    if (!_modelsLoaded || !_labelsLoaded) {
      throw Exception("Los modelos y etiquetas no están cargados.");
    }

    img.Image imageInput = img.decodeImage(imageFile.readAsBytesSync())!;
    img.Image finalImage = img.copyResize(imageInput, width: 224, height: 224);

    var classifierInput =
        _imageToByteListFloat32(finalImage, 224, 127.5, 127.5);
    var classifierOutput = List.filled(1 * 100, 0).reshape([1, 100]);
    _classifierInterpreter.run(classifierInput, classifierOutput);

    int maxIndex = classifierOutput[0].indexWhere((element) =>
        element ==
        classifierOutput[0].reduce((double a, double b) => a > b ? a : b));

    return {
      "classificationClass": butterflyLabels[maxIndex] ?? "Desconocido",
      "confidence": classifierOutput[0][maxIndex],
      "finalImage": finalImage
    };
  }

  static Uint8List _imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = ((pixel & 0xFF) - mean) / std;
        buffer[pixelIndex++] = (((pixel >> 8) & 0xFF) - mean) / std;
        buffer[pixelIndex++] = (((pixel >> 16) & 0xFF) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
