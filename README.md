# Pipeline de paisajes sonoros

Pipeline de datos que procesa grabaciones de campo de la Reserva Natural El Silencio (Colombia).

> Proyecto en construcción. Fuente de datos y decisiones: [docs/fuente_de_datos.md](docs/fuente_de_datos.md)

## Preparación
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
bash scripts/descargar_metadatos.sh
bash scripts/listar_archivos.sh
```
