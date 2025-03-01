import requests

# URL de prueba
url = "https://butterfly-conservation.org/butterflies/green-hairstreak"

# Hacer la petición con User-Agent para evitar bloqueos
headers = {"User-Agent": "Mozilla/5.0"}
response = requests.get(url, headers=headers)

# Guardar el HTML en un archivo local para inspección
with open("debug_page.html", "w", encoding="utf-8") as f:
    f.write(response.text)

print("\n✅ Se ha guardado el HTML de la página en 'debug_page.html'. Ábrelo para analizarlo.")
