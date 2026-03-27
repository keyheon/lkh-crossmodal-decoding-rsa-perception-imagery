#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# PTnIT_preprocessing_vox2.sh
#
# =========================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# =========================================
#
# Purpose:
#   Convert raw DICOM data to a minimal BIDS structure and run fMRIPrep for all
#
# Processing summary:
#   - DICOM to NIfTI conversion with dcm2niix
#   - Minimal BIDS tree creation (anat and func)
#   - Automatic insertion of TaskName metadata for BOLD JSON files
#   - BIDS validation before preprocessing
#   - fMRIPrep execution with output spaces:
#       * MNI152NLin2009cAsym:res-2
#       * T1w
#
# Authors of the study:
#   Ki Heon Lee, Heungsik Yoon, Sang Hee Kim
#
# Example usage:
#   cd /home/analysis01/NRL2024/fmriprep
#   tmux new -s preproc
#   conda activate lkh_neuro
#   ./nrl_bids_fmriprep_preproc_vox2_journal.sh 2>&1 | tee run_all_$(date +%Y%m%d_%H%M).log
# ------------------------------------------------------------------------------

set -euo pipefail

# ==============================
# Global settings
# ==============================
ROOT=$(pwd)
FS_LIC="$HOME/freesurfer/license.txt"
NCPUS=14
MEM=80000                      # Memory limit in MB
PREP_VOX=2                     # fMRIPrep output resolution in mm isotropic voxels

# ==============================
# Subject and visit loop
# ==============================
for SUB_DIR in P1?? P120; do
  [[ -d "$SUB_DIR" ]] || continue

  SUB=${SUB_DIR}
  echo
  echo "==================  ${SUB}  =================="

  for VIS in visit1 visit2 visit3; do
    RAW="${ROOT}/${SUB}/${VIS}_dicom"
    [[ -d "$RAW" ]] || { echo "→ Skip ${SUB} ${VIS} (no DICOM directory found)"; continue; }

    SES="ses-${VIS}"
    BIDS="${ROOT}/${SUB}/${VIS}_bids"
    TMP="${ROOT}/${SUB}/tmp_dcm2nii/${VIS}"
    WORKDIR="${ROOT}/${SUB}/work_${VIS}"

    echo "-----  ${SUB} | ${VIS}  -----"
    mkdir -p "$TMP" "$WORKDIR"

    # --------------------------------------------------------------------------
    # Step 1. Convert DICOM to NIfTI/JSON using dcm2niix
    # --------------------------------------------------------------------------
    echo "  · Converting T1w"
    T1DIR=$(find "$RAW" -maxdepth 1 -type d -name "32*T1*" | head -n1)
    dcm2niix -b y -z y -f T1w -o "$TMP" "$T1DIR"

    echo "  · Converting BOLD runs"
    for r in {1..6}; do
      printf -v RUN "%02d" "$r"
      RUNDIR=$(find "$RAW" -maxdepth 1 -type d -name "*TASK${r}_*" | head -n1)
      dcm2niix -b y -z y -f "task-face_run-${RUN}" -o "$TMP" "$RUNDIR"
    done

    # --------------------------------------------------------------------------
    # Step 2. Build BIDS directory structure
    # --------------------------------------------------------------------------
    echo "  · Creating BIDS tree"
    mkdir -p "${BIDS}/sub-${SUB}/${SES}/anat" "${BIDS}/sub-${SUB}/${SES}/func"

    mv "$TMP"/T1w.nii.gz  "${BIDS}/sub-${SUB}/${SES}/anat/sub-${SUB}_${SES}_T1w.nii.gz"
    mv "$TMP"/T1w.json    "${BIDS}/sub-${SUB}/${SES}/anat/sub-${SUB}_${SES}_T1w.json"

    for r in {1..6}; do
      printf -v RUN "%02d" "$r"
      mv "$TMP"/task-face_run-${RUN}.nii.gz \
         "${BIDS}/sub-${SUB}/${SES}/func/sub-${SUB}_${SES}_task-face_run-${RUN}_bold.nii.gz"
      mv "$TMP"/task-face_run-${RUN}.json \
         "${BIDS}/sub-${SUB}/${SES}/func/sub-${SUB}_${SES}_task-face_run-${RUN}_bold.json"
    done

    # --------------------------------------------------------------------------
    # Step 3. Add required BIDS metadata
    # --------------------------------------------------------------------------
    echo "  · Auto-filling metadata"
    for json in "${BIDS}/sub-${SUB}/${SES}/func/"*_bold.json; do
      jq 'if has("TaskName") then . else . + {TaskName:"face"} end' \
        "$json" > "${json}.tmp" && mv "${json}.tmp" "$json"
    done

    DESC="${BIDS}/dataset_description.json"
    if [[ ! -f "$DESC" ]]; then
      cat > "$DESC" <<EOF_JSON
{
  "Name": "PT/IT fMRI study",
  "BIDSVersion": "1.9.0",
  "DatasetType": "raw",
  "Authors": ["Ki Heon Lee", "Heungsik Yoon", "Sang Hee Kim"]
}
EOF_JSON
    fi

    # --------------------------------------------------------------------------
    # Step 4. Validate BIDS dataset
    # --------------------------------------------------------------------------
    echo "  · Validating BIDS"
    bids-validator "$BIDS" --ignoreNiftiHeaders \
      || { echo "    ✗ Validation failed — skipping ${SUB} ${VIS}"; continue; }

    # --------------------------------------------------------------------------
    # Step 5. Run fMRIPrep
    # --------------------------------------------------------------------------
    echo "  · Running fMRIPrep (${PREP_VOX} mm)"
    docker run --rm -ti \
      -v "${BIDS}":/data:ro \
      -v "${BIDS}/derivatives":/out \
      -v "${WORKDIR}":/work \
      -v "${FS_LIC}":/license.txt:ro \
      -e FS_LICENSE=/license.txt \
      nipreps/fmriprep:25.1.3 \
      /data /out participant \
      --participant-label "${SUB}" \
      --output-spaces MNI152NLin2009cAsym:res-${PREP_VOX} T1w \
      --n_cpus ${NCPUS} --mem_mb ${MEM}

    echo "  ✓ Finished ${SUB} ${VIS}"
    echo "    QC report: ${BIDS}/derivatives/fmriprep/sub-${SUB}.html"
  done
done

echo
echo "==================  ALL SUBJECTS DONE  =================="
