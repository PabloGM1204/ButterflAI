import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { environment } from 'src/environments/environment';

@Component({
  selector: 'app-chatbot',
  standalone: true,
  imports: [CommonModule, IonicModule, HttpClientModule, FormsModule],
  templateUrl: './chatbot.component.html',
  styleUrls: ['./chatbot.component.scss']
})
export class ChatbotComponent {
  messages: { sender: string, text: string }[] = []; // ✅ Almacena los mensajes del chat
  userInput: string = ''; // ✅ Almacena el mensaje del usuario
  isLoading = false; // ✅ Para mostrar "Cargando..." mientras responde el bot

  apiUrl = 'https://api.openai.com/v1/chat/completions'; // ✅ Endpoint de OpenAI
  apiKey = environment.apiKey; // 🔹 REEMPLAZA con tu clave de OpenAI

  constructor(private http: HttpClient) {
    this.loadMessages(); // ✅ Cargar mensajes guardados al iniciar
  }

  loadMessages() {
    const savedMessages = localStorage.getItem('chatHistory');
    if (savedMessages) {
      this.messages = JSON.parse(savedMessages);
    } else {
      this.sendWelcomeMessage(); // ✅ Si no hay historial, mostrar mensaje de bienvenida
    }
  }

  saveMessages() {
    localStorage.setItem('chatHistory', JSON.stringify(this.messages));
  }

  sendWelcomeMessage() {
    const welcomeMessage = {
      sender: 'bot',
      text: "Hola, soy ButterflAI 🦋, tu asistente sobre mariposas favorito."
    };
    this.messages.push(welcomeMessage);
    this.saveMessages(); // ✅ Guardar mensaje de bienvenida en el historial
  }

  sendMessage() {
    if (!this.userInput.trim()) return; // No enviar mensajes vacíos

    const userMessage = { sender: 'user', text: this.userInput };
    this.messages.push(userMessage);
    this.saveMessages(); // ✅ Guardar historial después de enviar mensaje
    this.isLoading = true;

    const requestBody = {
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Eres ButterflAI, un asistente experto en mariposas que responde preguntas de manera clara y útil." },
        { role: "user", content: this.userInput }
      ],
      max_tokens: 300
    };

    this.http.post(this.apiUrl, requestBody, {
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      }
    }).subscribe(
      (response: any) => {
        const botMessage = { sender: 'bot', text: response.choices[0].message.content };
        this.messages.push(botMessage);
        this.saveMessages(); // ✅ Guardar historial después de recibir respuesta
        this.isLoading = false;

        this.speak(botMessage.text);
      },
      (error) => {
        console.error('Error en la API:', error);
        this.isLoading = false;
      }
    );

    this.userInput = ''; // Limpiar input después de enviar el mensaje
  }

  // 🔊 Función para convertir texto en voz
  speak(text: string) {
    const speech = new SpeechSynthesisUtterance(text);
    speech.lang = 'es-ES';  // Idioma español
    speech.rate = 1;        // Velocidad normal
    speech.pitch = 1;       // Tono normal
    window.speechSynthesis.speak(speech);
  }
}