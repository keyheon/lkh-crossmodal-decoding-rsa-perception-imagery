from __future__ import annotations

import numpy as np
import pandas as pd

from utility_functions.partial_eta_squared_from_F import partial_eta_squared_from_F

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
try:
    import pingouin as pg
    USE_PINGOUIN = True
except Exception:
    USE_PINGOUIN = False

try:
    from statsmodels.stats.anova import AnovaRM
    HAVE_STATSMODELS = True
except Exception:
    HAVE_STATSMODELS = False


def run_rm_anova(
    long_df: pd.DataFrame,
    subject_col: str,
    within_name: str = "Emotion",
    dv_name: str = "Score",
) -> dict:
    results: dict = {}

    if USE_PINGOUIN:
        aov = pg.rm_anova(
            data=long_df,
            dv=dv_name,
            within=within_name,
            subject=subject_col,
            detailed=True,
            effsize="np2",
        )
        try:
            W, p_spher, epsGG = pg.sphericity(
                data=long_df,
                dv=dv_name,
                subject=subject_col,
                within=within_name,
            )
        except Exception:
            W, p_spher, epsGG = (np.nan, np.nan, np.nan)

        row = aov.iloc[0]
        F = float(row["F"])
        df1 = float(row["DF1"])
        df2 = float(row["DF2"])
        p_unc = float(row["p-unc"])
        p_gg = float(row["p-GG-corr"]) if "p-GG-corr" in row else np.nan
        p_hf = float(row["p-HF-corr"]) if "p-HF-corr" in row else np.nan
        np2 = float(row["np2"]) if "np2" in row else partial_eta_squared_from_F(F, df1, df2)

        results["table"] = aov
        results["summary"] = {
            "F": F,
            "df1": df1,
            "df2": df2,
            "p": p_unc,
            "p_GG": p_gg,
            "p_HF": p_hf,
            "np2": np2,
            "W_sphericity": W,
            "p_sphericity": p_spher,
            "epsGG": epsGG,
            "backend": "pingouin",
        }
        return results

    if not HAVE_STATSMODELS:
        raise RuntimeError("Neither pingouin nor statsmodels is available for repeated-measures ANOVA.")

    aov = AnovaRM(data=long_df, depvar=dv_name, subject=subject_col, within=[within_name]).fit()
    try:
        table = aov.anova_table.copy()
    except Exception:
        table = pd.read_html(aov.summary().tables[0].as_html(), header=0, index_col=0)[0]

    row = table.iloc[0]
    F = float(row.get("F Value", row.get("F", np.nan)))
    df1 = float(row.get("Num DF", row.get("df", np.nan)))
    df2 = float(row.get("Den DF", row.get("DenDF", np.nan)))
    p_unc = float(row.get("Pr > F", row.get("Pr(>F)", np.nan)))
    np2 = partial_eta_squared_from_F(F, df1, df2)

    results["table"] = table
    results["summary"] = {
        "F": F,
        "df1": df1,
        "df2": df2,
        "p": p_unc,
        "p_GG": np.nan,
        "p_HF": np.nan,
        "np2": np2,
        "W_sphericity": np.nan,
        "p_sphericity": np.nan,
        "epsGG": np.nan,
        "backend": "statsmodels",
    }
    return results
