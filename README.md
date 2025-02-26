Logo de la app

# ButterflAI
TFM realizado por [Pablo García Muñoz]() y [Jairo Andrades Bueno]() en el **Master de Inteligencía Artificial y Big Data CPIFP Alan Turing**.

## Justificación del proyecto

Nostros dos siempre hemos querido hacer una aplicación de detección con uso a tiempo real para el TFM, inicialmente se nos ocurrio la idea de hacerlo sobre constelaciones ya que el resultado final podría quedar muy bien visualmente pero despues de probrar vimos que no era el enfoque perfecto para un TFM de este master, por ello seguimos con la idea de detección pero esta vez con **Mariposas** y así creamos **BUTTERFLAI** ya que es algo muy visual y comodo el poder usar una aplicación que ha tiempo real sea capaz de detectar la mariposa y te la classifique para decirte que tipo es.

## Índice

1. Descripción del proyecto
2. Obtención de datos
3. Limpieza de datos

    3.1 Comprobación de los datos
    3.2 Eliminación de nulos
    3.3 Descripción de los datos

4. Exploración y visualización de los datos
5. Preparación de los datos para los algoritmos de *Machine Learning*
6. Entrenamiento del modelo y comprobación del rendimiento
7. Uso de *NPL*
8. Web y Aplicación
9. Conclusiones

## Descripción del proyecto

**ButterlfAI** es una aplicación de detección y clasificación de mariposas a tiempo real con la capacidad de detectar hasta 100 clases de mariposas distintas, la hemos desarrollado en dos vertiente una en pagina web y otra para dispositivos moviles. Las dos hacen uso de un chatbot especializado en mariposas para en el caso de tener alguna duda poder preguntarle.

* Para el diseño tanto de la aplicación movil como de la página web hemos usado figma: [Figma Web](https://www.figma.com/design/ppYnvwKn1cuR7QMSj7lIhE/Untitled?node-id=0-1&t=sqGsiv9wRIYfBdJS-1), [Figma App](https://www.figma.com/design/yZJnqPjqBbwB1zLa1cWf5o/ButterflAI_App?t=sqGsiv9wRIYfBdJS-1)

Estas son las tecnologías que hemos usado para desarrollar este proyecto:
![usos](imgs_readme/usos.png)

### Diagrama del proyecto
![diagrama](imgs_readme/diagrama.png)

Explicación detallada desde abajo hasta arriba:

* **Datos:**
    
    Los datos han sido recogidos desde kaggle ya que había varios dataset con un gran cantidad de fotos que es lo que necesitamos para los dos modelos.
    Estos tres dataset los juntamos en uno sumando las clases ya existente ya añadiendo las nuevas para poder subir el dataset bruto a S3 de AWS.

* **ButterflAI Modelo:**

    Para este TFM hemos usado dos modelos uno es de clasificación que está entrenado desde cero y otro de detección que ha sido creado haciendo *fine-tunning* al modelo de YOLOv8.

    * Clasificación: este modelo lo hemos hecho desde cero usando **TensorFlow** ya que lo usariamos en movil por lo que nos iba a hacer falta convertirlo a **.tflite** para que así este optimizado para moviles.

    * Detección: este modelo ha sido creado desde el modelo de YOLO v8 al cual le hemos hecho **fine-tunning** y así poder detectar las mariposas en las imagenes. YOLO está creado en **Pytorch** por lo que mas adelante está explicado que hemos hecho para usarlo en las dos aplicaciones.

* **Página web:**

    Para hacer uso de los dos modelos creamos una API en **HuggingFace Spaces** con un **Docker** y **FastAPI**, en esta API hay dos endpoints, una para cada modelo.
    La página web está hosteada en **Netlifly**.

* **Aplicación movil:**

    Usa los dos modelos exportados a **.tflite** para así poder optimizar la aplicación ya que usa la camara a tiempo real y no hubiese sido posible conseguir un buen resultado usando una API. La aplicación esta desarrollada en **Flutter**.

* **ChatBot:**

    Las dos aplicaciones tienen **ChatBot** el cual usa la API de **ChatGPT**.

## Obtención de datos

Principalmente buscamos varios dataset que tuviesen lo mismo en comun que son fotos de mariposas, ya que pare el entrenamiento del detector solo necesitamos fotos de mariposas y fotos aleatorios (mas adelante explicamos esto) mientras que para el clasificador necesitamos fotos de mariposas en categorias.

* [butterfly-images40-species](https://www.kaggle.com/datasets/gpiosenka/butterfly-images40-species): Primer dataset utilizado principalmente ya que las imagenes estan clasificadas en carpetas (nombre en ingles) por cada tipo, en total hay 100 tipos entre ellos "MONARCH", "ADONIS", "APPOLLO", etc.

* [butterfly-dataset](https://www.kaggle.com/datasets/veeralakrishna/butterfly-dataset): Segundo dataset utilizado para tener descripciones de las espcies pero de poco nos sirvio ya que solo tenia 10 tipos de mariposas.

* [butterfly-image-classification](https://www.kaggle.com/datasets/phucthaiv02/butterfly-image-classification): Tercer dataset que es como el primero ya que tiene unas 75 clases de mariposas y vienen catalogadas por tipo en un csv.

* [random-images](https://www.kaggle.com/datasets/ezzzio/random-images): Ultimo dataset utilizado para el detector de imagenes ya que haciendo el fine-tunning unicamente con imagenes de mariposas no era muy preciso, pero gracias a añadir imagenes sin mariposas (mas adelante explicado) fue capaz de mejorar la detección.

Para tener una copia de los dataset en la nube por si se nos pierde y ademas de que no nos ocupe mucho espacio en los equipos usamos dos cuadernos **jupyter** para poder subir los dataset a AWS S3 usando las cuentas de *g.educaand*: 
* [Cuaderno de subida](cuadernos/up_awsS3.ipynb)
* [Cuaderno de descarga](cuadernos/down_awsS3.ipynb)

## Limpieza de datos

Para la limpieza de los datos de los datasets hemos divido el proceso en varias partes para que todo sea mas claro y sencillo de explicar y entender ademas de que estan hechos en cuadernos *jupyter*:

### 3.1 Comprobación de los datos

* Nos centramos en el dataset de **butterfly-images40-species** ya que es el que mas imagenes y especies tiene:
```
# Muestra la cantidad de datos para train, valid y test
df['data set'].value_counts()
-------------------------------------------------------
data set
train    12594
test       500
valid      500
Name: count, dtype: int64
```
* Cantidad de datos por cada tipo de mariposa que hay en el conjunto de entrenamiento:
```
df[df['data set'] == 'train']['labels'].value_counts()
--------------------------------------------------------
labels
MOURNING CLOAK         187
GREEN HAIRSTREAK       176
BROWN ARGUS            169
BROOKES BIRDWING       165
SLEEPY ORANGE          152
                      ... 
GOLD BANDED            104
CRIMSON PATCH          103
MALACHITE              103
WOOD SATYR             102
SIXSPOT BURNET MOTH    100
Name: count, Length: 100, dtype: int64
```
Vemos que el mínimo de imágenes es de **100** mientras que el máximo es **187**.

Ahora, sacamos el mínimo y el máximo número de imágenes por especie de los conjuntos de validación y de prueba:
```
df[df['data set'] == 'test']['labels'].value_counts().min(), df[df['data set'] == 'test']['labels'].value_counts().max()
--------------------------------------------------------
(5, 5)
```
```
df[df['data set'] == 'valid']['labels'].value_counts().min(), df[df['data set'] == 'valid']['labels'].value_counts().max()
--------------------------------------------------------
(5, 5)
```
Con esto confirmamos que hay 5 imágenes por cada especie tanto en el conjunto de validación como en el de prueba.

### 3.2 Eliminación de los nulos

* En general las imagenes al estar en datasets de Kaggle suelen venir bien formateadas y no suelen ser nulas pero aun así hicimos esta función para comprobar los valores:

```
def verificar_imagenes(directorio):
    """
    Verifica que las imágenes en un directorio sean válidas.
    
    Parámetros:
        directorio (str): Ruta del directorio donde están las imágenes.
        
    Retorna:
        imágenes_corruptas (list): Lista con las rutas de las imágenes corruptas o no válidas.
    """
    imagenes_corruptas = []
    formatos_validos = {".jpg", ".jpeg", ".png", ".bmp", ".tiff"}

    for archivo in tqdm(os.listdir(directorio), desc="Verificando imágenes"):
        ruta_imagen = os.path.join(directorio, archivo)

        # Verificar que sea un archivo de imagen válido por extensión
        if not any(archivo.lower().endswith(ext) for ext in formatos_validos):
            print(f"Archivo no válido (extensión incorrecta): {ruta_imagen}")
            imagenes_corruptas.append(ruta_imagen)
            continue

        # Intentar abrir la imagen con OpenCV
        try:
            imagen = cv2.imread(ruta_imagen)
            if imagen is None or imagen.size == 0:
                print(f"Imagen corrupta o vacía: {ruta_imagen}")
                imagenes_corruptas.append(ruta_imagen)
        except Exception as e:
            print(f"Error al leer la imagen {ruta_imagen}: {e}")
            imagenes_corruptas.append(ruta_imagen)

    print(f"Total de imágenes corruptas/no válidas encontradas: {len(imagenes_corruptas)}")
    return imagenes_corruptas

# Uso del código
directorio_imagenes = "ruta/a/tu/dataset"
imagenes_invalidas = verificar_imagenes(directorio_imagenes)

# para eliminar las imagenes corruptas
if imagenes_invalidas:
    for img in imagenes_invalidas:
        os.remove(img)
        print(f"Eliminada imagen corrupta: {img}")

print("Verificación completada.")
```
### 3.3 Carga de imágenes
* Creamos una nueva columna `image` en el dataset para guardar todas las imágenes como un array y las normalizamos entre 0 y 1, con un size **(224, 224)**.
```
df['image'] = df['filepaths'].apply(lambda x: img_to_array(load_img(f"../{x}", target_size=(224, 224))) / 255)
```
* Vemos 5 imágenes de prueba
```
df_sample = df[['image', 'labels']].sample(5)
plt.figure(figsize=(15, 15))
for i in range(5):
    plt.subplot(1, 5, i+1)
    plt.imshow(df_sample.iloc[i, 0])
    plt.title(df_sample.iloc[i, 1])
    plt.axis('off')
plt.show()
```
![ejemplos_imgs](imgs_readme/ejemplo_imgs.png)

* Mostramos las 5 primeras filas
```
df.head()
```
| class id | filepaths| labels | data set | image |
|----------|--------------------------|--------|----------|--------|
| 0        | train/ADONIS/001.jpg     | ADONIS | train    | [[[0.0, 0.023529412, 0.019607844], [0.0, 0.050... |
| 0        | train/ADONIS/002.jpg     | ADONIS | train    | [[[0.33333334, 0.29803923, 0.12941177], [0.313... |
| 0        | train/ADONIS/003.jpg     | ADONIS | train    | [[[0.50980395, 0.48235294, 0.3019608], [0.5098... |
| 0        | train/ADONIS/004.jpg     | ADONIS | train    | [[[0.54509807, 0.5254902, 0.29803923], [0.5450... |
| 0        | train/ADONIS/005.jpg     | ADONIS | train    | [[[0.61960787, 0.654902, 0.2901961], [0.619607... |

### 3.4 Creación de diccionario de labels
* Como podemos ver, tenemos una columna `class id` y otra `labels`. Para eliminar esta última, creamos un diccionario que sea `{id: label}` que nos permite obtener el nombre meditante el número de la clase. 
```
dict_name = dict(zip( df['class id'], df['labels']))
dict_name
--------------------------------------------------------
{0: 'ADONIS',
 1: 'AFRICAN GIANT SWALLOWTAIL',
 2: 'AMERICAN SNOOT',
 3: 'AN 88',
 4: 'APPOLLO',
 ...
 95: 'VICEROY',
 96: 'WHITE LINED SPHINX MOTH',
 97: 'WOOD SATYR',
 98: 'YELLOW SWALLOW TAIL',
 99: 'ZEBRA LONG WING'}
```

### 3.5 Descripción de los datos

* Como hemos comentado antes los datos importantes de los datasets son las imágenes pero para el caso del entrenamiento del modelo de **detección** necesitabamos los datos en formato **YOLO** que son las imagenes con las *labels* (etiquetas con la información de cada imagen como las cordenadas de la caja que delimita la mariposa). Por eso usamos **Roboflow** ya que no era eficiente hacer a mas de 1000 imagenes la caja delimitadora a mano y esta página con el plan gratuito nos permitio a 1000 imagenes y usando el modelo de deteccion de **Dino** poder crear un dataset con el formato **YOLO** que es el que necesitabamos.
    * [Link a nuestro dataset subido a **Roboflow**](https://universe.roboflow.com/butterflai/butterflies-detection-sfxwl/dataset/5)

Ejemplo de un label creado por **Dino**:

Cada label tien estos 5 datos: **0** se refiere a la clase que es, en este caso como todas son mariposas le pone clase **0**, los cuatro siguientes valores son los puntos de *xmin, xmax, ymin, ymax* que sirven para saber donde esta la caja delimitadora de la detección.

```0 0.5 0.48671875 0.92890625 0.9015625```

<img src="detector/dataset_final/train/images/image_1_jpg.rf.ddf7ec584529709fd345025297a3e8c3.jpg" alt="alt text" width="300"/>


* Tambien para el modelo de deteccion necesitabamos unas 200 imagenes de objetos aleatorios para que el modelo supiera diferencia entre lo que es una mariposa y no, estos datos tambien son imagenes solo que no tienen un label que les corresponda ya que estas fotos no tiene una mariposa por lo que no tiene una caja delimitadora para la mariposa.

<img src="detector/dataset_final/train/images/resized_image_132.jpg" alt="alt text" width="300"/>


## Exploración y visualización de los datos