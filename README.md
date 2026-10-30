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

cp .env.example .env    # then replace the placeholder secrets
docker compose up -d    # start PostgreSQL and RustFS
docker compose ps       # both services should be "healthy"
```

| Service | URL | Purpose |
|---|---|---|
| PostgreSQL 18 | `localhost:5432` | Recording metadata and audio features |
| RustFS (S3 API) | `http://localhost:9000` | Raw audio files (S3-compatible object storage) |
| RustFS console | http://localhost:9001/rustfs/console/ | Browse buckets in the browser |

Stop the services with `docker compose down`; data is kept in Docker volumes.

## Ingest
```bash
uv run python -m soundscape.ingest   # upload recordings to S3 and register them in Postgres
uv run pytest                        # run the tests
```
The ingestion is idempotent: re-running it skips recordings already registered
(by SHA-256). Files land in `s3://soundscape/raw/<source>/site=<site>/date=<date>/`
and their metadata in the `raw.recordings` table.
Why RustFS instead of MinIO: [ADR 0001](docs/adr/0001-s3-compatible-storage.md).

## License
The code is released under the [MIT](LICENSE) license.

The data is **not** part of this repository nor covered by that license: the BirdCLEF+ 2025 dataset keeps its own [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license (non-commercial use, with attribution). The pipeline downloads it directly from Kaggle.
