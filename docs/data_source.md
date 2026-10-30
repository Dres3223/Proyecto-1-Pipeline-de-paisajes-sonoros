# Data source

## Decision
- **Primary (batch):** BirdCLEF+ 2025, Kaggle — https://www.kaggle.com/competitions/birdclef-2025/data
  Recordings from El Silencio Nature Reserve, Middle Magdalena (Colombia). 206 species (birds, amphibians, mammals, insects). OGG audio at 32 kHz.
  License CC BY-NC-SA 4.0: non-commercial use, with attribution. Audio files are not committed to the repository.
- **Secondary (incremental):** Xeno-canto API, filtered to Colombia. Requires an API key.

## What gets downloaded
| File | Use |
|---|---|
| `train.csv`, `taxonomy.csv` | Metadata, in full |
| `train_soundscapes/` | Subset of up to 2 GB, spread across dates and hours |
| `train_audio/` | Not downloaded (reserved for Project 3) |

## Disk budget (12.45 GB free at start)
| Use | Maximum |
|---|---|
| BirdCLEF soundscapes | 2 GB |
| Metadata | < 50 MB |
| Xeno-canto recordings | 500 MB (deleted after feature extraction) |
| Processed data | 200 MB |
| Python environment and Docker | 4 GB |
