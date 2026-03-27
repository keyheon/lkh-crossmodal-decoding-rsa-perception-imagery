from __future__ import annotations

import math

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def stars(p: float) -> str:
    if p is None or (isinstance(p, float) and (math.isnan(p) or math.isinf(p))):
        return ""
    if p < 0.001:
        return "***"
    if p < 0.01:
        return "**"
    if p < 0.05:
        return "*"
    return ""
