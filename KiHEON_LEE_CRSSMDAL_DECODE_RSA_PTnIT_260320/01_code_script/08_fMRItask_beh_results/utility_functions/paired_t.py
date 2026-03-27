from __future__ import annotations

import numpy as np
import pandas as pd
from scipy import stats

from utility_functions.cohens_dz_from_diff import cohens_dz_from_diff

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def paired_t(df: pd.DataFrame, col_emotion: str, col_neutral: str) -> dict:
    a = pd.to_numeric(df[col_emotion], errors="coerce").to_numpy()
    b = pd.to_numeric(df[col_neutral], errors="coerce").to_numpy()
    mask = ~np.isnan(a) & ~np.isnan(b)
    a = a[mask]
    b = b[mask]
    n = a.size

    if n < 2:
        return {
            "comparison": f"{col_emotion} vs {col_neutral}",
            "n_pairs": n,
            "mean_emotion": np.nan,
            "mean_neutral": np.nan,
            "mean_diff": np.nan,
            "t": np.nan,
            "df": np.nan,
            "p": np.nan,
            "ci95_lo": np.nan,
            "ci95_hi": np.nan,
            "cohens_dz": np.nan,
        }

    diff = a - b
    mean_emotion = float(a.mean())
    mean_neutral = float(b.mean())
    mean_diff = float(diff.mean())
    sd_diff = float(diff.std(ddof=1)) if n >= 2 else np.nan

    t_stat, p_val = stats.ttest_rel(a, b, nan_policy="omit")
    df_ = n - 1
    se = sd_diff / np.sqrt(n) if not np.isnan(sd_diff) else np.nan
    tcrit = stats.t.ppf(0.975, df_) if df_ > 0 else np.nan
    ci_lo = mean_diff - tcrit * se if not np.isnan(se) and not np.isnan(tcrit) else np.nan
    ci_hi = mean_diff + tcrit * se if not np.isnan(se) and not np.isnan(tcrit) else np.nan
    dz = cohens_dz_from_diff(mean_diff, sd_diff)

    return {
        "comparison": f"{col_emotion} vs {col_neutral}",
        "n_pairs": int(n),
        "mean_emotion": mean_emotion,
        "mean_neutral": mean_neutral,
        "mean_diff": mean_diff,
        "t": float(t_stat),
        "df": int(df_),
        "p": float(p_val),
        "ci95_lo": float(ci_lo) if ci_lo == ci_lo else np.nan,
        "ci95_hi": float(ci_hi) if ci_hi == ci_hi else np.nan,
        "cohens_dz": float(dz) if dz == dz else np.nan,
    }
