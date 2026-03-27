from __future__ import annotations

import numpy as np
from scipy.stats import spearmanr

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def permutation_p_spearman(
    x: np.ndarray,
    y: np.ndarray,
    n_perm: int,
    alternative: str,
    seed: int,
) -> tuple[float, float]:
    """
    Compute a Spearman correlation and a permutation p-value by shuffling y.

    Parameters
    ----------
    x, y : array-like
        Data vectors.
    n_perm : int
        Number of permutations.
    alternative : {"two-sided", "greater", "less"}
        Tail of the permutation test.
    seed : int
        Random seed for reproducibility.

    Returns
    -------
    rho_obs : float
        Observed Spearman correlation.
    p_perm : float
        Permutation p-value.
    """
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)
    mask = np.isfinite(x) & np.isfinite(y)
    x = x[mask]
    y = y[mask]

    if x.size < 5:
        return np.nan, np.nan

    rho_obs, _ = spearmanr(x, y)

    rng = np.random.default_rng(seed)
    null = np.empty(n_perm, dtype=float)
    for i in range(n_perm):
        y_perm = rng.permutation(y)
        null[i], _ = spearmanr(x, y_perm)

    if alternative == "two-sided":
        p = (np.sum(np.abs(null) >= np.abs(rho_obs)) + 1) / (n_perm + 1)
    elif alternative == "greater":
        p = (np.sum(null >= rho_obs) + 1) / (n_perm + 1)
    elif alternative == "less":
        p = (np.sum(null <= rho_obs) + 1) / (n_perm + 1)
    else:
        raise ValueError("alternative must be 'two-sided', 'greater', or 'less'")

    return float(rho_obs), float(p)
