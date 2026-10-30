"""End-to-end tests against the Docker services (PostgreSQL and RustFS).

They use their own database and bucket, so they never touch the real data,
and are skipped when the services are not running (docker compose up -d).
Run only the fast tests with: uv run pytest -m "not integration"
"""

import io

import numpy as np
import psycopg
import pyarrow.parquet as pq
import pytest
import soundfile as sf
from botocore.exceptions import BotoCoreError, ClientError
from psycopg import sql

from soundscape import features, ingest
from soundscape.config import Settings
from soundscape.storage import pg_connect, s3_client

pytestmark = pytest.mark.integration

TEST_DB = "soundscape_test"
TEST_BUCKET = "soundscape-test"
SAMPLE_RATE = 32000
# Two sites and two months, so features land in two partitions
FILE_NAMES = ["T01_20230422_014500.ogg", "T02_20230512_060000.ogg"]


def write_tone(path, frequency_hz: float) -> None:
    t = np.arange(SAMPLE_RATE) / SAMPLE_RATE  # one second
    sf.write(path, 0.5 * np.sin(2 * np.pi * frequency_hz * t), SAMPLE_RATE)


@pytest.fixture
def settings(tmp_path):
    """Settings pointing at an empty test database, bucket and source folder."""
    base = Settings()
    try:
        with pg_connect(base, autocommit=True, connect_timeout=2) as conn:
            exists = conn.execute(
                "SELECT 1 FROM pg_database WHERE datname = %s", (TEST_DB,)
            ).fetchone()
            if not exists:
                conn.execute(
                    sql.SQL("CREATE DATABASE {}").format(sql.Identifier(TEST_DB))
                )
        s3_client(base).list_buckets()
    except (psycopg.OperationalError, BotoCoreError, ClientError) as error:
        pytest.skip(f"services not available: {error}")

    test = base.model_copy(
        update={
            "postgres_db": TEST_DB,
            "s3_bucket": TEST_BUCKET,
            "ingest_source_dir": tmp_path,
        }
    )

    # Start from a clean state: no tables, no objects
    with pg_connect(test, autocommit=True) as conn:
        conn.execute("DROP SCHEMA IF EXISTS raw CASCADE")
    s3 = s3_client(test)
    ingest.ensure_bucket(s3, TEST_BUCKET)
    for obj in s3.list_objects_v2(Bucket=TEST_BUCKET).get("Contents", []):
        s3.delete_object(Bucket=TEST_BUCKET, Key=obj["Key"])

    for i, name in enumerate(FILE_NAMES):
        write_tone(tmp_path / name, frequency_hz=1000 * (i + 1))
    return test


def object_keys(settings: Settings, prefix: str = "") -> list[str]:
    s3 = s3_client(settings)
    response = s3.list_objects_v2(Bucket=settings.s3_bucket, Prefix=prefix)
    return sorted(obj["Key"] for obj in response.get("Contents", []))


def test_ingest_is_idempotent(settings):
    first = ingest.run(settings)
    second = ingest.run(settings)

    assert first == {"loaded": 2, "skipped": 0, "rejected": 0}
    assert second == {"loaded": 0, "skipped": 2, "rejected": 0}
    with pg_connect(settings) as conn:
        (rows,) = conn.execute("SELECT count(*) FROM raw.recordings").fetchone()
    assert rows == 2
    assert len(object_keys(settings, "raw/")) == 2


def test_ingest_rejects_changed_content(settings):
    ingest.run(settings)
    write_tone(settings.ingest_source_dir / FILE_NAMES[0], frequency_hz=440)

    counts = ingest.run(settings)

    assert counts == {"loaded": 0, "skipped": 1, "rejected": 1}


def test_ingest_rejects_damaged_audio_without_stopping(settings):
    (settings.ingest_source_dir / "T03_20230422_014500.ogg").write_bytes(b"not audio")

    counts = ingest.run(settings)

    assert counts == {"loaded": 2, "skipped": 0, "rejected": 1}
    assert len(object_keys(settings, "raw/")) == 2  # nothing uploaded for it


def test_features_write_partitioned_parquet_and_are_idempotent(settings):
    ingest.run(settings)

    results = features.run(settings)
    first = object_keys(settings, "features")
    features.run(settings)

    assert [result.status for _, result in results] == ["ok", "ok"]
    assert first == [
        "features/site=T01/month=2023-04/features.parquet",
        "features/site=T02/month=2023-05/features.parquet",
        "features_failed/failed.parquet",
    ]
    assert object_keys(settings, "features") == first  # re-run adds nothing

    body = s3_client(settings).get_object(Bucket=TEST_BUCKET, Key=first[0])["Body"]
    table = pq.read_table(io.BytesIO(body.read()))
    assert table.schema == features.FEATURES_SCHEMA
    assert table.column("spectral_centroid_hz")[0].as_py() == pytest.approx(
        1000, rel=0.05
    )
