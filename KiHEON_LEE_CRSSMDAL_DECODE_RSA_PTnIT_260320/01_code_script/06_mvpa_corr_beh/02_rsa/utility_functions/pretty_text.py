from __future__ import annotations

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def pretty_text(value: object) -> str:
    """Convert underscore-delimited labels into display labels."""
    return str(value).replace("_", " ")
