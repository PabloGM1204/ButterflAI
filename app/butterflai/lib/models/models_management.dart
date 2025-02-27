import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;

/// Clase que contiene y maneja los modelos de detección y clasificación de mariposas
class ButterflyModels {
  /// Interprete del modelo de detección
  static late tfl.Interpreter _detectorInterpreter;

  /// Interprete del modelo de clasificación
  static late tfl.Interpreter _classifierInterpreter;

  /// Etiquetas de las mariposas
  static Map<int, String> _butterflyLabels = {};

  /// Bandera que indica si los modelos están cargados
  static bool _modelsLoaded = false;

  /// Bandera que indica si las etiquetas están cargadas
  static bool _labelsLoaded = false;

  /// Carga los modelos de detección y clasificación
  static Future<void> loadModels() async {
    // Evita recargar si ya se hizo
    if (_modelsLoaded) return;
    // Carga el detector
    _detectorInterpreter =
        await tfl.Interpreter.fromAsset('assets/models/detector.tflite');
    // Carga el clasificador
    _classifierInterpreter =
        await tfl.Interpreter.fromAsset('assets/models/clasificador.tflite');
    // Marca los modelos como cargados
    _modelsLoaded = true;
  }

  /// Carga las etiquetas de las mariposas
  static Future<void> loadLabels() async {
    // Evita recargar si ya se hizo
    if (_labelsLoaded) return;
    // Carga las etiquetas
    String butterflyLabelsString =
        await rootBundle.loadString('assets/models/labels_clasificador.txt');
    // Convierte las etiquetas en una lista
    List<String> labelsList =
        butterflyLabelsString.split('\n').map((e) => e.trim()).toList();
    // Crea un mapa con las etiquetas
    _butterflyLabels = {
      for (int i = 0; i < labelsList.length; i++) i: labelsList[i]
    };
    // Marca las etiquetas como cargadas
    _labelsLoaded = true;
  }

  /// Detecta una mariposa en una imagen
  static Future<Map<String, dynamic>?> detectButterfly(File imageFile) async {
    // Verifica que el modelo esté cargado
    if (!_modelsLoaded) {
      throw Exception("El modelo de detección no está cargado.");
    }

    // Decodifica la imagen
    img.Image imageInput = img.decodeImage(imageFile.readAsBytesSync())!;
    // Redimensiona la imagen a 640x640
    img.Image resizedImage =
        img.copyResize(imageInput, width: 640, height: 640);

    // Convierte la imagen en un tensor para el modelo
    var detectorInput =
        _imageToByteListFloat32(resizedImage, 640, 127.5, 127.5);

    // Crea la estructura de salida del modelo
    var outputDetections = List.generate(
        1, (_) => List.generate(5, (_) => List.filled(8400, 0.0)));

    // Ejecuta el modelo de detección
    _detectorInterpreter.run(detectorInput, outputDetections);

    // Procesa las detecciones
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

    // Si no hay detecciones, devuelve null
    if (detections.isEmpty) return null;

    // Encuentra la mejor detección
    Map<String, dynamic> bestDetection =
        detections.reduce((a, b) => a['score'] > b['score'] ? a : b);

    // Saca las coordenadas de la mejor detección
    double top = bestDetection['top'].toDouble();
    double left = bestDetection['left'].toDouble();
    double bottom = bestDetection['bottom'].toDouble();
    double right = bestDetection['right'].toDouble();
    double cropWidth = right - left;
    double cropHeight = bottom - top;

    // Comprueba que las coordenadas sean válidas
    if (cropWidth > 0 && cropHeight > 0) {
      // Devuelve las coordenadas
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

  /// Clasifica una mariposa en una imagen
  static Future<Map<String, dynamic>> classifyButterfly(File imageFile) async {
    // Verifica que el modelo y las etiquetas estén cargados
    if (!_modelsLoaded || !_labelsLoaded) {
      throw Exception(
          "El model de clasificación y las etiquetas no están cargados.");
    }

    // Decodifica la imagen
    img.Image imageInput = img.decodeImage(imageFile.readAsBytesSync())!;
    // Redimensiona la imagen a 224x224
    img.Image finalImage = img.copyResize(imageInput, width: 224, height: 224);

    // Convierte la imagen en un tensor para el modelo
    var classifierInput =
        _imageToByteListFloat32(finalImage, 224, 127.5, 127.5);
    // Crea la estructura de salida del modelo
    var classifierOutput = List.filled(1 * 100, 0).reshape([1, 100]);
    // Ejecuta el modelo de clasificación
    _classifierInterpreter.run(classifierInput, classifierOutput);

    // Convierte el resultado en una lista de pares (clase, confianza)
    List<Map<String, dynamic>> predictions = [];
    for (int i = 0; i < _butterflyLabels.length; i++) {
      predictions.add({
        "class": _butterflyLabels[i], // Clase
        "confidence": classifierOutput[0][i], // Confianza
      });
    }

    // Ordena las predicciones de mayor a menor confianza
    predictions.sort((a, b) => b["confidence"].compareTo(a["confidence"]));

    // Toma las 10 mejores predicciones
    List<Map<String, dynamic>> topPredictions = predictions.take(10).toList();

    // Elimina las predicciones con confianza menor a 0.01
    topPredictions.removeWhere((element) => element["confidence"] <= 0.01);

    // Devuelve la clasificación con las 10 mejores predicciones y la imagen final
    return {
      "topPredictions": topPredictions, // Lista de las 10 mejores predicciones
      "finalImage": finalImage, // Imagen redimensionada
    };
  }

  /// Convierte una imagen en una lista de bytes
  static Uint8List _imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    // Crea una lista de bytes
    var convertedBytes = Float32List(inputSize * inputSize * 3);
    // Crea un buffer de 32 bits
    var buffer = Float32List.view(convertedBytes.buffer);
    // Itera sobre cada píxel de la imagen
    int pixelIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        // Obtiene el píxel de la imagen
        var pixel = image.getPixel(x, y);
        // Convierte el píxel a RGB y normaliza
        buffer[pixelIndex++] = ((pixel & 0xFF) - mean) / std;
        buffer[pixelIndex++] = (((pixel >> 8) & 0xFF) - mean) / std;
        buffer[pixelIndex++] = (((pixel >> 16) & 0xFF) - mean) / std;
      }
    }
    // Devuelve la lista de bytes
    return convertedBytes.buffer.asUint8List();
  }
}
