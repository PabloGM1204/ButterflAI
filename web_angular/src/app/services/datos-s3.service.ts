import Fuse from 'fuse.js';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root'
})
export class datosS3Service {
  private jsonUrl = 'https://info-tmf-butterflai.s3.us-east-1.amazonaws.com/datos/mariposas.json'; // URL pública del JSON en S3
  chatgptUrl = 'https://api.openai.com/v1/chat/completions'; // Endpoint de OpenAI
  apiKey = environment.apiKey;
  private mariposasData: any[] = []; // Almacenar los datos en memoria

  constructor(private http: HttpClient) {
    this.cargarMariposas(); // Cargar los datos al iniciar
  }

  private cargarMariposas() {
    this.http.get<any[]>(this.jsonUrl).subscribe(data => {
      this.mariposasData = data;
      console.log('Datos de mariposas cargados:', this.mariposasData);
    });
  }

  // Buscar mariposa en el JSON o consultar a ChatGPT
  getMariposa(nombre: string): Observable<any> {
    if (!this.mariposasData || this.mariposasData.length === 0) {
      console.warn("Los datos de mariposas aún no han sido cargados.");
      return of(null);
    }

    // Usar Fuse.js para encontrar coincidencias cercanas
    const fuse = new Fuse(this.mariposasData, {
      keys: ["Nombre común"], 
      threshold: 0.3 
    });

    const resultado = fuse.search(nombre.trim());

    if (resultado.length > 0) {
      const mejorCoincidencia = resultado[0].item;
      console.log(`Mejor coincidencia encontrada: '${mejorCoincidencia["Nombre común"]}'`);
      return of(mejorCoincidencia);
    } else {
      console.warn(`No se encontró '${nombre}' en el JSON. Consultando ChatGPT...`);
      return this.getInfoFromChatGPT(nombre);
    }
  }

  private getInfoFromChatGPT(nombre: string): Observable<any> {
    const prompt = `Provide information about the butterfly called '${nombre}'. 
    Respond ONLY in JSON format like this, with NO extra text outside the JSON:
    {
      "Common Name": "${nombre}",
      "Scientific Name": "Scientific name here",
      "Description": "Detailed description here",
      "Habitat": "Where it is usually found"
    }`;

    const body = {
      model: "gpt-4o",
      messages: [{ role: "system", content: "You are a butterfly expert." },
                 { role: "user", content: prompt }],
      max_tokens: 600
    };

    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.apiKey}`
    });

    return this.http.post<any>(this.chatgptUrl, body, { headers }).pipe(
      map(response => {
        let chatResponse = response.choices[0].message.content;
        console.log(`Raw ChatGPT Response: ${chatResponse}`);

        try {
          // Eliminar triple comillas y limpiar espacios extra
          chatResponse = chatResponse.replace(/```json/g, "").replace(/```/g, "").trim();
          
          // Convertir la respuesta a JSON
          const parsedResponse = JSON.parse(chatResponse);

          return {
            "Nombre común": parsedResponse["Common Name"] || nombre,
            "Nombre científico": parsedResponse["Scientific Name"] || "Desconocido",
            "Descripción": parsedResponse["Description"] || "No hay descripción disponible.",
            "Hábitat": parsedResponse["Habitat"] || "Desconocido",
            "IA": true
          };
        } catch (error) {
          console.error("Error parsing ChatGPT response:", error);
          return {
            "Nombre común": nombre,
            "Nombre científico": "Desconocido",
            "Descripción": "La IA no pudo generar información precisa.",
            "Hábitat": "Generado por IA",
            "IA": true
          };
        }
      }),
      catchError(error => {
        console.error('Error al consultar ChatGPT:', error);
        return of(null);
      })
    );
  }


}