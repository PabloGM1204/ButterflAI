// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera/camera_screen.dart';
import 'chatbot/chat_screen.dart';
import 'results_page.dart';

/// Pantalla principal de la aplicación
class HomeScreen extends StatefulWidget {
  /// Constructor de la clase
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Estado de la pantalla principal
class _HomeScreenState extends State<HomeScreen> {
  /// Lista de cámaras disponibles
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    // Inicializa las cámaras
    _initCameras();
  }

  /// Obtiene la lista de cámaras disponibles
  Future<void> _initCameras() async {
    List<CameraDescription> camerasList = [];
    try {
      // Recoge las cámaras disponibles
      camerasList = await availableCameras();
    } on CameraException catch (e) {
      debugPrint("Error cargando cámaras: ${e.description}");
    }
    setState(() {
      cameras = camerasList;
    });
  }

  /// Recoge una imagen de la galería
  Future<void> getImage(ImageSource source, BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    // Abre la galería para seleccionar una imagen
    final pickedFile = await picker.pickImage(source: source);
    // Si se ha seleccionado una imagen, muestra la pantalla de resultados
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(File(pickedFile.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Ancho de la pantalla
    double width = MediaQuery.of(context).size.width;

    /// Alto de la pantalla
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo de pantalla
          Image.asset('assets/images/fondo_inicio.jpg', fit: BoxFit.fill),
          // Contenido de la pantalla
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                _buildTitle(width),
                const Spacer(),
                // Acceso al chatbot y a la galería
                _buildIconsRow(context, width),
                const SizedBox(height: 20),
                // Botón de detección en tiempo real
                _buildRealTimeDetectionButton(context, width, height),
                SizedBox(height: height * 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el título de la aplicación
  Widget _buildTitle(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          'ButterflAI',
          style: TextStyle(
            fontSize: width * 0.15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // Subtítulo
        Text(
          'Detector y Clasificador',
          style: TextStyle(
            fontSize: width * 0.05,
            color: Colors.white,
          ),
        ),
        // Autores
        Text(
          'Pablo y Jairo',
          style: TextStyle(
            fontSize: width * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Construye la fila de iconos de acceso al chatbot y a la galería
  Widget _buildIconsRow(BuildContext context, double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icono de chatbot
        IconButton(
          icon: Icon(Icons.smart_toy_outlined, size: width * 0.15),
          color: Colors.white,
          // Navega a la pantalla del chatbot
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          },
        ),
        SizedBox(width: width * 0.3),
        // Icono de galería
        IconButton(
          icon: Icon(Icons.image_search_rounded, size: width * 0.15),
          color: Colors.white,
          // Selección de imagen de la galería
          onPressed: () => getImage(ImageSource.gallery, context),
        ),
      ],
    );
  }

  /// Construye el botón de detección en tiempo real
  Widget _buildRealTimeDetectionButton(
      BuildContext context, double width, double height) {
    return Center(
      // Botón de detección en tiempo real
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.1,
            vertical: height * 0.02,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        // Deshabilita el botón mientras se cargan las cámaras
        onPressed: cameras == null
            ? null
            : () {
                // Navega a la pantalla de la cámara
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(cameras: cameras!),
                  ),
                );
              },
        // Muestra un indicador de carga mientras se cargan las cámaras
        child: cameras == null
            ? Column(
                children: [
                  // Texto de carga
                  Text(
                    'Cargando cámaras...',
                    style: TextStyle(
                      fontSize: width * 0.05,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Indicador de carga
                  const CircularProgressIndicator(color: Colors.black),
                ],
              )
            // Texto del botón
            : Text(
                'Detección en tiempo real',
                style: TextStyle(
                  fontSize: width * 0.05,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
