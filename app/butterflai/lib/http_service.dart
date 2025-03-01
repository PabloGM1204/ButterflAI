import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'butterfly_info.dart';

/// Servicio para realizar peticiones HTTP
class HttpService {
  /// API Key de OpenAI
  static String apiKey = "";

  /// Endpoint de OpenAI
  static String endpoint = "https://api.openai.com/v1/chat/completions";

  /// URL con la información de las mariposas
  static String infoUrl =
      "https://info-tmf-butterflai.s3.us-east-1.amazonaws.com/datos/mariposas.json";

  /// Información de las mariposas
  static List<ButterflyInfo> butterflyInfo = [];

  /// Obtiene la clave de la API
  static getKey() async {
    await dotenv.load(fileName: "assets/env/.env");
    apiKey = dotenv.env['API_KEY'] ?? "";
  }

  /// Obtiene la información de las mariposas
  static getButterflyInfo() async {
    try {
      // Realiza la petición al servidor
      final response = await http.get(Uri.parse(infoUrl));
      if (response.statusCode == 200) {
        // Obtiene la información de las mariposas
        butterflyInfo = ButterflyInfo.fromJsonList(response.body);
      } else {
        debugPrint(
            "Error obteniendo la información de las mariposas: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error al conectar con el servidor de mariposas: $e");
    }
  }

  static Future<ButterflyInfo> searchButterflyInfo(String name) async {
    final message =
        "I'm searching for information about the butterfly named '$name'. Give me a JSON response formatted as follows: [{\"Nombre común\": \"$name\", \"Nombre científico\": \"Scientific $name name\", \"Descripción\": \"Short description about $name\", \"Hábitat\": [\"Countries: ...\", \"(Other habitat information)\", \"...\"] }]. Provide only the JSON response with no additional text.";
    String response = await getResponse(message);
    // Comprueba si la respuesta empieza por "Error"
    if (response.startsWith("Error")) {
      return ButterflyInfo.empty(name);
    } else {
      final decoded = jsonDecode(response);
      return ButterflyInfo.fromJson(decoded[0]);
    }
  }

  /// Obtiene la respuesta del servicio de chat
  static Future<String> getResponse(String message) async {
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
              "content":
                  "You only know about butterflies and moths and nothing else."
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
        return "Error in server response";
      }
    } catch (e) {
      return "Error connecting to server";
    }
  }
}
