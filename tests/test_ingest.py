from datetime import datetime

import pytest

from soundscape.ingest import RecordingName, build_s3_key, parse_file_name


@pytest.mark.parametrize(
    ("file_name", "site_code", "recorded_at"),
    [
        ("H02_20230422_014500.ogg", "H02", datetime(2023, 4, 22, 1, 45, 0)),
        # Irregular site codes found in the dataset
        ("O201_20230512_011500.ogg", "O201", datetime(2023, 5, 12, 1, 15, 0)),
        ("H8749_20230427_084000.ogg", "H8749", datetime(2023, 4, 27, 8, 40, 0)),
    ],
)
def test_parse_file_name_valid(file_name, site_code, recorded_at):
    assert parse_file_name(file_name) == RecordingName(site_code, recorded_at)


@pytest.mark.parametrize(
    "file_name",
    [
        "H02_20230422_014500.wav",  # wrong extension
        "h02_20230422_014500.ogg",  # lowercase site
        "H02_2023042_014500.ogg",  # short date
        "H02-20230422-014500.ogg",  # wrong separator
        "H02_20230231_014500.ogg",  # 31 February does not exist
        "H02_20230422_256000.ogg",  # hour 25 does not exist
    ],
)
def test_parse_file_name_invalid(file_name):
    with pytest.raises(ValueError):
        parse_file_name(file_name)


def test_build_s3_key_is_hive_partitioned():
    name = RecordingName("H02", datetime(2023, 4, 22, 1, 45, 0))
    key = build_s3_key("birdclef-2025", name, "H02_20230422_014500.ogg")
    expected = "raw/birdclef-2025/site=H02/date=2023-04-22/H02_20230422_014500.ogg"
    assert key == expected
