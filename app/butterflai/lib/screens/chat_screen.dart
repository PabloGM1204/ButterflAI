// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import '../http_service.dart';

/// Pantalla del chatbot
class ChatScreen extends StatefulWidget {
  /// Constructor de la pantalla del chatbot
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

/// Estado de la pantalla del chatbot
class _ChatScreenState extends State<ChatScreen> {
  /// Controlador del campo de texto
  final TextEditingController _controller = TextEditingController();

  /// Lista de mensajes
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _addMessage("bot",
        "Hi, I'm ButterflAI, your expert butterfly assistant.\nHow can I help you?");
  }

  /// Agrega un mensaje a la lista y actualiza la interfaz
  void _addMessage(String sender, String text) {
    setState(() {
      _messages.add({"sender": sender, "text": text});
    });
  }

  /// Envía un mensaje al chatbot
  void _sendMessage() async {
    // Obtiene el mensaje del campo de texto
    String message = _controller.text.trim();
    // Si el mensaje está vacío, no hace nada
    if (message.isEmpty) return;
    // Añade el mensaje del usuario a la lista de mensajes
    _addMessage("user", message);
    // Limpia el campo de texto
    _controller.clear();
    // Oculta el teclado al enviar el mensaje
    FocusScope.of(context).unfocus();
    // Obtiene la respuesta del chatbot
    String response = await HttpService.getResponse(message);
    // Añade la respuesta del chatbot a la lista de mensajes
    _addMessage("bot", response);
  }

  @override
  Widget build(BuildContext context) {
    // Ancho de la pantalla
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        // Título de la pantalla
        title: Text("Chatbot",
            style: TextStyle(
              color: Colors.black,
              fontSize: width * 0.06,
            )),
        // Color de fondo de la barra de navegación
        backgroundColor: const Color(0xAAA0FF46),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo con imagen
          _buildBackground(),
          // Lista de mensajes y la barra de entrada
          Column(
            children: [
              _buildMessageList(width),
              _buildInputBar(),
            ],
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

  /// Construye la lista de mensajes
  Widget _buildMessageList(double width) {
    return Expanded(
      // Lista de mensajes
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          // Comprueba si el mensaje es del usuario o del chatbot
          bool isUser = _messages[index]["sender"] == "user";
          return Align(
            // Alinea el mensaje según el remitente
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: width * 0.8),
              padding: const EdgeInsets.all(10),
              // Margen del mensaje
              margin: const EdgeInsets.only(
                top: 5,
                bottom: 5,
              ),
              // Bordes redondeados del mensaje
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: isUser ? const Radius.circular(15) : Radius.zero,
                  topRight: isUser ? Radius.zero : const Radius.circular(15),
                  bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(15),
                ),
              ),
              // Texto del mensaje
              child: Text(
                _messages[index]["text"]!,
                style: TextStyle(fontSize: width * 0.04),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye la barra de entrada de texto
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            // Campo de texto
            child: TextField(
              controller: _controller,
              // Primera letra en mayúscula
              textCapitalization: TextCapitalization.sentences,
              // Número de líneas mínimas y máximas
              minLines: 1,
              maxLines: 5,
              // Longitud máxima del texto
              maxLength: 300,
              decoration: const InputDecoration(
                border: InputBorder.none,
                // Texto de ayuda
                hintText: "¿Cuál es la mariposa más ...",
              ),
            ),
          ),
          // Botón de enviar mensaje
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
