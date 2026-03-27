from __future__ import annotations

import re

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def sanitize_filename(value: object) -> str:
    """Convert a label into a file-system-safe string."""
    s = re.sub(r"[^\w\-\.]+", "_", str(value))
    return s.strip("_")
