from __future__ import annotations

import re

## Utility function
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def normalize_subject_from_folder(folder_name: str) -> str:
    """
    Convert a folder name such as 'p101' to the standardized subject label 'P101'.
    """
    match = re.search(r"(\d+)", folder_name)
    if match:
        return f"P{int(match.group(1)):03d}"
    return folder_name
