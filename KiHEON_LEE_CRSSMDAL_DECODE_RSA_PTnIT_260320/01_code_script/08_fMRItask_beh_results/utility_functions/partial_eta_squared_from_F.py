from __future__ import annotations

import pandas as pd

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def partial_eta_squared_from_F(F: float, df1: float, df2: float) -> float:
    if any(pd.isna(x) for x in [F, df1, df2]) or df2 <= 0:
        return float('nan')
    return (F * df1) / (F * df1 + df2)
