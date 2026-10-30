# Pipeline de paisajes sonoros

Pipeline de datos que procesa grabaciones de campo de la Reserva Natural El Silencio (Colombia).

> Proyecto en construcción. Fuente de datos y decisiones: [docs/fuente_de_datos.md](docs/fuente_de_datos.md)

## Preparación
```bash
uv sync
uv run bash scripts/descargar_metadatos.sh
uv run bash scripts/listar_archivos.sh
uv run bash scripts/descargar_muestra.sh   # 16 audios (~8 MB) para desarrollo local
```
