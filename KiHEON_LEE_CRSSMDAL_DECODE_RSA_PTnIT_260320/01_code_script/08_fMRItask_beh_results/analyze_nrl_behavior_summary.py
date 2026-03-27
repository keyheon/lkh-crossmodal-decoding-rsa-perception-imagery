#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Behavioral descriptives, repeated-measures ANOVAs, and paired t-tests.

Output:
    - descriptives_all_variables.csv
    - descriptives_ratings_only.csv
    - anova_PT_perceived_intensity.csv
    - anova_IT_vividness.csv
    - ttests_perceived_vs_neutral.csv
    - ttests_vividness_vs_neutral.csv
    - behavioral_report.txt
"""
# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
from __future__ import annotations

import os
from pathlib import Path

import numpy as np
import pandas as pd
from statsmodels.stats.multitest import multipletests

from utility_functions.clean_text import clean_text
from utility_functions.find_subject_col import find_subject_col
from utility_functions.paired_t import paired_t
from utility_functions.run_rm_anova import run_rm_anova
from utility_functions.stars import stars
from utility_functions.summarize_means import summarize_means
from utility_functions.wide_to_long import wide_to_long


# -----------------------------------------------------------------------------
# User-configurable paths
# -----------------------------------------------------------------------------
INPATH = "~/behavioral/nrl_behavioral_descript.csv" # modify if needed
OUTDIR = Path(os.path.dirname(INPATH)) / "descriptive_summary_tables_desc"
OUTDIR.mkdir(parents=True, exist_ok=True)

PERCEIVED_INTENSITY = {
    "ang": "ang_perceived_intensity",
    "hap": "hap_perceived_intensity",
    "sad": "sad_perceived_intensity",
    "neut": "neut_perceived_intensity",
}
VIVIDNESS = {
    "ang": "ang_vividness",
    "hap": "hap_vividness",
    "sad": "sad_vividness",
    "neut": "neut_vividness",
}


def build_descriptives_all(df: pd.DataFrame) -> pd.DataFrame:
    subject_col = find_subject_col(df)
    columns_all = [c for c in df.columns if c != subject_col]

    rows = []
    for column in columns_all:
        x = pd.to_numeric(df[column], errors="coerce")
        n = int(x.notna().sum())
        mean = float(x.mean(skipna=True)) if n > 0 else np.nan
        sd = float(x.std(ddof=1, skipna=True)) if n > 1 else np.nan
        rows.append({"variable": column, "N": n, "mean": mean, "sd": sd})
    return pd.DataFrame(rows).sort_values("variable")


def build_ratings_descriptives(df: pd.DataFrame) -> pd.DataFrame:
    ratings_cols = [PERCEIVED_INTENSITY[k] for k in ["ang", "hap", "sad", "neut"] if PERCEIVED_INTENSITY[k] in df.columns]
    ratings_cols += [VIVIDNESS[k] for k in ["ang", "hap", "sad", "neut"] if VIVIDNESS[k] in df.columns]

    rows = []
    for column in ratings_cols:
        x = pd.to_numeric(df[column], errors="coerce")
        n = int(x.notna().sum())
        mean = float(x.mean(skipna=True)) if n > 0 else np.nan
        sd = float(x.std(ddof=1, skipna=True)) if n > 1 else np.nan
        rows.append({"variable": column, "N": n, "mean": mean, "sd": sd})
    return pd.DataFrame(rows)


def build_paired_tests(df: pd.DataFrame, mapping: dict[str, str]) -> pd.DataFrame:
    rows = []
    for emotion, column in mapping.items():
        if emotion == "neut":
            continue
        if column in df.columns and mapping["neut"] in df.columns:
            rows.append(paired_t(df, column, mapping["neut"]))

    out = pd.DataFrame(rows)
    if not out.empty:
        out["p_FDR"] = multipletests(out["p"].values, method="fdr_bh")[1]
        out["sig"] = [stars(p) for p in out["p"].values]
        out["sig_FDR"] = [stars(p) for p in out["p_FDR"].values]
    return out


def append_ttest_lines(report_lines: list[str], df_tests: pd.DataFrame, label: str) -> None:
    if df_tests.empty:
        report_lines.append(f"{label} paired t-tests: no results were generated.")
        return

    report_lines.append(f"{label} paired t-tests (emotion vs. neutral), BH-FDR within family:")
    for _, row in df_tests.iterrows():
        report_lines.append(
            f"  {row['comparison']}: t({int(row['df'])})={row['t']:.2f}, "
            f"p={row['p']:.4g}{stars(row['p'])}, "
            f"p_FDR={row['p_FDR']:.4g}{stars(row['p_FDR'])}, "
            f"mean_diff={row['mean_diff']:.2f}, dz={row['cohens_dz']:.2f}"
        )


def main() -> None:
    df = pd.read_csv(INPATH, sep=None, engine="python")
    df.columns = [clean_text(c) for c in df.columns]
    subject_col = find_subject_col(df)

    desc_all = build_descriptives_all(df)
    desc_ratings = build_ratings_descriptives(df)

    out_desc_all = OUTDIR / "descriptives_all_variables.csv"
    out_desc_ratings = OUTDIR / "descriptives_ratings_only.csv"
    desc_all.to_csv(out_desc_all, index=False, float_format="%.6g")
    desc_ratings.to_csv(out_desc_ratings, index=False, float_format="%.6g")

    report_lines: list[str] = []
    report_lines.append(f"[NRL] Subject column detected: {subject_col}")

    try:
        long_pt = wide_to_long(df, subject_col, PERCEIVED_INTENSITY, dv_name="Score", within_name="Emotion")
        aov_pt = run_rm_anova(long_pt, subject_col, within_name="Emotion", dv_name="Score")
        out_anova_pt = OUTDIR / "anova_PT_perceived_intensity.csv"
        aov_pt["table"].to_csv(out_anova_pt)
        summary = aov_pt["summary"]
        report_lines.append(summarize_means(df, PERCEIVED_INTENSITY, "PT perceived intensity"))
        if summary["backend"] == "pingouin":
            report_lines.append(
                f"PT ANOVA (Emotion): F({summary['df1']:.0f},{summary['df2']:.0f})={summary['F']:.2f}, "
                f"p={summary['p']:.4g} (GG p={summary['p_GG']:.4g}, HF p={summary['p_HF']:.4g}; "
                f"W={summary['W_sphericity']:.3f}, p_sphericity={summary['p_sphericity']:.4g}, "
                f"epsGG={summary['epsGG']:.3f}), partial eta-squared={summary['np2']:.3f}."
            )
        else:
            report_lines.append(
                f"PT ANOVA (Emotion): F({summary['df1']:.0f},{summary['df2']:.0f})={summary['F']:.2f}, "
                f"p={summary['p']:.4g}, partial eta-squared={summary['np2']:.3f}."
            )
    except Exception as exc:
        out_anova_pt = OUTDIR / "anova_PT_perceived_intensity.csv"
        report_lines.append(f"PT ANOVA failed: {exc}")

    try:
        long_it = wide_to_long(df, subject_col, VIVIDNESS, dv_name="Score", within_name="Emotion")
        aov_it = run_rm_anova(long_it, subject_col, within_name="Emotion", dv_name="Score")
        out_anova_it = OUTDIR / "anova_IT_vividness.csv"
        aov_it["table"].to_csv(out_anova_it)
        summary = aov_it["summary"]
        report_lines.append(summarize_means(df, VIVIDNESS, "IT vividness"))
        if summary["backend"] == "pingouin":
            report_lines.append(
                f"IT ANOVA (Emotion): F({summary['df1']:.0f},{summary['df2']:.0f})={summary['F']:.2f}, "
                f"p={summary['p']:.4g} (GG p={summary['p_GG']:.4g}, HF p={summary['p_HF']:.4g}; "
                f"W={summary['W_sphericity']:.3f}, p_sphericity={summary['p_sphericity']:.4g}, "
                f"epsGG={summary['epsGG']:.3f}), partial eta-squared={summary['np2']:.3f}."
            )
        else:
            report_lines.append(
                f"IT ANOVA (Emotion): F({summary['df1']:.0f},{summary['df2']:.0f})={summary['F']:.2f}, "
                f"p={summary['p']:.4g}, partial eta-squared={summary['np2']:.3f}."
            )
    except Exception as exc:
        out_anova_it = OUTDIR / "anova_IT_vividness.csv"
        report_lines.append(f"IT ANOVA failed: {exc}")

    pt_tests = build_paired_tests(df, PERCEIVED_INTENSITY)
    vv_tests = build_paired_tests(df, VIVIDNESS)

    out_t_pt = OUTDIR / "ttests_perceived_vs_neutral.csv"
    out_t_vv = OUTDIR / "ttests_vividness_vs_neutral.csv"
    pt_tests.to_csv(out_t_pt, index=False, float_format="%.6g")
    vv_tests.to_csv(out_t_vv, index=False, float_format="%.6g")

    append_ttest_lines(report_lines, pt_tests, "PT perceived intensity")
    append_ttest_lines(report_lines, vv_tests, "IT vividness")

    report_path = OUTDIR / "behavioral_report.txt"
    with open(report_path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(report_lines))

    print(f"[NRL] Saved: {out_desc_all}")
    print(f"[NRL] Saved: {out_desc_ratings}")
    print(f"[NRL] Saved: {out_anova_pt}")
    print(f"[NRL] Saved: {out_anova_it}")
    print(f"[NRL] Saved: {out_t_pt}")
    print(f"[NRL] Saved: {out_t_vv}")
    print(f"[NRL] Saved: {report_path}")


if __name__ == "__main__":
    main()
