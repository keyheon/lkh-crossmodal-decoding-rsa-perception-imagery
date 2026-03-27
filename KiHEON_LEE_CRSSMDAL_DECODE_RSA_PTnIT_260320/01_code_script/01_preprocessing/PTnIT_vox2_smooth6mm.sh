#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# PTnIT_vox2_smooth6mm.sh
#
# =========================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# =========================================
#
# Purpose:
#   Apply 6 mm FWHM Gaussian smoothing to fMRIPrep-preprocessed 2 mm isotropic
#   BOLD images for all available PT and IT runs.
#
# Scope:
#   - Input: per-run fMRIPrep preprocessed 4D BOLD files in MNI space
#   - Output: smoothed 4D BOLD files written to a run-level smooth6mm/ directory
#   - Existing outputs are preserved and skipped
#   - If FSL writes .nii.gz output, the file is decompressed to .nii
#
# Usage:
#   ./PTnIT_vox2_smooth6mm.sh [PROJECT_ROOT]
#
# -----------------------------------------------------------------------------

set -u
set -o pipefail
shopt -s nullglob

ROOT=${1:-$(pwd)}
FWHM=6

# -----------------------------------------------------------------------------
# Dependency checks
# -----------------------------------------------------------------------------
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: '$1' not found in PATH"
    exit 1
  }
}

need fslmaths
need gunzip
need python3

# Force FSL to generate compressed NIfTI output; files are decompressed below.
export FSLOUTPUTTYPE=NIFTI_GZ

# Precompute Gaussian sigma in millimeters for fslmaths -s.
SIGMA=$(python3 - <<'PYEOF'
import math
print(round(6/2.3548, 4))
PYEOF
)

echo "ROOT=$ROOT"
echo "Smoothing: FWHM=${FWHM}mm (sigma=${SIGMA} mm)"
echo

# -----------------------------------------------------------------------------
# Locate the preprocessed BOLD input for a given run directory.
# Supports both .nii.gz and .nii inputs.
# -----------------------------------------------------------------------------
find_input() {
  local run_dir="$1"
  local -n _out="$2"
  local files=()

  # Prefer filenames that explicitly include the res-2 tag.
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(
    find "$run_dir" -maxdepth 1 -type f \(
      -name "sub-P*_ses-visit*_task-face_run-*_space-MNI152NLin2009cAsym*_res-2_*_desc-preproc_bold.nii.gz" -o \
      -name "sub-P*_ses-visit*_task-face_run-*_space-MNI152NLin2009cAsym*_res-2_*_desc-preproc_bold.nii"
    \) -print0
  )

  # Fallback for filenames without an explicit res-2 tag.
  if [[ ${#files[@]} -eq 0 ]]; then
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(
      find "$run_dir" -maxdepth 1 -type f \(
        -name "sub-P*_ses-visit*_task-face_run-*_space-MNI152NLin2009cAsym*_desc-preproc_bold.nii.gz" -o \
        -name "sub-P*_ses-visit*_task-face_run-*_space-MNI152NLin2009cAsym*_desc-preproc_bold.nii"
      \) -print0
    )
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    _out=""
    return 1
  fi

  IFS=$'\n' files=($(printf '%s\n' "${files[@]}" | sort))
  _out="${files[0]}"
  return 0
}

# -----------------------------------------------------------------------------
# Smooth a single 4D run and write the result to smooth6mm/.
# -----------------------------------------------------------------------------
smooth_once() {
  local in_file="$1"
  local out_dir="$2"
  local fwhm="$3"
  local sigma="$4"

  mkdir -p "$out_dir"

  local base
  local stem
  local out_gz
  local out_nii

  base="$(basename "$in_file")"
  stem="${base%.nii.gz}"
  stem="${stem%.nii}"

  out_gz="${out_dir}/${stem/_desc-preproc_bold/_desc-preproc_smooth${fwhm}mm_bold}.nii.gz"
  out_nii="${out_gz%.gz}"

  # Skip smoothing if either decompressed or compressed output already exists.
  if [[ -f "$out_nii" || -f "$out_gz" ]]; then
    echo "    OK: smooth${fwhm}mm exists: $(basename "${out_nii:-$out_gz}")"
    if [[ -f "$out_gz" && ! -f "$out_nii" ]]; then
      echo "      -> decompress: $(basename "$out_gz")"
      gunzip -f "$out_gz"
    fi
    return 0
  fi

  echo "    -> 4D smoothing (FWHM=${fwhm}mm; sigma=${sigma} mm)"
  if fslmaths "$in_file" -s "$sigma" "$out_gz"; then
    if [[ -f "$out_gz" ]]; then
      echo "      -> decompress: $(basename "$out_gz")"
      gunzip -f "$out_gz"
    fi
  else
    echo "    ERROR: fslmaths failed (smooth ${fwhm}mm)"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Run 6 mm smoothing across all available subjects and runs.
# -----------------------------------------------------------------------------
echo "==================  6 mm smoothing  =================="
for SUB in "$ROOT"/P1?? "$ROOT"/P120; do
  [[ -d "$SUB" ]] || continue
  echo
  echo "---- $(basename "$SUB") ----"

  for RUN_DIR in "$SUB"/01_FEPT_RUN?? "$SUB"/02_IT_RUN??; do
    [[ -d "$RUN_DIR" ]] || continue

    in_file=""
    if ! find_input "$RUN_DIR" in_file; then
      echo "  - $(basename "$RUN_DIR"): no 2 mm preprocessed BOLD found -> skip"
      continue
    fi

    echo "  + $(basename "$RUN_DIR") | input: $(basename "$in_file")"
    smooth_once "$in_file" "$RUN_DIR/smooth6mm" "$FWHM" "$SIGMA"
  done
done

echo

echo "==================  DONE  =================="
