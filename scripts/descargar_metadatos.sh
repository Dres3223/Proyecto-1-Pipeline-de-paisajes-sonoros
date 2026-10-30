#!/usr/bin/env bash
# Descarga la lista de archivos y los metadatos de BirdCLEF+ 2025.
# No descarga audio: eso lo hace un script aparte con un subconjunto controlado.
#
# Uso (desde la carpeta del proyecto):
#   uv run bash scripts/descargar_metadatos.sh

set -euo pipefail

COMPETENCIA="birdclef-2025"
DESTINO="data/raw/birdclef"
ARCHIVOS=("train.csv" "taxonomy.csv" "recording_location.txt")

# 1. Comprobaciones previas
if ! command -v kaggle >/dev/null 2>&1; then
  echo "ERROR: no encuentro el comando 'kaggle'."
  echo "Instala las dependencias con: uv sync"
  echo "y ejecuta el script con:      uv run bash scripts/descargar_metadatos.sh"
  exit 1
fi

if [ ! -f "$HOME/.kaggle/access_token" ] && [ ! -f "$HOME/.kaggle/kaggle.json" ] \
   && [ -z "${KAGGLE_API_TOKEN:-}" ] && [ -z "${KAGGLE_KEY:-}" ]; then
  echo "ERROR: no encuentro tus credenciales de Kaggle."
  echo "Guarda tu token en ~/.kaggle/access_token (chmod 600) o define KAGGLE_API_TOKEN."
  exit 1
fi

mkdir -p "$DESTINO"

# 2. Lista de archivos de la competencia (con tamaños)
echo ">> Guardando la lista de archivos en $DESTINO/lista_archivos.txt"
kaggle competitions files -c "$COMPETENCIA" > "$DESTINO/lista_archivos.txt"

# 3. Metadatos (se salta lo que ya esté descargado: el script se puede repetir)
for archivo in "${ARCHIVOS[@]}"; do
  if [ -f "$DESTINO/$archivo" ]; then
    echo ">> $archivo ya existe, lo salto"
    continue
  fi
  echo ">> Descargando $archivo"
  kaggle competitions download -c "$COMPETENCIA" -f "$archivo" -p "$DESTINO"
  if [ -f "$DESTINO/$archivo.zip" ]; then
    unzip -o -q "$DESTINO/$archivo.zip" -d "$DESTINO"
    rm "$DESTINO/$archivo.zip"
  fi
done

# 4. Resumen
echo
echo ">> Archivos descargados:"
ls -lh "$DESTINO"
echo
echo ">> Primeras filas de train.csv:"
head -3 "$DESTINO/train.csv"
echo
echo ">> Espacio libre en disco:"
df -h "$HOME" | tail -1
