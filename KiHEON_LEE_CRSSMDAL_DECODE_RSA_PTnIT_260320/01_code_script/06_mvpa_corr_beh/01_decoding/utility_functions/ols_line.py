from __future__ import annotations

import numpy as np
from scipy.stats import linregress

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def ols_line(x: np.ndarray, y: np.ndarray, n_grid: int = 200) -> tuple[np.ndarray, np.ndarray]:
    """
    Fit an ordinary least squares line and return plotting coordinates.
    """
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)

    mask = np.isfinite(x) & np.isfinite(y)
    x = x[mask]
    y = y[mask]

    lr = linregress(x, y)
    x_grid = np.linspace(np.min(x), np.max(x), n_grid)
    y_hat_grid = lr.intercept + lr.slope * x_grid
    return x_grid, y_hat_grid
