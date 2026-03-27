from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

from .pretty_text import pretty_text
from .pretty_roi_label import pretty_roi_label

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def plot_roi_behavior_scatter(
    x: np.ndarray,
    y: np.ndarray,
    x_grid: np.ndarray,
    y_hat_grid: np.ndarray,
    roi_short: str,
    dv: str,
    rho_value: float,
    q_value: float,
    color: str,
    out_png: str | Path,
) -> None:
    """Save a single ROI-by-behavior scatter plot with an OLS line."""
    fig, ax = plt.subplots(figsize=(4.5, 6.0))

    ax.scatter(
        x,
        y,
        s=180,
        c=color,
        edgecolors="black",
        linewidths=0.5,
        zorder=3,
    )
    ax.plot(x_grid, y_hat_grid, color=color, linewidth=8, zorder=2)

    roi_label = pretty_roi_label(roi_short)
    dv_label = pretty_text(dv)

    ax.set_title(f"{roi_label} | {dv_label}", fontsize=14, fontweight="bold", pad=12)
    ax.set_xlabel("RS (Spearman ρ, PT vs IT)", fontsize=13, fontweight="bold")
    ax.set_ylabel(dv_label, fontsize=13, fontweight="bold")
    ax.tick_params(axis="both", labelsize=13)
    ax.grid(False)

    annotation = f"ρ = {rho_value:.3f} | FDR-q = {q_value:.4f}"
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

    out_png = Path(out_png)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(out_png, dpi=250)
    plt.close(fig)
