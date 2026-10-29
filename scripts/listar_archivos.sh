#!/usr/bin/env bash
# Kaggle entrega la lista de archivos por páginas. Este script recorre todas
# las páginas y guarda:
#   - lista_archivos_completa.txt : todos los archivos (nombre y tamaño en bytes)
#   - soundscapes_disponibles.txt : solo los de train_soundscapes/
#
# Uso (desde la carpeta del proyecto, con el entorno activado):
#   bash scripts/listar_archivos.sh

set -euo pipefail

COMPETENCIA="birdclef-2025"
DESTINO="data/raw/birdclef"
TAMANO_PAGINA="${TAMANO_PAGINA:-200}"

COMPLETA="$DESTINO/lista_archivos_completa.txt"
SOUNDSCAPES="$DESTINO/soundscapes_disponibles.txt"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

mkdir -p "$DESTINO"
: > "$COMPLETA"

token=""
pagina=1
while : ; do
  if [ -z "$token" ]; then
    kaggle competitions files -c "$COMPETENCIA" --page-size "$TAMANO_PAGINA" > "$TMP"
  else
    kaggle competitions files -c "$COMPETENCIA" --page-size "$TAMANO_PAGINA" --page-token "$token" > "$TMP"
  fi

  # Filas de archivos: la primera columna es una ruta y la segunda un número
  awk '$2 ~ /^[0-9]+$/ && $1 ~ /\./ {print $1, $2}' "$TMP" >> "$COMPLETA"

  token="$(sed -n 's/^Next Page Token = //p' "$TMP")"
  printf '\r>> Página %d leída (%d archivos en total)' "$pagina" "$(wc -l < "$COMPLETA")"
  [ -z "$token" ] && break
  pagina=$((pagina + 1))
done
echo

grep '^train_soundscapes/' "$COMPLETA" > "$SOUNDSCAPES" || true

n=$(wc -l < "$SOUNDSCAPES" | tr -d ' ')
bytes=$(awk '{s += $2} END {print s + 0}' "$SOUNDSCAPES")
echo ">> Archivos en total:        $(wc -l < "$COMPLETA" | tr -d ' ')"
echo ">> Paisajes sonoros:         $n"
echo ">> Peso total de los paisajes: $(awk -v b="$bytes" 'BEGIN {printf "%.2f GB", b / 1e9}')"
echo ">> Ejemplos:"
head -5 "$SOUNDSCAPES"
