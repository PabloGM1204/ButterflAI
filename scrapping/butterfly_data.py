import requests
from bs4 import BeautifulSoup
import json
import time

# Cargar las URLs de las mariposas desde el JSON generado previamente
with open("urls_mariposas.json", "r", encoding="utf-8") as f:
    butterfly_urls = json.load(f)

# Función para obtener el contenido HTML de una página
def get_soup(url):
    response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"})
    if response.status_code == 200:
        return BeautifulSoup(response.content, 'html.parser')
    else:
        print(f"Error al acceder a {url} - Código: {response.status_code}")
        return None

# Función para extraer información de cada mariposa
def extract_butterfly_info(url):
    soup = get_soup(url)
    if not soup:
        return None

    # Extraer nombre común
    try:
        name = soup.find("h1").text.strip()
    except AttributeError:
        name = "No disponible"

    # Extraer nombre científico
    try:
        scientific_name = soup.find("p", class_="sub-heading").text.strip()
    except AttributeError:
        scientific_name = "No disponible"

    # Extraer descripción desde <meta name="description">
    try:
        description = soup.find("meta", attrs={"name": "description"})["content"].strip()
    except (AttributeError, TypeError):
        description = "No disponible"

    # Función para extraer información de listas (<ul><li>)
    def extract_list_data(header_text):
        try:
            section = soup.find("h4", text=header_text)
            if section:
                items = section.find_next("ul").find_all("li")
                return [item.text.strip() for item in items]
        except AttributeError:
            return []
        return []

    # Extraer información de distintas secciones
    size_and_family = extract_list_data("Size and Family")
    conservation_status = extract_list_data("Conservation Status")
    foodplants = extract_list_data("Caterpillar Foodplants")
    lifecycle = extract_list_data("Lifecycle")
    habitat = extract_list_data("Habitat")

    return {
        "Nombre común": name,
        "Nombre científico": scientific_name,
        "Descripción": description,
        "Tamaño y Familia": size_and_family,
        "Estado de conservación": conservation_status,
        "Plantas alimenticias de orugas": foodplants,
        "Ciclo de vida": lifecycle,
        "Hábitat": habitat,
        "URL": url
    }

# Lista para almacenar los datos de las mariposas
butterfly_data = []

# Recorrer todas las URLs y extraer información
for index, url in enumerate(butterfly_urls):
    print(f"[{index+1}/{len(butterfly_urls)}] Extrayendo datos de: {url}")
    data = extract_butterfly_info(url)
    if data:
        butterfly_data.append(data)
    time.sleep(1)  # Pausa de 1 segundo para evitar bloqueos

# Guardar los datos en un archivo JSON
with open("mariposas.json", "w", encoding="utf-8") as f:
    json.dump(butterfly_data, f, ensure_ascii=False, indent=4)

print("\n✅ Los datos de las mariposas se han guardado en 'mariposas.json'")
