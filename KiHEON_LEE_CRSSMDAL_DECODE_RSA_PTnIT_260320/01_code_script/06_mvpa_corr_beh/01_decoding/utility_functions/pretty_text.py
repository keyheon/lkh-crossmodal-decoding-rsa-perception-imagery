from __future__ import annotations

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def pretty_text(text: str) -> str:
    """
    Replace underscores with spaces for display labels.
    """
    return str(text).replace("_", " ")
