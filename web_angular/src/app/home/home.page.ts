import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { DeteccionComponent } from '../components/deteccion/deteccion.component';
import { ClasificationComponent } from '../components/clasification/clasification.component';
import { ChatbotComponent } from '../components/chatbot/chatbot.component';

@Component({
  selector: 'app-home',
  standalone: true, // Como estamos usando standalone
  imports: [CommonModule, IonicModule, DeteccionComponent, ClasificationComponent, ChatbotComponent], // Importamos el componente
  templateUrl: './home.page.html',
  styleUrls: ['./home.page.scss'],
})
export class HomePage {
  detections: any[] = [];
  classificationResult: any = null;
  imageToClassify: File | null = null;

  onDetectionsReceived(detections: any[]) {
    console.log('Detecciones recibidas en Home:', detections);
    this.detections = detections;
  }

  onSendToClassifier(image: File) {
    console.log('Recibida imagen para clasificar:', image.name);
    this.imageToClassify = image; // ✅ Guardamos la imagen para enviarla al clasificador
  }

  onClassificationReceived(result: any) {
    console.log('Clasificación recibida en Home:', result);
    this.classificationResult = result;
  }

  isChatOpen = false; // ✅ Controla si el chatbot está visible

  toggleChat() {
    this.isChatOpen = !this.isChatOpen; // ✅ Cambia el estado del chat al hacer clic
  }
}
