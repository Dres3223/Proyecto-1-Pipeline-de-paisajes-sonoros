"""Pipeline configuration, read from environment variables (and .env)."""

from pathlib import Path

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Typed settings: a missing or malformed variable fails at startup."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # PostgreSQL
    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_user: str
    postgres_password: SecretStr
    postgres_db: str

    # S3-compatible object storage (RustFS locally, AWS S3 later)
    s3_endpoint_url: str | None = "http://localhost:9000"  # None means AWS S3
    s3_access_key: str
    s3_secret_key: SecretStr
    s3_bucket: str = "soundscape"
    s3_region: str = "us-east-1"

    # Ingestion
    ingest_source_dir: Path = Path("data/raw/birdclef/train_soundscapes")
    ingest_source_name: str = "birdclef-2025"
