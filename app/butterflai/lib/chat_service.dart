import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String apiKey = "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";
  final String endpoint = "https://api.openai.com/v1/chat/completions";

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
            {"role": "system", "content": "Eres un asistente útil."},
            {"role": "user", "content": message}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["choices"][0]["message"]["content"];
      } else {
        return "Error en la respuesta del servidor";
      }
    } catch (e) {
      return "Error al conectar con ChatGPT";
    }
  }
}
