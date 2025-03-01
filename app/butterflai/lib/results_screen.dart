// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'dart:typed_data';
import 'package:butterflai/butterfly_info.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'http_service.dart';
import 'models_management.dart';

/// Pantalla de resultados de la clasificación
class ResultScreen extends StatefulWidget {
  /// Imagen a clasificar
  final File image;

  /// Constructor de la clase
  const ResultScreen(this.image, {super.key});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

/// Estado de la pantalla de resultados
class _ResultScreenState extends State<ResultScreen> {
  /// Predicción de la mariposa
  List<Map<String, dynamic>> _predictions = [];

  /// Imagen final
  img.Image? _finalImage;

  @override
  void initState() {
    super.initState();
    _runClassification();
  }

  /// Clasifica la mariposa en la imagen
  Future<void> _runClassification() async {
    var result = await ButterflyModels.classifyButterfly(widget.image);
    setState(() {
      _predictions = result["topPredictions"];
      _finalImage = result["finalImage"];
    });
  }

  /// Obtiene la información de la mariposa
  Future<ButterflyInfo> _getInfo(String name) async {
    ButterflyInfo info = ButterflyInfo.empty(name);

    info = HttpService.butterflyInfo.firstWhere(
      (b) => b.commonName.toLowerCase() == name.toLowerCase(),
      orElse: () => info,
    );

    if (info.scientificName == "Unknown") {
      info = await HttpService.searchButterflyInfo(name);
    }

    return info;
  }

  @override
  Widget build(BuildContext context) {
    // Ancho de la pantalla
    double width = MediaQuery.of(context).size.width;
    // Altura de la pantalla
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: const Color(0xAAA0FF46),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Fondo de pantalla
          _buildBackground(),
          // Imagen de la mariposa
          _buildImage(height),
          // Resultados de la clasificación
          _buildDraggable(width, height),
        ],
      ),
    );
  }

  /// Construye el fondo con la imagen
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xAAA0FF46),
        image: DecorationImage(
          image: AssetImage("assets/images/fondo_chat.png"),
          opacity: 0.2,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Construye la imagen de la mariposa
  Widget _buildImage(double height) {
    return Column(
      children: [
        SizedBox(height: height * 0.05),
        // Imagen de la mariposa
        if (_finalImage != null)
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.memory(
                Uint8List.fromList(img.encodePng(_finalImage!)),
              ),
            ),
          ),
      ],
    );
  }

  /// Construye los resultados de la clasificación
  Widget _buildDraggable(double width, double height) {
    return DraggableScrollableSheet(
      initialChildSize: 0.25, // Posición inicial
      minChildSize: 0.25, // Tamaño mínimo
      maxChildSize: 0.5, // Hasta el 50% de la pantalla
      builder: (context, scrollController) {
        return Container(
          // Estilo de la tarjeta
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // Barra de arrastre
              _buildDragHandle(width),
              // Resultados de la clasificación
              FutureBuilder<Widget>(
                future: _buildResults(scrollController, width),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading results'));
                  } else {
                    return snapshot.data!;
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye la barra de arrastre
  Widget _buildDragHandle(double width) {
    return Container(
      width: 80,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  /// Construye los resultados de la clasificación con información adicional
  Future<Widget> _buildResults(
      ScrollController scrollController, double width) async {
    // Obtiene el nombre de la mariposa
    if (_predictions.isEmpty) {
      return const Center(child: Text('No predictions'));
    }
    String name = _predictions[0]["class"];

    // Obtiene la información de la mariposa
    ButterflyInfo butterflyInfo = await _getInfo(name);
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: _predictions.length,
        itemBuilder: (context, index) {
          name = _predictions[index]["class"];
          // Construye la tarjeta con la información de la mariposa
          return Padding(
            padding:
                const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 10),
            // Tarjeta con la información
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildButterflyInfo(butterflyInfo, width, index),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye toda la información de la mariposa
  Widget _buildButterflyInfo(
      ButterflyInfo butterflyInfo, double width, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre de la mariposa
        Center(
          child: Text(
            _predictions[index]["class"],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: width * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Confianza de la predicción
        Center(
          child: Text(
            "${(_predictions[index]["confidence"] * 100).toStringAsFixed(2)} %",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: width * 0.05, color: Colors.grey[700]),
          ),
        ),
        if (index == 0) ...[
          const Divider(height: 20, thickness: 1),
          // Información adicional
          _buildInfo(
              "📜 Scientific name: ", butterflyInfo.scientificName, width),
          const SizedBox(height: 5),
          _buildInfo("📖 Description: ", butterflyInfo.description, width),
          const SizedBox(height: 5),
          _buildInfo("🌍 Habitat: ", butterflyInfo.habitat.join('; '), width)
        ],
      ],
    );
  }

  // Construye el texto con la información adicional
  Widget _buildInfo(String title, String info, double width) {
    return Text.rich(
      TextSpan(
        children: [
          // Título
          TextSpan(
            text: title,
            style:
                TextStyle(fontSize: width * 0.04, fontWeight: FontWeight.bold),
          ),
          // Información
          TextSpan(
            text: info,
            style: TextStyle(fontSize: width * 0.04),
          ),
        ],
      ),
    );
  }
}
