import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio de chat con OpenAI
class ChatService {
  /// API Key de OpenAI
  static String apiKey = "";

  /// Endpoint de OpenAI
  final String endpoint = "https://api.openai.com/v1/chat/completions";

  /// Obtiene la clave de la API
  static getKey() async {
    await dotenv.load(fileName: "assets/env/.env");
    apiKey = dotenv.env['API_KEY'] ?? "";
  }

  /// Obtiene la respuesta del servicio de chat
  Future<String> getResponse(String message) async {
    try {
      // Realiza la petición al servidor
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        // Cuerpo de la petición
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content": "Solo sabes de mariposas y polillas y nada más."
            },
            {"role": "user", "content": message}
          ],
        }),
      );

      // Procesa la respuesta
      if (response.statusCode == 200) {
        // Decodifica la respuesta y obtiene el contenido del mensaje
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["choices"][0]["message"]["content"];
      } else {
        // Imprime el cuerpo de la respuesta en caso de error
        debugPrint(response.body);
        return "Error en la respuesta del servidor";
      }
    } catch (e) {
      return "Error al conectar con ChatGPT";
    }
  }
}
