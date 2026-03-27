from __future__ import annotations

import re

from utility_functions.pretty_text import pretty_text

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def pretty_roi_label(roi_short: str) -> str:
    """
    Convert an ROI filename stem to a human-readable label.

    Example
    -------
    rstr01_l_amygdala -> Left amygdala
    rstr02_r_ACC      -> Right ACC
    """
    s = str(roi_short)
    s = re.sub(r"^rstr\d+_", "", s)

    parts = s.split("_")
    if len(parts) >= 2 and parts[0].lower() in {"l", "r"}:
        hemisphere = "Left" if parts[0].lower() == "l" else "Right"
        roi_name = pretty_text(" ".join(parts[1:]))
        return f"{hemisphere} {roi_name}"

    return pretty_text(s)
