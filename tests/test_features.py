import io

import numpy as np
import pytest
import soundfile as sf

from soundscape.features import analyze

SAMPLE_RATE = 32000


def tone(frequency_hz: float, seconds: float) -> np.ndarray:
    """A pure sine wave: its spectral centroid is known in advance."""
    t = np.arange(int(SAMPLE_RATE * seconds)) / SAMPLE_RATE
    return (0.5 * np.sin(2 * np.pi * frequency_hz * t)).astype(np.float32)


def encode(audio: np.ndarray, file_format: str = "OGG") -> bytes:
    buffer = io.BytesIO()
    sf.write(buffer, audio, SAMPLE_RATE, format=file_format)
    return buffer.getvalue()


def test_tone_features():
    result = analyze(encode(tone(1000, 2)), SAMPLE_RATE, n_mfcc=20)

    assert result.status == "ok"
    assert result.error is None
    assert result.features["duration_s"] == pytest.approx(2.0)
    # A 1 kHz tone concentrates its energy at 1 kHz
    assert result.features["spectral_centroid_hz"] == pytest.approx(1000, rel=0.05)
    assert result.features["rms_mean"] > 0


def test_n_mfcc_sets_the_length_of_the_lists():
    result = analyze(encode(tone(1000, 1)), SAMPLE_RATE, n_mfcc=13)

    assert len(result.features["mfcc_mean"]) == 13
    assert len(result.features["mfcc_std"]) == 13


def test_other_sample_rate_is_resampled():
    # Ask for 16 kHz from a 32 kHz file: duration must not change
    result = analyze(encode(tone(1000, 2)), sample_rate=16000, n_mfcc=20)

    assert result.status == "ok"
    assert result.features["duration_s"] == pytest.approx(2.0)


@pytest.mark.parametrize(
    "data",
    [
        b"",  # empty file
        b"not an audio file" * 10,  # damaged file
        encode(np.zeros(0, dtype=np.float32), "WAV"),  # valid file, no samples
    ],
)
def test_bad_audio_fails_without_raising(data):
    result = analyze(data, SAMPLE_RATE, n_mfcc=20)

    assert result.status == "failed"
    assert result.error
    assert result.features == {}
