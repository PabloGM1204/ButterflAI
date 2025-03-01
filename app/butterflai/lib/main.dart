// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';

import 'models_management.dart';
import 'http_service.dart';
import 'screens/home_screen.dart';

/// Método principal de la aplicación
void main() async {
  // Inicialización de la aplicación
  WidgetsFlutterBinding.ensureInitialized();

  // Realiza la carga de la clave de la API
  HttpService.getKey();

  // Obtiene la información de las mariposas
  HttpService.getButterflyInfo();

  // Carga los modelos
  await ButterflyModels.loadLabels();
  await ButterflyModels.loadModels();

  // Ejecuta la aplicación
  runApp(const MyApp());
}

/// Clase principal de la aplicación
class MyApp extends StatelessWidget {
  /// Constructor de la clase
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Deshabilita el banner de depuración
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
