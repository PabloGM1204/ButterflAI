// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'models_management.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  bool _isCameraChanging = false;
  String _classificationResult = "Clasificación: ...";
  double _confidence = 0.0;
  Timer? _timer;
  Rect? _detectionBox;

  @override
  void initState() {
    super.initState();
    _initCamera(_selectedCameraIndex);
    _startClassification();
  }

  Future<void> _initCamera(int cameraIndex) async {
    if (_isCameraChanging) return;
    _isCameraChanging = true;

    if (widget.cameras.isEmpty) {
      debugPrint('No hay cámaras disponibles');
      _isCameraChanging = false;
      return;
    }

    try {
      await _controller?.dispose();
      _controller = null;

      _controller = CameraController(
        widget.cameras[cameraIndex],
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
    }

    _isCameraChanging = false;
  }

  void _startClassification() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
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
            _classificationResult = "Clasificación: X";
            _confidence = 0.0;
            _detectionBox = null;
          });
        } else {
          // Clasifica la mariposa
          var result =
              await ButterflyModels.classifyButterfly(File(imageFile.path));
          // Recoge el resultado y la confianza de la clasificación
          var newResult = "Clasificación: ${result["classificationClass"]}";
          var newConfidence = result["confidence"] * 100;
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

  void _switchCamera() async {
    if (widget.cameras.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      await _initCamera(_selectedCameraIndex);
    } else {
      debugPrint("Solo hay una cámara disponible");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cámara en tiempo real'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.inversePrimary,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _controller != null &&
                    _controller!.value.isInitialized) {
                  return Center(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize?.height ?? 1,
                        height: _controller!.value.previewSize?.width ?? 1,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
            if (_detectionBox != null)
              Positioned(
                top: _detectionBox!.top - 100,
                left: _detectionBox!.left - 200,
                width: _detectionBox!.width,
                height: _detectionBox!.height,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 4),
                  ),
                ),
              ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      _classificationResult,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    Text(
                      "Confianza: ${_confidence.toStringAsFixed(2)}%",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'switch_camera',
                    onPressed: _switchCamera,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.switch_camera),
                        Text('${_selectedCameraIndex + 1}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
