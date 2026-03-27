from __future__ import annotations

import pandas as pd

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def find_subject_col(df: pd.DataFrame) -> str:
    for candidate in ["Subject_ID", "subject_id", "subj", "subject"]:
        if candidate in df.columns:
            return candidate
    return df.columns[0]
