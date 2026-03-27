from __future__ import annotations

from pathlib import Path

import pandas as pd

from utility_functions.normalize_subject_from_folder import normalize_subject_from_folder

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def read_one_accuracy_csv(csv_path: Path, roi_root: str | None = None) -> pd.DataFrame:
    """
    Read one subject-level decoding accuracy CSV and return a standardized long table.

    Expected columns in the input:
        ROI
        OverallAccuracy_pairwise_minus_chance_percent
    """
    df = pd.read_csv(csv_path, sep=None, engine="python")
    df.rename(columns={c: c.strip() for c in df.columns}, inplace=True)

    required = ["ROI", "OverallAccuracy_pairwise_minus_chance_percent"]
    missing = [col for col in required if col not in df.columns]
    if missing:
        raise ValueError(f"Missing columns in {csv_path}: {missing}")

    df = df[required].copy()
    df.rename(
        columns={"OverallAccuracy_pairwise_minus_chance_percent": "Accuracy_minus_Chance(%)"},
        inplace=True,
    )

    subj_folder = csv_path.parent.name
    subj = normalize_subject_from_folder(subj_folder)
    subject_id = int("".join(ch for ch in subj if ch.isdigit()))

    df["Subject"] = subj
    df["Subject_ID"] = subject_id

    if roi_root is None:
        df["ROI_fullpath"] = df["ROI"].astype(str)
    else:
        df["ROI_fullpath"] = [str(Path(roi_root) / roi) for roi in df["ROI"].astype(str)]

    df = df[["ROI_fullpath", "ROI", "Subject", "Subject_ID", "Accuracy_minus_Chance(%)"]]
    return df
