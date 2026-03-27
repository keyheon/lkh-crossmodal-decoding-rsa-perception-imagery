from __future__ import annotations

import numpy as np

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def cohens_dz_from_diff(mean_diff: float, sd_diff: float) -> float:
    if sd_diff is None or np.isnan(sd_diff) or sd_diff == 0:
        return np.nan
    return mean_diff / sd_diff
