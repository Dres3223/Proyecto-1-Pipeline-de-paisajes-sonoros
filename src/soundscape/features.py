"""Extract audio features from the recordings registered in raw.recordings.

Usage:
    uv run python -m soundscape.features

Each recording is read from S3 into memory and summarised as one row of
numbers: MFCC (mean and std per coefficient), spectral centroid and
bandwidth, RMS energy, zero-crossing rate and duration. A damaged or empty
file is reported as failed instead of stopping the batch.
"""

import io
import logging
from dataclasses import dataclass, field

import librosa
import numpy as np
import soundfile as sf
from psycopg.rows import dict_row
from pydantic import ValidationError

from soundscape.config import Settings
from soundscape.storage import pg_connect, s3_client

log = logging.getLogger("soundscape.features")


@dataclass
class FeatureResult:
    """Outcome for one recording: its features, or why they could not be computed."""

    status: str  # "ok" or "failed"
    features: dict[str, float] = field(default_factory=dict)
    error: str | None = None


def extract_features(audio: np.ndarray, sample_rate: int, n_mfcc: int) -> dict:
    """Summarise a mono signal as a flat dict of features (one value per column)."""
    features = {"duration_s": round(len(audio) / sample_rate, 3)}

    mfcc = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=n_mfcc)
    for i, coefficient in enumerate(mfcc, start=1):
        features[f"mfcc_{i:02d}_mean"] = float(coefficient.mean())
        features[f"mfcc_{i:02d}_std"] = float(coefficient.std())

    centroid = librosa.feature.spectral_centroid(y=audio, sr=sample_rate)
    bandwidth = librosa.feature.spectral_bandwidth(y=audio, sr=sample_rate)
    features["spectral_centroid_hz"] = float(centroid.mean())
    features["spectral_bandwidth_hz"] = float(bandwidth.mean())
    features["rms_mean"] = float(librosa.feature.rms(y=audio).mean())
    features["zcr_mean"] = float(librosa.feature.zero_crossing_rate(audio).mean())
    return features


def analyze(data: bytes, sample_rate: int, n_mfcc: int) -> FeatureResult:
    """Decode an audio file held in memory and extract its features."""
    try:
        # Resamples only if the file's rate differs from sample_rate
        audio, _ = librosa.load(io.BytesIO(data), sr=sample_rate, mono=True)
    except sf.LibsndfileError as error:
        message = f"cannot decode audio: {error.error_string}"
        return FeatureResult("failed", error=message)

    if audio.size == 0:
        # A valid file with no samples decodes without error, so check it here
        return FeatureResult("failed", error="audio has no samples")
    return FeatureResult("ok", extract_features(audio, sample_rate, n_mfcc))


def run(settings: Settings) -> list[tuple[dict, FeatureResult]]:
    """Analyze every registered recording; return (catalog row, result) pairs."""
    s3 = s3_client(settings)

    # raw.recordings is the catalog: only ingested files are processed (lineage)
    with pg_connect(settings, row_factory=dict_row) as conn:
        recordings = conn.execute(
            """
            SELECT sha256, file_name, site_code, recorded_at, s3_key
            FROM raw.recordings
            ORDER BY recorded_at, file_name
            """
        ).fetchall()

    results = []
    for recording in recordings:
        body = s3.get_object(Bucket=settings.s3_bucket, Key=recording["s3_key"])
        result = analyze(
            body["Body"].read(),
            settings.features_sample_rate,
            settings.features_n_mfcc,
        )
        if result.status == "ok":
            log.info("Extracted %s", recording["file_name"])
        else:
            log.warning("Failed %s: %s", recording["file_name"], result.error)
        results.append((recording, result))
    return results


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    # boto3 is chatty at INFO level
    logging.getLogger("botocore").setLevel(logging.WARNING)

    try:
        settings = Settings()
    except ValidationError as error:
        # Report which settings are wrong without echoing their values (secrets)
        for problem in error.errors(include_input=False, include_url=False):
            field_name = ".".join(str(part) for part in problem["loc"])
            log.error("Invalid configuration for %s: %s", field_name, problem["msg"])
        raise SystemExit(1) from None

    results = run(settings)
    ok = sum(result.status == "ok" for _, result in results)
    log.info("Summary: ok=%d failed=%d", ok, len(results) - ok)


if __name__ == "__main__":
    main()
