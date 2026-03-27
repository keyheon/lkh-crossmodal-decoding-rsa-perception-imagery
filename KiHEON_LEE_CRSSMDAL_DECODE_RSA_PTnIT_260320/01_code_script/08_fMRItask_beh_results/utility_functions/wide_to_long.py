from __future__ import annotations

import pandas as pd

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def wide_to_long(
    df: pd.DataFrame,
    subject_col: str,
    mapping: dict[str, str],
    dv_name: str = "Score",
    within_name: str = "Emotion",
) -> pd.DataFrame:
    required = [mapping[k] for k in ["ang", "hap", "sad", "neut"] if mapping.get(k) in df.columns]
    if len(required) < 4:
        missing = set(["ang", "hap", "sad", "neut"]) - {k for k in mapping if mapping[k] in df.columns}
        raise ValueError(f"Missing required columns for ANOVA: {missing}")

    subset = df[[subject_col] + required].copy()
    subset = subset.dropna(subset=required, how="any")
    rename_map = {
        mapping["ang"]: "ang",
        mapping["hap"]: "hap",
        mapping["sad"]: "sad",
        mapping["neut"]: "neut",
    }
    subset = subset.rename(columns=rename_map)
    long_df = subset.melt(
        id_vars=[subject_col],
        value_vars=["ang", "hap", "sad", "neut"],
        var_name=within_name,
        value_name=dv_name,
    )
    return long_df
