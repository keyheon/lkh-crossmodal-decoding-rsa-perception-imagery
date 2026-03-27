from __future__ import annotations

import numpy as np

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def stats_from_array(values: np.ndarray) -> tuple[int, float, float]:
    """Return N, mean, and sample SD (ddof=1) for a numeric array."""
    n = int(values.size)
    if n == 0:
        return 0, np.nan, np.nan
    mean = float(np.nanmean(values))
    sd = float(np.nanstd(values, ddof=1)) if n >= 2 else np.nan
    return n, mean, sd
