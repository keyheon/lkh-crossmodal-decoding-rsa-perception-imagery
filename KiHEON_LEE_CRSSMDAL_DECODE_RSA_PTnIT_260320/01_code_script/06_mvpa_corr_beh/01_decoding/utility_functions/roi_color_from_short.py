from __future__ import annotations

import re

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def roi_color_from_short(roi_short: str) -> str:
    """
    Return a fixed ROI-specific color.

    Insula   -> forest green
    vmPFC    -> dark yellow
    ACC      -> blue
    Amygdala -> dark red
    """
    s = str(roi_short).lower()
    s = re.sub(r"^rstr\d+_", "", s)

    if "insula" in s:
        return "#228B22"
    if "vmpfc" in s:
        return "#D4B000"
    if "acc" in s:
        return "tab:blue"
    if "amygdala" in s:
        return "#8B0000"

    return "tab:gray"
