import { Component, Input, OnChanges, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { datosS3Service } from 'src/app/services/datos-s3.service';

@Component({
  selector: 'app-clasification',
  standalone: true,
  imports: [CommonModule, IonicModule, HttpClientModule],
  templateUrl: './clasification.component.html',
  styleUrls: ['./clasification.component.scss']
})
export class ClasificationComponent implements OnChanges {

  @Input() image: File | null = null; // Recibe la imagen desde HomePage
  @Input() detections: any[] = []; // Recibe las detecciones desde HomePage

  classificationResults: { class: string, confidence: number }[] = []; // Almacena los 5 mejores resultados
  imageUrl: string = ''; // Almacena la URL de la imagen

  apiUrl = 'https://pablogm-1204-tfm-mariposas.hf.space/classify'; // Cambia esta URL si es diferente
  clasificacionResultado: any = null;
  confianza: number = 0;
  mariposaClasificada: any = null;
  cargandoInfo: boolean = false; // Para mostrar mensaje de carga en UI
  esGeneradoPorIA: boolean | undefined;

  constructor(
    private http: HttpClient, 
    private cdr: ChangeDetectorRef,
    private datosService: datosS3Service
  ) {}

  ngOnChanges() {
    if (this.image) {
      // Resetear datos de la mariposa cuando se cambia la imagen
      this.mariposaClasificada = null;
      this.clasificacionResultado = null;
      this.confianza = 0;
      this.cargandoInfo = false;

      this.imageUrl = URL.createObjectURL(this.image);
      this.cdr.detectChanges(); // Forzar actualización UI
      this.classifyImage(); // Clasificar la imagen automáticamente
    }
}


  async classifyImage() {
    if (!this.image) return;

    const formData = new FormData();
    formData.append('file', this.image);

    console.log('Enviando imagen para clasificación...');

    if (this.detections.length > 0) {
      try {
        const response: any = await this.http.post(this.apiUrl, formData).toPromise();
        console.log('Clasificación recibida:', response);

        // Convertimos respuesta en lista de { class, confidence }
        this.classificationResults = response.top_classes.map((className: string, index: number) => ({
          class: className,
          confidence: response.top_confidences[index]
        }));

        if (this.classificationResults.length > 0) {
          // Obtener la mariposa con mayor confianza
          const topMariposa = this.classificationResults.reduce((max, obj) => 
            obj.confidence > max.confidence ? obj : max
          );

          console.log("Mariposa con mayor confianza:", topMariposa);

          // Guardamos el nombre y confianza
          this.clasificacionResultado = topMariposa;
          this.confianza = topMariposa.confidence;

          // Buscar la mariposa en el JSON o ChatGPT
          this.buscarMariposa(topMariposa.class);
        }
      } catch (error) {
        console.error('Error en la clasificación:', error);
      }
    } else {
      console.log('No se detectaron objetos.');
      this.classificationResults = [];
    }
  }

  buscarMariposa(nombre: string) {
    this.cargandoInfo = true; // Mostramos "Cargando información..."
    this.esGeneradoPorIA = false; // Inicialmente asumimos que no es IA
    this.cdr.detectChanges(); // Forzar actualización UI
  
    this.datosService.getMariposa(nombre).subscribe(mariposa => {
      if (mariposa) {
        this.mariposaClasificada = mariposa;
        this.esGeneradoPorIA = false; // Se encontró en el JSON, no es generado por IA
        console.log('Datos de la mariposa clasificada:', mariposa);
      } else {
        console.warn('No se encontró en el JSON, consultando ChatGPT...');
        this.esGeneradoPorIA = true; // Ahora sí marcamos que es IA antes de asignar datos
        console.log('esGeneradoPorIA:', this.esGeneradoPorIA);
        this.mariposaClasificada = {
          "Nombre común": nombre,
          "Nombre científico": "Desconocido",
          "Descripción": "Generando información...",
          "Hábitat": "Desconocido"
        };
        this.cdr.detectChanges();
      }
      this.cargandoInfo = false; // Ocultamos mensaje de carga
      this.cdr.detectChanges(); // Forzar actualización de UI después de cambios
    });
  }
  

  leerDescripcion() {
    if (!this.mariposaClasificada || !this.mariposaClasificada["Descripción"]) {
      console.warn("No hay descripción disponible para leer.");
      return;
    }
  
    // Crear el mensaje de voz
    const speech = new SpeechSynthesisUtterance(this.mariposaClasificada["Descripción"]);
    speech.lang = "en-US"; // Idioma inglés
    speech.rate = 1; // Velocidad normal
    speech.pitch = 1; // Tono normal
    speech.volume = 1; // Volumen normal
  
    // Reproducir el texto en voz alta
    window.speechSynthesis.speak(speech);
  }
  

}
