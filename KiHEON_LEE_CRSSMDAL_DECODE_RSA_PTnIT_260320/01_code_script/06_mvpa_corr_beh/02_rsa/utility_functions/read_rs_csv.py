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
def read_rs_csv(path: str | Path) -> pd.DataFrame:
    """Read an RS table exported from MATLAB and standardize key columns."""
    df = pd.read_csv(path, sep=None, engine="python")
    df.rename(columns={c: c.strip() for c in df.columns}, inplace=True)

    if "Subject" not in df.columns:
        raise ValueError("The RS file must contain a 'Subject' column (for example, 'P101').")

    if "RS_spearman" not in df.columns:
        matches = [c for c in df.columns if c.lower() == "rs_spearman"]
        if matches:
            df.rename(columns={matches[0]: "RS_spearman"}, inplace=True)
        else:
            raise ValueError("The RS file must contain an 'RS_spearman' column.")

    df["Subject_ID"] = df["Subject"].astype(str).str.extract(r"(\d+)").astype(int)

    def short_name(value: object) -> str:
        try:
            return Path(str(value)).stem
        except Exception:
            s = str(value)
            s = s.split("/")[-1]
            return s.split("\\")[-1].split(".")[0]

    df["ROI_short"] = df["ROI"].apply(short_name)
    return df[["ROI", "ROI_short", "Subject_ID", "RS_spearman"]].copy()
