from __future__ import annotations

import glob
import re
from pathlib import Path

import pandas as pd

from utility_functions.normalize_subject_from_folder import normalize_subject_from_folder
from utility_functions.read_one_accuracy_csv import read_one_accuracy_csv

# ===================================================================
# Merge ROI-wise overall decoding accuracy across subjects
# -------------------------------------------------------------------
# This script merges subject-level ROI decoding outputs into a long
# table for downstream behavior-correlation analyses.
#
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
#
# Input:
#   ROI_results_sessionwise_pairwise.csv for each subject
#
# Output:
#   SubjectOverallAccuracy_long.csv
#   SubjectOverallAccuracy_long.xlsx
# ===================================================================

# User-configurable paths
GLOB_PATTERN = (
    "~/p1*/ROI_results_pairwise.csv" # modify as needed
)

OUT_DIR = (
    "~/decoding/pairwise_libsvm/" # modify as needed
)

# Set ROI_ROOT if ROI_fullpath should be converted to an absolute path.
ROI_ROOT = None


def main() -> None:
    matches = sorted(glob.glob(GLOB_PATTERN))
    if not matches:
        raise FileNotFoundError(f"No CSV files were found for pattern:\n{GLOB_PATTERN}")

    out_dir = Path(OUT_DIR)
    out_dir.mkdir(parents=True, exist_ok=True)

    dfs = []
    for match in matches:
        csv_path = Path(match)
        try:
            df = read_one_accuracy_csv(csv_path, roi_root=ROI_ROOT)
            dfs.append(df)
        except Exception as exc:
            print(f"[WARN] Skipping {csv_path}: {exc}")

    if not dfs:
        raise RuntimeError("No valid decoding CSV files were parsed.")

    merged = pd.concat(dfs, ignore_index=True)
    merged.sort_values(by=["Subject_ID", "ROI"], inplace=True)

    csv_out = out_dir / "SubjectOverallAccuracy_long.csv"
    xlsx_out = out_dir / "SubjectOverallAccuracy_long.xlsx"

    merged.to_csv(csv_out, index=False)
    with pd.ExcelWriter(xlsx_out) as writer:
        merged.to_excel(writer, sheet_name="overall_only", index=False)

    n_subjects = merged["Subject"].nunique()
    n_rois = merged["ROI"].nunique()

    print("[Done]")
    print(f"Saved CSV : {csv_out}")
    print(f"Saved XLSX: {xlsx_out}")
    print(f"Subjects  : {n_subjects}")
    print(f"ROIs      : {n_rois}")
    print(f"Rows      : {len(merged)}")


if __name__ == "__main__":
    main()
