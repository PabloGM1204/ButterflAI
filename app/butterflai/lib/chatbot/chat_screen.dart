// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    messages.add({
      "sender": "bot",
      "text":
          "Hola soy ButterflAI, tu asistente experto en mariposas.\n¿En qué te puedo ayudar?"
    });
  }

  void sendMessage() async {
    String message = _controller.text;
    if (message.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": message});
    });

    _controller.clear();
    // Oculta el teclado al enviar el mensaje
    FocusScope.of(context).unfocus();

    String response = await chatService.getResponse(message);

    setState(() {
      messages.add({"sender": "bot", "text": response});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatBot",
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
            )),
        backgroundColor: const Color(0xAAA0FF46),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo verde con imagen de mariposas en transparencia
          Container(
            decoration: const BoxDecoration(
              color: Color(0xAAA0FF46),
              image: DecorationImage(
                image: AssetImage("assets/images/fondo_chat.png"),
                opacity: 0.2,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    bool isUser = messages[index]["sender"] == "user";
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(
                          top: 5,
                          bottom: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: isUser
                                ? const Radius.circular(15)
                                : Radius.zero,
                            topRight: isUser
                                ? Radius.zero
                                : const Radius.circular(15),
                            bottomLeft: isUser
                                ? const Radius.circular(15)
                                : Radius.zero,
                            bottomRight: isUser
                                ? Radius.zero
                                : const Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          messages[index]["text"]!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Barra de entrada de texto con diseño personalizado
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        autofocus: true,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "¿Cuál es la mariposa más ...",
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_forward, color: Colors.black),
                      onPressed: sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
