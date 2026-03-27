from __future__ import annotations

import pandas as pd


# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def select_wsap_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Keep the same analysis columns used in the original WSAP script."""
    columns_to_keep = (
        df.columns[0:1].tolist() +
        df.columns[6:7].tolist() +
        df.columns[14:15].tolist() +
        df.columns[26:27].tolist() +
        df.columns[42:43].tolist() +
        df.columns[44:].tolist()
    )
    return df[columns_to_keep]
