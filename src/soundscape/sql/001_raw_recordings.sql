-- Raw layer: one row per ingested recording, stored as the source describes it.
-- Interpretations (time zone, period of day) belong to dbt staging models.

CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.recordings (
    sha256          char(64)     PRIMARY KEY,  -- content fingerprint (idempotency key)
    file_name       text         NOT NULL UNIQUE,
    site_code       text         NOT NULL,     -- recording site: H02, O201, H8749...
    recorded_at     timestamp    NOT NULL,     -- as written in the file name (assumed local time, UTC-5)
    duration_s      numeric(7,3) NOT NULL,
    sample_rate_hz  integer      NOT NULL,
    channels        smallint     NOT NULL,
    size_bytes      bigint       NOT NULL,
    s3_key          text         NOT NULL,     -- object location in the bucket
    source          text         NOT NULL,     -- e.g. 'birdclef-2025', later 'xeno-canto'
    ingested_at     timestamptz  NOT NULL DEFAULT now()
);
