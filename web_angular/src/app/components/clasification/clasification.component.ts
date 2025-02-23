import { Component, EventEmitter, Input, Output, OnChanges, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { HttpClient, HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-clasification',
  standalone: true,
  imports: [CommonModule, IonicModule, HttpClientModule],
  templateUrl: './clasification.component.html',
  styleUrls: ['./clasification.component.scss']
})
export class ClasificationComponent implements OnChanges {

  @Input() image: File | null = null; // ✅ Recibe la imagen desde HomePage
  @Input() detections: any[] = []; // ✅ Recibe las detecciones desde HomePage

  classificationResults: { class: string, confidence: number }[] = []; // ✅ Almacena los 5 mejores resultados
  imageUrl: string = ''; // ✅ Almacena la URL de la imagen con recuadros

  apiUrl = 'https://pablogm-1204-tfm-mariposas.hf.space/classify'; // 🔹 Cambia esta URL si es diferente

  constructor(private http: HttpClient, private cdr: ChangeDetectorRef) {}

  ngOnChanges() {
    if (this.image) {
      this.imageUrl = URL.createObjectURL(this.image);
      this.cdr.detectChanges(); // ✅ Forzar actualización para evitar NG0100
      this.drawBoundingBoxes(); // ✅ Dibujar los recuadros en la imagen
      this.classifyImage(); // ✅ Clasificar la imagen automáticamente
    }
  }

  classifyImage() {
    if (!this.image) return;

    const formData = new FormData();
    formData.append('file', this.image);

    console.log('Enviando imagen para clasificación...');

    this.http.post(this.apiUrl, formData).subscribe(
      (response: any) => {
        console.log('Clasificación recibida:', response);
        
        // ✅ Convertir respuesta en una lista de objetos { class, confidence }
        this.classificationResults = response.top_classes.map((className: string, index: number) => ({
          class: className,
          confidence: response.top_confidences[index]
        }));

        this.cdr.detectChanges(); // ✅ Forzar actualización
      },
      (error) => {
        console.error('Error en la clasificación:', error);
      }
    );
  }

  drawBoundingBoxes() {
    const imageElement = new Image();
    imageElement.src = this.imageUrl;

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

      // Convertir canvas a imagen con recuadros
      this.imageUrl = canvas.toDataURL();
      this.cdr.detectChanges(); // ✅ Actualizamos el componente
    };
  }
}