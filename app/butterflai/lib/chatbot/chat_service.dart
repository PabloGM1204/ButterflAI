import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  static String apiKey = "";
  final String endpoint = "https://api.openai.com/v1/chat/completions";

  static getKey() async {
    await dotenv.load(fileName: "assets/env/.env");
    apiKey = dotenv.env['API_KEY'] ?? "";
  }

  Future<String> getResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {"role": "system", "content": "Solo sabes de mariposas y polillas y nada más."},
            {"role": "user", "content": message}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["choices"][0]["message"]["content"];
      } else {
        debugPrint(response.body);
        return "Error en la respuesta del servidor";
      }
    } catch (e) {
      return "Error al conectar con ChatGPT";
    }
  }
}
