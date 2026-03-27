from __future__ import annotations

import numpy as np

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================

try:
    from statsmodels.stats.multitest import multipletests as sm_multipletests
except Exception:  # pragma: no cover
    sm_multipletests = None


def fdr_bh(pvals: np.ndarray) -> np.ndarray:
    """
    Benjamini-Hochberg FDR correction with NaN-safe handling.
    """
    p = np.asarray(pvals, dtype=float)
    q = np.full_like(p, np.nan, dtype=float)
    mask = np.isfinite(p)

    if not np.any(mask):
        return q

    if sm_multipletests is not None:
        _, q_vals, _, _ = sm_multipletests(p[mask], alpha=0.05, method="fdr_bh")
        q[mask] = q_vals
        return q

    pv = p[mask]
    m = pv.size
    order = np.argsort(pv)
    pv_sorted = pv[order]
    ranks = np.arange(1, m + 1)

    q_sorted = pv_sorted * m / ranks
    q_sorted = np.minimum.accumulate(q_sorted[::-1])[::-1]

    q_valid = np.empty_like(pv_sorted)
    q_valid[order] = q_sorted
    q[mask] = np.clip(q_valid, 0.0, 1.0)
    return q
