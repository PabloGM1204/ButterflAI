// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models_management.dart';

/// Pantalla de la cámara en tiempo real
class CameraScreen extends StatefulWidget {
  /// Lista de cámaras disponibles
  final List<CameraDescription> cameras;

  /// Constructor de la clase
  const CameraScreen({super.key, required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

/// Estado de la pantalla de la cámara
class _CameraScreenState extends State<CameraScreen> {
  /// Controlador de la cámara
  CameraController? _controller;

  /// Inicialización del controlador
  Future<void>? _initializeControllerFuture;

  /// Indicador de cambio de cámara
  bool _isCameraChanging = false;

  /// Resultado de la clasificación
  String _classificationResult = "X";

  /// Confianza de la clasificación
  double _confidence = 0.0;

  /// Temporizador de clasificación
  Timer? _timer;

  /// Cuadro de detección
  Rect? _detectionBox;

  @override
  void initState() {
    super.initState();
    // Inicializa la cámara
    _initCamera();
    // Inicia la clasificación
    _startClassification();
  }

  /// Inicializa la cámara
  Future<void> _initCamera() async {
    // Evita cambios de cámara simultáneos
    if (_isCameraChanging) return;
    _isCameraChanging = true;

    // Comprueba si hay cámaras disponibles
    if (widget.cameras.isEmpty) {
      debugPrint('No hay cámaras disponibles');
      _isCameraChanging = false;
      return;
    }

    try {
      // Libera la cámara anterior
      await _controller?.dispose();
      _controller = null;

      // Inicializa la nueva cámara
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
      );

      // Inicializa el controlador
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      // Si el widget aún está montado, actualiza el estado
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
    }
    // Indica que la cámara ha terminado de cambiar
    _isCameraChanging = false;
  }

  /// Inicia la clasificación
  void _startClassification() {
    // Inicia el temporizador de clasificación
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // Comprueba si el controlador de la cámara está inicializado
      if (_controller == null || !_controller!.value.isInitialized) return;
      try {
        // Captura una imagen
        XFile imageFile = await _controller!.takePicture();
        // Detecta si hay una mariposa en la imagen
        var newBox =
            await ButterflyModels.detectButterfly(File(imageFile.path));
        // Clasifica la mariposa si se detectó
        if (newBox == null) {
          setState(() {
            _classificationResult = "X";
            _confidence = 0.0;
            _detectionBox = null;
          });
        } else {
          // Clasifica la mariposa
          var result =
              await ButterflyModels.classifyButterfly(File(imageFile.path));
          // Recoge el resultado y la confianza de la clasificación
          var newResult = "${result["topPredictions"][0]["class"]}";
          var newConfidence = result["topPredictions"][0]["confidence"] * 100;
          // Actualiza el estado si hay cambios
          if (newResult != _classificationResult ||
              newConfidence != _confidence) {
            setState(() {
              _classificationResult = newResult;
              _confidence = newConfidence;
              _detectionBox = Rect.fromLTWH(newBox["left"], newBox["top"],
                  newBox["width"], newBox["height"]);
            });
          }
        }
        // Libera memoria después de clasificar
        await File(imageFile.path).delete();
      } catch (e) {
        debugPrint('Error al clasificar imagen: $e');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Anchura de la pantalla
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time detection',
            style: TextStyle(
              color: Colors.black,
              fontSize: screenWidth * 0.06,
            )),
        backgroundColor: const Color(0xAAA0FF46),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: const Color(0xAAA0FF46),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Vista previa de la cámara
            _buildCameraPreview(),
            // Cuadro de detección si se detecta una mariposa
            if (_detectionBox != null) _buildDetectionBox(),
            _buildClassificationResult(screenWidth),
          ],
        ),
      ),
    );
  }

  /// Construye la vista previa de la cámara
  Widget _buildCameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        // Comprueba si la cámara está inicializada
        if (snapshot.connectionState == ConnectionState.done &&
            _controller != null &&
            _controller!.value.isInitialized) {
          // Devuelve la vista previa de la cámara
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize?.height ?? 1,
              height: _controller!.value.previewSize?.width ?? 1,
              child: CameraPreview(_controller!),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  /// Dibuja el cuadro de detección en la imagen
  Widget _buildDetectionBox() {
    return Positioned(
      // Posiciona el cuadro de detección
      top: _detectionBox!.top - 100,
      left: _detectionBox!.left - 200,
      width: _detectionBox!.width,
      height: _detectionBox!.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 4),
        ),
      ),
    );
  }

  /// Muestra los resultados de la clasificación en la parte inferior
  Widget _buildClassificationResult(double width) {
    // Posiciona el contenedor en la parte inferior
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            // Resultado de la clasificación
            Text(
              _classificationResult,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: width * 0.045),
            ),
            // Confianza de la clasificación
            Text(
              "${_confidence.toStringAsFixed(2)}%",
              style: TextStyle(color: Colors.white, fontSize: width * 0.045),
            ),
          ],
        ),
      ),
    );
  }
}
