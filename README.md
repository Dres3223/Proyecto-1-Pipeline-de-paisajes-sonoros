# Pipeline de paisajes sonoros

Pipeline de datos que procesa grabaciones de campo de la Reserva Natural El Silencio (Colombia).

> Proyecto en construcción. Fuente de datos y decisiones: [docs/fuente_de_datos.md](docs/fuente_de_datos.md)

## Preparación
```bash
uv sync
uv run pre-commit install   # activa los hooks de git (una sola vez)
uv run bash scripts/descargar_metadatos.sh
uv run bash scripts/listar_archivos.sh
uv run bash scripts/descargar_muestra.sh   # 16 audios (~8 MB) para desarrollo local
```

## Licencia
El código está bajo licencia [MIT](LICENSE).

Los datos **no** forman parte de este repositorio ni de esa licencia: el dataset BirdCLEF+ 2025 conserva su propia licencia [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) (uso no comercial, citando la fuente). El pipeline los descarga directamente desde Kaggle.
