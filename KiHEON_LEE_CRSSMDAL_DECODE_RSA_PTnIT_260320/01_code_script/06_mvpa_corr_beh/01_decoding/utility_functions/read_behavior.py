from __future__ import annotations

import pandas as pd

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def read_behavior(path: str) -> pd.DataFrame:
    """
    Read the behavioral CSV and ensure that Subject_ID is present and numeric.
    """
    beh = pd.read_csv(path)

    if "Subject_ID" not in beh.columns:
        candidates = [c for c in beh.columns if c.lower() in {"subject", "subj", "participant", "id"}]
        if candidates:
            beh["Subject_ID"] = beh[candidates[0]].astype(str).str.extract(r"(\d+)").astype(int)
        else:
            raise ValueError("Behavior CSV must contain 'Subject_ID' or a recognizable subject column.")

    beh["Subject_ID"] = beh["Subject_ID"].astype(int)
    return beh
