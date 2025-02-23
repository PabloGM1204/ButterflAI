import { Component, EventEmitter, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { HttpClient, HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-deteccion',
  standalone: true,
  imports: [CommonModule, IonicModule, HttpClientModule],
  templateUrl: './deteccion.component.html',
  styleUrls: ['./deteccion.component.scss']
})
export class DeteccionComponent {
  selectedFile: File | null = null;
  imageUrl: string | ArrayBuffer | null = null;
  detections: any[] = [];

  @Output() detectionsFound = new EventEmitter<any[]>(); // ✅ Emitimos detecciones
  @Output() sendToClassifier = new EventEmitter<File>(); // ✅ Emitimos imagen a clasificador

  apiUrl = 'https://pablogm-1204-tfm-mariposas.hf.space/predict';

  constructor(private http: HttpClient) {}

  onFileSelected(event: any) {
    this.selectedFile = event.target.files[0];

    if (this.selectedFile) {
      const reader = new FileReader();
      reader.onload = () => {
        this.imageUrl = reader.result;
      };
      reader.readAsDataURL(this.selectedFile);
    }
  }

  uploadImage() {
    if (!this.selectedFile) {
      console.error('No se ha seleccionado ninguna imagen');
      return;
    }

    console.log('Enviando imagen a la API...');

    const formData = new FormData();
    formData.append('file', this.selectedFile);

    this.http.post(this.apiUrl, formData, {
      headers: {
        'Accept': 'application/json', // ✅ Aseguramos que el backend acepte JSON
      }
    }).subscribe(
      (response: any) => {
        console.log('Respuesta de la API:', response);
        this.detections = response.detections;
        this.detectionsFound.emit(this.detections); // ✅ Emitimos detecciones

        // 🔹 Verificar si hay una mariposa en la detección
        const mariposaDetectada = this.detections.some(det => det.class.toLowerCase() === 'butterfly');
        if (mariposaDetectada) {
          console.log('¡Mariposa detectada! Enviando al clasificador...');
          if (this.selectedFile)
            this.sendToClassifier.emit(this.selectedFile); // ✅ Enviar la imagen al clasificador
        }
      },
      (error) => {
        console.error('Error al subir imagen:', error);
      }
    );
  }

  drawBoundingBoxes() {
    const imageElement = new Image();
    imageElement.src = this.imageUrl as string;
  
    imageElement.onload = () => {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
  
      canvas.width = imageElement.width;
      canvas.height = imageElement.height;
  
      ctx!.drawImage(imageElement, 0, 0, canvas.width, canvas.height);
  
      // Dibujar cada detección
      this.detections.forEach((det: any) => {
        const [x1, y1, x2, y2] = det.bbox; // Coordenadas del objeto detectado
        ctx!.strokeStyle = 'red'; // Color del recuadro
        ctx!.lineWidth = 3;
        ctx!.strokeRect(x1, y1, x2 - x1, y2 - y1);
  
        // Etiqueta de la detección
        ctx!.fillStyle = 'red';
        ctx!.font = '16px Arial';
        ctx!.fillText(`${det.class} (${(det.confidence * 100).toFixed(2)}%)`, x1, y1 - 5);
      });
  
      // Convertir canvas a imagen y mostrarlo
      this.imageUrl = canvas.toDataURL();
    };
  }
  
}
