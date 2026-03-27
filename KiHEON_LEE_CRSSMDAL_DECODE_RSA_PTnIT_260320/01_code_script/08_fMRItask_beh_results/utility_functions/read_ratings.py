from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def read_ratings(path: Path) -> np.ndarray:
    """Read a one-column rating file and return numeric values as a NumPy array."""
    if not path.exists():
        return np.array([], dtype=float)

    series = pd.read_csv(
        path,
        header=None,
        names=["value"],
        dtype=str,
        comment="#",
        engine="python",
    )["value"]
    values = pd.to_numeric(series.str.strip(), errors="coerce").dropna().to_numpy(dtype=float)
    return values
