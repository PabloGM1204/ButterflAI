// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'camera/models.dart';

class ResultScreen extends StatefulWidget {
  final File image;
  const ResultScreen(this.image, {super.key});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String _classificationClass = "";
  double _confidence = 0.0;
  img.Image? _finalImage;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    _runClassification();
  }

  Future<void> _runClassification() async {
    var result = await ButterflyModels.classifyButterfly(widget.image);
    setState(() {
      _classificationClass = result["classificationClass"];
      _confidence = result["confidence"];
      _finalImage = result["finalImage"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultados')),
      body: Column(
        children: [
          if (_finalImage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  Image.memory(Uint8List.fromList(img.encodePng(_finalImage!))),
            ),
          const SizedBox(height: 20),
          const Text(
            "Clasificación:",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _classificationClass,
            style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
          ),
          const SizedBox(height: 10),
          Text(
            "Confianza: ${(_confidence * 100).toStringAsFixed(2)}%",
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
