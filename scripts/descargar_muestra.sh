#!/usr/bin/env bash
# Descarga la muestra fija de paisajes sonoros para desarrollo local.
# La lista de audios está en scripts/muestra_desarrollo.txt (16 audios, ~8 MB).
#
# Uso (desde la carpeta del proyecto, con el entorno activado):
#   bash scripts/descargar_muestra.sh

set -euo pipefail

COMPETENCIA="birdclef-2025"
LISTA="scripts/muestra_desarrollo.txt"
DESTINO="data/raw/birdclef/train_soundscapes"

# 1. Comprobaciones previas
if ! command -v kaggle >/dev/null 2>&1; then
  echo "ERROR: no encuentro el comando 'kaggle'."
  echo "Activa el entorno con: source .venv/bin/activate"
  exit 1
fi

if [ ! -f "$LISTA" ]; then
  echo "ERROR: no encuentro la lista $LISTA"
  exit 1
fi

mkdir -p "$DESTINO"

# 2. Descarga (se salta lo que ya esté descargado: el script se puede repetir)
descargados=0
saltados=0
while read -r archivo; do
  case "$archivo" in ''|\#*) continue ;; esac

  if [ -f "$DESTINO/$archivo" ]; then
    saltados=$((saltados + 1))
    continue
  fi
  echo ">> Descargando $archivo"
  # Kaggle conserva la subcarpeta del archivo, por eso se descarga en la carpeta padre
  kaggle competitions download -c "$COMPETENCIA" -f "train_soundscapes/$archivo" -p "$(dirname "$DESTINO")" -q
  if [ -f "$DESTINO/$archivo.zip" ]; then
    unzip -o -q "$DESTINO/$archivo.zip" -d "$DESTINO"
    rm "$DESTINO/$archivo.zip"
  fi
  descargados=$((descargados + 1))
done < "$LISTA"

# 3. Resumen
echo
echo ">> Descargados: $descargados | Ya existían: $saltados"
echo ">> Audios en $DESTINO: $(find "$DESTINO" -name '*.ogg' | wc -l | tr -d ' ') ($(du -sh "$DESTINO" | cut -f1))"
