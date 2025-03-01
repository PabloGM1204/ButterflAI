import boto3

# Configuración
BUCKET_NAME = "info-tmf-butterflai"  # Cambia esto por el nombre de tu bucket
FILE_NAME = "moths.json"  # Archivo que queremos subir
S3_OBJECT_NAME = "datos/moths.json"  # Ruta en S3 donde se guardará

# Credenciales de AWS
aws_id = ""
aws_key = ""
aws_token = ""
region = ""


# Crear cliente de S3
s3 = boto3.client('s3', aws_access_key_id=aws_id, aws_secret_access_key=aws_key,aws_session_token=aws_token,region_name=region)

# Subir archivo
try:
    s3.upload_file(FILE_NAME, BUCKET_NAME, S3_OBJECT_NAME)
    print(f"✅ Archivo '{FILE_NAME}' subido exitosamente a s3://{BUCKET_NAME}/{S3_OBJECT_NAME}")
except Exception as e:
    print(f"❌ Error subiendo el archivo: {e}")
