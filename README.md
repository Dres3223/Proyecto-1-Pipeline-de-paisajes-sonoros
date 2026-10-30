# Soundscape Data Pipeline

Data pipeline that processes field recordings from El Silencio Nature Reserve (Colombia).

> Work in progress. Data source and decisions: [docs/data_source.md](docs/data_source.md)

## Setup
```bash
uv sync
uv run pre-commit install   # enable the git hooks (once)
uv run bash scripts/download_metadata.sh
uv run bash scripts/list_files.sh
uv run bash scripts/download_sample.sh   # 16 recordings (~8 MB) for local development
```

## License
The code is released under the [MIT](LICENSE) license.

The data is **not** part of this repository nor covered by that license: the BirdCLEF+ 2025 dataset keeps its own [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license (non-commercial use, with attribution). The pipeline downloads it directly from Kaggle.
