# Fuente de datos

## Decisión
- **Principal (lote):** BirdCLEF+ 2025, Kaggle — https://www.kaggle.com/competitions/birdclef-2025/data
  Grabaciones de la Reserva Natural El Silencio, Magdalena Medio (Colombia). 206 especies (aves, anfibios, mamíferos, insectos). Audio OGG a 32 kHz.
  Licencia CC BY-NC-SA 4.0: uso no comercial, citando la fuente. Los audios no se suben al repositorio.
- **Secundaria (incremental):** API de Xeno-canto, filtrada por Colombia. Requiere clave de API.

## Qué se descarga
| Archivo | Uso |
|---|---|
| `train.csv`, `taxonomy.csv` | Metadatos, completos |
| `train_soundscapes/` | Subconjunto de hasta 2 GB, repartido en fechas y horas |
| `train_audio/` | No se descarga (reservado para el Proyecto 3) |

## Presupuesto de disco (12,45 GB libres al iniciar)
| Uso | Máximo |
|---|---|
| Paisajes sonoros BirdCLEF | 2 GB |
| Metadatos | < 50 MB |
| Audios de Xeno-canto | 500 MB (se borran tras extraer características) |
| Datos procesados | 200 MB |
| Entorno de Python y Docker | 4 GB |
