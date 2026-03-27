from __future__ import annotations

from pathlib import Path

import pandas as pd

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def read_accuracy_overall(path: str) -> pd.DataFrame:
    """
    Read the merged overall decoding accuracy CSV.

    Expected columns:
        ROI_fullpath
        ROI
        Subject
        Subject_ID
        Accuracy_minus_Chance(%)
    """
    df = pd.read_csv(path)
    df.rename(columns={c: c.strip() for c in df.columns}, inplace=True)

    required = {"ROI", "Subject", "Subject_ID", "Accuracy_minus_Chance(%)"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"Accuracy file is missing columns: {sorted(missing)}")

    out = df.copy()
    out["Subject_ID"] = out["Subject_ID"].astype(int)
    out["ROI_short"] = out["ROI"].apply(lambda s: Path(str(s)).stem)

    return out[["ROI", "ROI_short", "Subject", "Subject_ID", "Accuracy_minus_Chance(%)"]].copy()
