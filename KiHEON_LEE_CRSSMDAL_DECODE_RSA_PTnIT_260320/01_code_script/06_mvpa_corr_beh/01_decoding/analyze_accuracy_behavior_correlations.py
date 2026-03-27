from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from scipy.stats import linregress

from utility_functions.fdr_bh import fdr_bh
from utility_functions.ols_line import ols_line
from utility_functions.permutation_p_spearman import permutation_p_spearman
from utility_functions.pretty_roi_label import pretty_roi_label
from utility_functions.pretty_text import pretty_text
from utility_functions.read_accuracy_overall import read_accuracy_overall
from utility_functions.read_behavior import read_behavior
from utility_functions.roi_color_from_short import roi_color_from_short
from utility_functions.sanitize_filename import sanitize_filename

# ===================================================================
# Decoding accuracy × behavior correlation analysis
# -------------------------------------------------------------------
# This script tests the association between ROI-wise overall decoding
# accuracy and behavioral measures using Spearman correlation with a
# two-sided permutation test. False discovery rate correction is
# applied within each ROI across the four behavioral variables.
#
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
#
# Output:
#   ACC_Behavior_perm_results_ALL.csv
#   plots_by_roi/<ROI_short>/*.png
# ===================================================================

# Plot style
plt.rcParams["font.family"] = "sans-serif"
plt.rcParams["font.sans-serif"] = ["Arial", "DejaVu Sans", "Liberation Sans"]
plt.rcParams["axes.titleweight"] = "bold"
plt.rcParams["axes.labelweight"] = "bold"
plt.rcParams["xtick.labelsize"] = 13
plt.rcParams["ytick.labelsize"] = 13

# Paths
BEHAVIOR_CSV = (
    "~/260320_behavioral_results.csv" # modify if needed
)
ACCURACY_CSV = (
    "~/decoding/pairwise_libsvm/SubjectOverallAccuracy_long.csv" # modify if needed
)
OUT_BASE = (
    "~/decoding_results/pairwise_libsvm/" # modify if needed
)

# Analysis settings
DV_COLS = [
    "ERQ_reappraisal",
    "ERQ_suppression",
    "Benign_Endorsement_Rate",
    "Threat_Endorsement_Rate",
]
N_PERM = 10000
ALTERNATIVE = "two-sided"
RANDOM_SEED = 1


def main() -> None:
    out_base = Path(OUT_BASE)
    out_base.mkdir(parents=True, exist_ok=True)
    out_plots = out_base / "plots_by_roi"
    out_plots.mkdir(parents=True, exist_ok=True)

    behavior = read_behavior(BEHAVIOR_CSV)
    accuracy = read_accuracy_overall(ACCURACY_CSV)

    dv_cols = [col for col in DV_COLS if col in behavior.columns]
    missing_dv = [col for col in DV_COLS if col not in behavior.columns]
    if missing_dv:
        print(f"[WARN] Missing behavioral columns and skipped: {missing_dv}")
    if not dv_cols:
        raise RuntimeError("No requested behavioral variables were found in the behavior file.")

    roi_list = sorted(accuracy["ROI"].unique().tolist())
    all_rows = []

    # Pass 1: compute statistics
    for roi in roi_list:
        roi_short = accuracy.loc[accuracy["ROI"] == roi, "ROI_short"].iloc[0]
        acc_roi = accuracy.loc[accuracy["ROI"] == roi, ["Subject_ID", "Accuracy_minus_Chance(%)"]]
        dat = behavior.merge(acc_roi, on="Subject_ID", how="inner").copy()
        dat = dat.replace([np.inf, -np.inf], np.nan).dropna(subset=["Accuracy_minus_Chance(%)"])

        for dv in dv_cols:
            x = dat["Accuracy_minus_Chance(%)"].to_numpy(dtype=float)
            y = dat[dv].to_numpy(dtype=float)
            mask = np.isfinite(x) & np.isfinite(y)
            x = x[mask]
            y = y[mask]
            n = int(x.size)

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

            rho_s, p_perm = permutation_p_spearman(
                x=x,
                y=y,
                n_perm=N_PERM,
                alternative=ALTERNATIVE,
                seed=RANDOM_SEED,
            )

            all_rows.append(
                {
                    "ROI": roi,
                    "ROI_short": roi_short,
                    "DV": dv,
                    "n": n,
                    "rho_spearman": float(rho_s),
                    "p_perm": float(p_perm),
                }
            )

    res_all = pd.DataFrame(all_rows)
    res_all["q_perm_withinROI"] = (
        res_all.groupby("ROI_short")["p_perm"]
        .transform(lambda s: fdr_bh(s.to_numpy(dtype=float)))
    )
    res_all.sort_values(["ROI_short", "p_perm", "DV"], inplace=True)

    master_csv = out_base / "ACC_Behavior_perm_results_ALL.csv"
    res_all.to_csv(master_csv, index=False)

    print("Computed statistics and within-ROI FDR. Now generating plots...")

    # Pass 2: plotting
    for roi in roi_list:
        roi_short = accuracy.loc[accuracy["ROI"] == roi, "ROI_short"].iloc[0]
        roi_dir = out_plots / sanitize_filename(roi_short)
        roi_dir.mkdir(parents=True, exist_ok=True)

        acc_roi = accuracy.loc[accuracy["ROI"] == roi, ["Subject_ID", "Accuracy_minus_Chance(%)"]]
        dat = behavior.merge(acc_roi, on="Subject_ID", how="inner").copy()
        dat = dat.replace([np.inf, -np.inf], np.nan).dropna(subset=["Accuracy_minus_Chance(%)"])

        for dv in dv_cols:
            row = res_all[(res_all["ROI"] == roi) & (res_all["DV"] == dv)]
            if row.empty:
                continue

            q_val = float(row["q_perm_withinROI"].iloc[0])
            rho_v = float(row["rho_spearman"].iloc[0]) if "rho_spearman" in row.columns else np.nan

            x = dat["Accuracy_minus_Chance(%)"].to_numpy(dtype=float)
            y = dat[dv].to_numpy(dtype=float)
            mask = np.isfinite(x) & np.isfinite(y)
            x = x[mask]
            y = y[mask]
            if x.size < 5:
                continue

            color = roi_color_from_short(roi_short)
            x_grid, y_hat_grid = ols_line(x, y, n_grid=200)

            fig, ax = plt.subplots(figsize=(4.5, 6.0))
            sns.scatterplot(
                x=x,
                y=y,
                s=180,
                color=color,
                edgecolor="black",
                linewidth=0.5,
                ax=ax,
                zorder=3,
            )
            ax.plot(x_grid, y_hat_grid, color=color, linewidth=8, zorder=2)

            roi_label = pretty_roi_label(roi_short)
            dv_label = pretty_text(dv)

            ax.set_title(f"{roi_label} | {dv_label}", fontsize=14, fontweight="bold", pad=12)
            ax.set_xlabel("Overall accuracy - chance (%)", fontsize=13, fontweight="bold")
            ax.set_ylabel(dv_label, fontsize=13, fontweight="bold")
            ax.tick_params(axis="both", labelsize=13)
            ax.grid(False)

            annotation = f"rho = {rho_v:.3f} | FDR-q = {q_val:.4f}"
            ax.annotate(
                annotation,
                xy=(0.02, 0.98),
                xycoords="axes fraction",
                ha="left",
                va="top",
                fontsize=9,
                bbox=dict(boxstyle="round,pad=0.25", fc="white", ec=color, lw=1.5),
                color=color,
            )

            out_png = roi_dir / f"{sanitize_filename(dv)}__{sanitize_filename(roi_short)}.png"
            plt.tight_layout()
            plt.savefig(out_png, dpi=250)
            plt.close(fig)

    print("Done.")
    print(f"Behavioral variables analyzed (n={len(dv_cols)}): {dv_cols}")
    print(f"ROIs analyzed (n={len(roi_list)}): {[Path(r).stem for r in roi_list]}")
    print(f"Total tests: {len(roi_list) * len(dv_cols)}")
    print(f"Plot directory: {out_plots}")
    print(f"Master table : {master_csv}")


if __name__ == "__main__":
    main()
