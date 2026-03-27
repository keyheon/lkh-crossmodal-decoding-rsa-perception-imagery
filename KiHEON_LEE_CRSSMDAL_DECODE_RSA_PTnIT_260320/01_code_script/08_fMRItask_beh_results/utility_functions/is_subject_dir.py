from __future__ import annotations

import re
from pathlib import Path

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def is_subject_dir(path: Path) -> bool:
    return path.is_dir() and re.fullmatch(r"\d+", path.name) is not None
