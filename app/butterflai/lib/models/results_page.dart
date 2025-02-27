// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
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
          Column(
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
          ),
          // Resultados de la clasificación
          DraggableScrollableSheet(
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
                    Container(
                      width: 80,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Resultados de la clasificación
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                top: 20, left: 16, right: 16, bottom: 10),
                            child: ListTile(
                              // Nombre de la mariposa
                              title: Text(
                                _predictions[index]["class"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  // Fuente y tamaño según la posición
                                  fontSize: (index == 0)
                                      ? width * 0.07
                                      : width * 0.055,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Confianza de la predicción
                              subtitle: Text(
                                "${(_predictions[index]["confidence"] * 100).toStringAsFixed(2)} %",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: width * 0.055),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
}
