#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NRL ratings: descriptive statistics for PT (perceived intensity) and IT (vividness).

Outputs:
    - ratings_subject_emotion_stats.csv
    - ratings_group_emotion_stats.csv
"""
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================

from __future__ import annotations

import re
from pathlib import Path

import numpy as np
import pandas as pd

from utility_functions.is_subject_dir import is_subject_dir
from utility_functions.read_ratings import read_ratings
from utility_functions.stats_from_array import stats_from_array


# -----------------------------------------------------------------------------
# User-configurable paths
# -----------------------------------------------------------------------------
ROOT = Path("~/behavioral/rating") # where rating data are located
PT_DIR = ROOT / "01PT"
IT_DIR = ROOT / "02IT"
OUTDIR = ROOT / "summary_tables"
OUTDIR.mkdir(parents=True, exist_ok=True)

EMOTIONS = ["angry", "happy", "sad", "neutral"]
EMOTION_LABELS = {
    "angry": "Angry",
    "happy": "Happy",
    "sad": "Sad",
    "neutral": "Neutral",
}


def collect_subject_ids(pt_dir: Path, it_dir: Path) -> list[str]:
    pt_subjects = {p.name for p in pt_dir.glob("*") if is_subject_dir(p)}
    it_subjects = {p.name for p in it_dir.glob("*") if is_subject_dir(p)}
    return sorted(pt_subjects | it_subjects)


def main() -> None:
    subject_rows: list[dict] = []

    pooled_pt = {emo: [] for emo in EMOTIONS}
    pooled_it = {emo: [] for emo in EMOTIONS}
    subject_mean_pt = {emo: [] for emo in EMOTIONS}
    subject_mean_it = {emo: [] for emo in EMOTIONS}

    subjects = collect_subject_ids(PT_DIR, IT_DIR)

    for subject in subjects:
        subject_pt_dir = PT_DIR / subject
        subject_it_dir = IT_DIR / subject

        for emotion in EMOTIONS:
            pt_values = np.array([], dtype=float)
            for visit in (1, 2):
                pt_file = subject_pt_dir / f"visit{visit}_output_onset_face_{emotion}_intensity.csv"
                if pt_file.exists():
                    pt_values = np.concatenate([pt_values, read_ratings(pt_file)])
            pt_n, pt_mean, pt_sd = stats_from_array(pt_values)

            it_values = np.array([], dtype=float)
            it_file = subject_it_dir / f"visit3_output_onset_face_{emotion}_intensity.csv"
            if it_file.exists():
                it_values = read_ratings(it_file)
            it_n, it_mean, it_sd = stats_from_array(it_values)

            subject_rows.append(
                {
                    "Subject_ID": subject,
                    "Emotion": EMOTION_LABELS[emotion],
                    "PT_n": pt_n,
                    "PT_mean": pt_mean,
                    "PT_sd": pt_sd,
                    "IT_n": it_n,
                    "IT_mean": it_mean,
                    "IT_sd": it_sd,
                }
            )

            if pt_n > 0:
                pooled_pt[emotion].extend(pt_values.tolist())
                subject_mean_pt[emotion].append(pt_mean)
            if it_n > 0:
                pooled_it[emotion].extend(it_values.tolist())
                subject_mean_it[emotion].append(it_mean)

    df_subject = pd.DataFrame(subject_rows)
    emotion_order = [EMOTION_LABELS[e] for e in EMOTIONS]
    df_subject["Emotion"] = pd.Categorical(df_subject["Emotion"], categories=emotion_order, ordered=True)
    df_subject.sort_values(["Subject_ID", "Emotion"], inplace=True)
    out_subject = OUTDIR / "ratings_subject_emotion_stats.csv"
    df_subject.to_csv(out_subject, index=False, float_format="%.6g")

    group_rows: list[dict] = []
    for emotion in EMOTIONS:
        pt_vals = np.asarray(pooled_pt[emotion], dtype=float)
        it_vals = np.asarray(pooled_it[emotion], dtype=float)
        pt_total_n, pt_pooled_mean, pt_pooled_sd = stats_from_array(pt_vals)
        it_total_n, it_pooled_mean, it_pooled_sd = stats_from_array(it_vals)

        pt_submeans = np.asarray(subject_mean_pt[emotion], dtype=float)
        it_submeans = np.asarray(subject_mean_it[emotion], dtype=float)
        pt_n_subj, pt_mean_of_means, pt_sd_of_means = stats_from_array(pt_submeans)
        it_n_subj, it_mean_of_means, it_sd_of_means = stats_from_array(it_submeans)

        group_rows.append(
            {
                "Emotion": EMOTION_LABELS[emotion],
                "PT_trials_total": pt_total_n,
                "PT_subjects_with_data": int(pt_n_subj),
                "PT_pooled_mean": pt_pooled_mean,
                "PT_pooled_sd": pt_pooled_sd,
                "PT_subject_mean_mean": pt_mean_of_means,
                "PT_subject_mean_sd": pt_sd_of_means,
                "IT_trials_total": it_total_n,
                "IT_subjects_with_data": int(it_n_subj),
                "IT_pooled_mean": it_pooled_mean,
                "IT_pooled_sd": it_pooled_sd,
                "IT_subject_mean_mean": it_mean_of_means,
                "IT_subject_mean_sd": it_sd_of_means,
            }
        )

    df_group = pd.DataFrame(group_rows)
    df_group["Emotion"] = pd.Categorical(df_group["Emotion"], categories=emotion_order, ordered=True)
    df_group.sort_values("Emotion", inplace=True)
    out_group = OUTDIR / "ratings_group_emotion_stats.csv"
    df_group.to_csv(out_group, index=False, float_format="%.6g")

    print(f"[NRL] Saved: {out_subject}")
    print(f"[NRL] Saved: {out_group}")


if __name__ == "__main__":
    main()
