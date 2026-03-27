from __future__ import annotations

import pandas as pd

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def summarize_means(df: pd.DataFrame, mapping: dict[str, str], label: str) -> str:
    parts: list[str] = []
    for key in ["ang", "hap", "sad", "neut"]:
        column = mapping.get(key)
        if column in df.columns:
            x = pd.to_numeric(df[column], errors="coerce")
            parts.append(f"{key}: {x.mean():.2f}±{x.std(ddof=1):.2f}")
    return f"{label} means±SD -> " + ", ".join(parts)
