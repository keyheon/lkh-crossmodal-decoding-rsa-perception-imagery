from __future__ import annotations

from pathlib import Path
import sys

import numpy as np
import pandas as pd

import matplotlib.pyplot as plt

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from utility_functions.read_rs_csv import read_rs_csv
from utility_functions.permutation_p_spearman import permutation_p_spearman
from utility_functions.sanitize_filename import sanitize_filename
from utility_functions.pretty_text import pretty_text
from utility_functions.pretty_roi_label import pretty_roi_label
from utility_functions.roi_color_from_short import roi_color_from_short
from utility_functions.fit_ols_line import fit_ols_line
from utility_functions.fdr_bh import fdr_bh
from utility_functions.plot_roi_behavior_scatter import plot_roi_behavior_scatter

# ====================== NRL: RSA × behavior correlation analysis ======================
# This script evaluates the association between ROI-wise RSA values
# (PT vs IT, Spearman-based RSA summary) and behavioral measures using
# Spearman correlation with permutation testing.
#
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
#
# Analysis settings:
#   - dependent variables: ERQ_reappraisal, ERQ_suppression,
#                          Benign_Endorsement_Rate, Threat_Endorsement_Rate
#   - ROIs: (left/right) amygdala, insula, ACC, vmPFC
#   - inference: two-sided permutation test for Spearman rho
#   - multiple-comparison correction: Benjamini-Hochberg FDR within each ROI
#   - visualization: per-ROI scatter plots with OLS regression lines
#
# Outputs:
#   - RSA_Behavior_perm_results_ALL.csv
#   - plots_by_roi/<ROI_short>/<DV>__<ROI_short>.png

# ---------------------------- Global plot style ---------------------------------------
plt.rcParams["font.family"] = "sans-serif"
plt.rcParams["font.sans-serif"] = ["Arial", "DejaVu Sans", "Liberation Sans"]
plt.rcParams["axes.titleweight"] = "bold"
plt.rcParams["axes.labelweight"] = "bold"
plt.rcParams["xtick.labelsize"] = 13
plt.rcParams["ytick.labelsize"] = 13

# ---------------------------- Paths (edit if needed) ----------------------------------
BEHAVIOR_CSV = Path(
    "~/260320_behavioral_results.csv" # modify if needed
)
RS_CSV = Path(
    "~/RS/subject_RS_roi.csv" # modify if needed
)
OUT_BASE = Path(
    "~/runwise_RSA_behav_results/" # modify if needed
)

# ---------------------------- Analysis options -----------------------------------------
N_PERM = 10000
ALT = "two-sided"
RANDOM_SEED = 1
DV_COLS = [
    "ERQ_reappraisal",
    "ERQ_suppression",
    "Benign_Endorsement_Rate",
    "Threat_Endorsement_Rate",
]


def main() -> None:
    out_plots = OUT_BASE / "plots_by_roi"
    out_plots.mkdir(parents=True, exist_ok=True)

    beh = pd.read_csv(BEHAVIOR_CSV)
    rs = read_rs_csv(RS_CSV)

    missing_dv = [c for c in DV_COLS if c not in beh.columns]
    if missing_dv:
        raise KeyError(
            "The behavioral file is missing required dependent variable columns: "
            + ", ".join(missing_dv)
        )

    roi_list = rs["ROI"].unique().tolist()
    all_rows = []

    # ---------------------------- Pass 1: statistics ------------------------------------
    for roi in roi_list:
        roi_short = rs.loc[rs["ROI"] == roi, "ROI_short"].iloc[0]
        rs_roi = rs.loc[rs["ROI"] == roi, ["Subject_ID", "RS_spearman"]]
        dat = beh.merge(rs_roi, on="Subject_ID", how="inner").copy()
        dat = dat.replace([np.inf, -np.inf], np.nan).dropna(subset=["RS_spearman"])

        for dv in DV_COLS:
            y = dat[dv].to_numpy(dtype=float)
            x = dat["RS_spearman"].to_numpy(dtype=float)
            mask = np.isfinite(x) & np.isfinite(y)
            x = x[mask]
            y = y[mask]
            n = x.size

            if n < 5:
                all_rows.append(
                    {
                        "ROI": roi,
                        "ROI_short": roi_short,
                        "DV": dv,
                        "n": n,
                        "rho_spearman": np.nan,
                        "p_perm": np.nan,
                    }
                )
                continue

            rho_obs, p_perm, _ = permutation_p_spearman(
                x=x,
                y=y,
                n_perm=N_PERM,
                alternative=ALT,
                random_seed=RANDOM_SEED,
            )

            all_rows.append(
                {
                    "ROI": roi,
                    "ROI_short": roi_short,
                    "DV": dv,
                    "n": n,
                    "rho_spearman": float(rho_obs),
                    "p_perm": float(p_perm),
                }
            )

    res_all = pd.DataFrame(all_rows)
    res_all["q_perm_withinROI"] = (
        res_all.groupby("ROI_short")["p_perm"]
        .transform(lambda s: fdr_bh(s.to_numpy(dtype=float)))
    )

    res_all.sort_values(["ROI_short", "p_perm", "DV"], inplace=True)
    master_csv = OUT_BASE / "RSA_Behavior_perm_results_ALL.csv"
    res_all.to_csv(master_csv, index=False)

    print("Computed permutation-based Spearman correlations and within-ROI FDR correction.")

    # ---------------------------- Pass 2: plotting --------------------------------------
    for roi in roi_list:
        roi_short = rs.loc[rs["ROI"] == roi, "ROI_short"].iloc[0]
        roi_dir = out_plots / sanitize_filename(roi_short)
        roi_dir.mkdir(parents=True, exist_ok=True)

        rs_roi = rs.loc[rs["ROI"] == roi, ["Subject_ID", "RS_spearman"]]
        dat = beh.merge(rs_roi, on="Subject_ID", how="inner").copy()
        dat = dat.replace([np.inf, -np.inf], np.nan).dropna(subset=["RS_spearman"])

        for dv in DV_COLS:
            row = res_all[(res_all["ROI"] == roi) & (res_all["DV"] == dv)]
            if row.empty:
                continue

            y = dat[dv].to_numpy(dtype=float)
            x = dat["RS_spearman"].to_numpy(dtype=float)
            mask = np.isfinite(x) & np.isfinite(y)
            x = x[mask]
            y = y[mask]
            if x.size < 5:
                continue

            rho_v = float(row["rho_spearman"].iloc[0])
            q_val = float(row["q_perm_withinROI"].iloc[0])

            x_grid, y_hat_grid = fit_ols_line(x, y, n_grid=200)
            color = roi_color_from_short(roi_short)

            out_png = roi_dir / f"{sanitize_filename(dv)}__{sanitize_filename(roi_short)}.png"
            plot_roi_behavior_scatter(
                x=x,
                y=y,
                x_grid=x_grid,
                y_hat_grid=y_hat_grid,
                roi_short=roi_short,
                dv=dv,
                rho_value=rho_v,
                q_value=q_val,
                color=color,
                out_png=out_png,
            )

    print("Done.")
    print(f"- Dependent variables analyzed (n={len(DV_COLS)}): {DV_COLS}")
    print(f"- ROIs analyzed (n={len(roi_list)}): {[Path(r).stem for r in roi_list]}")
    print(f"- Total tests (m = ROI × DV): {len(roi_list) * len(DV_COLS)}")
    print(f"- Plot directory: {out_plots}")
    print(f"- Master table: {master_csv}")


if __name__ == "__main__":
    main()
