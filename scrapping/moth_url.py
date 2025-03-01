import requests
from bs4 import BeautifulSoup
import json

# URL base de la web
BASE_URL = "https://butterfly-conservation.org"
IDENTIFY_URL = f"{BASE_URL}/moths/identify-a-moth"

# Función para obtener el contenido HTML de una página
def get_soup(url):
    response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"})
    if response.status_code == 200:
        return BeautifulSoup(response.content, 'html.parser')
    else:
        print(f"Error al acceder a {url} - Código: {response.status_code}")
        return None

# Obtener la lista de URLs de mariposas recorriendo todas las páginas
def get_all_butterfly_links():
    butterfly_links = []
    page = 0  # Primera página

    while True:
        print(f"Scrapeando página {page + 1}...")
        soup = get_soup(f"{IDENTIFY_URL}?page={page}")
        
        if not soup:
            break  # Si no hay respuesta, terminamos el scraping

        # Buscar enlaces de mariposas dentro de <h3 class="field-content">
        found_links = []
        for h3 in soup.find_all("h3", class_="field-content"):
            link = h3.find("a", href=True)
            if link:
                full_url = BASE_URL + link["href"]  # Convertir ruta relativa en URL completa
                found_links.append(full_url)

        if not found_links:
            break  # Si en la página no hay más enlaces, hemos terminado

        butterfly_links.extend(found_links)
        page += 1  # Pasamos a la siguiente página

    return list(set(butterfly_links))  # Eliminar duplicados

# Ejecutar la función y obtener todas las URLs
butterfly_urls = get_all_butterfly_links()

# Guardar las URLs en un archivo JSON
with open("urls_moths.json", "w", encoding="utf-8") as f:
    json.dump(butterfly_urls, f, ensure_ascii=False, indent=4)

print(f"\n✅ Se han encontrado {len(butterfly_urls)} URLs y guardado en 'urls_moths.json'")
