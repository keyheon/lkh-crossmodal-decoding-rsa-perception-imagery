from __future__ import annotations

import re

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def sanitize_filename(text: str) -> str:
    """
    Convert arbitrary text to a filesystem-safe filename fragment.
    """
    return re.sub(r"[^\w\-\.]+", "_", str(text)).strip("_")
