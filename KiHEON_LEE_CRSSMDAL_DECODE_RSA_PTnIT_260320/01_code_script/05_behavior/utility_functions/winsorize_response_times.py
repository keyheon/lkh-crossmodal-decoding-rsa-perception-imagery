from __future__ import annotations

import pandas as pd


# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def winsorize_response_times(data: pd.DataFrame) -> pd.DataFrame:
    """Remove trials outside the response-time range 200-4000 ms."""
    lower_bound = 200
    upper_bound = 4000
    filtered = data[
        (data["response_time"] >= lower_bound) &
        (data["response_time"] <= upper_bound)
    ].reset_index(drop=True)
    return filtered
