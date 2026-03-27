from __future__ import annotations

import os
import pandas as pd

from utility_functions.calculate_bias_scores import calculate_bias_scores
from utility_functions.select_wsap_columns import select_wsap_columns
from utility_functions.winsorize_response_times import winsorize_response_times

# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
# This script processes WSAP behavioral data for subjects 101-120.
# The analysis pipeline performs the following steps:
#   1) load the raw CSV file for each subject;
#   2) remove the first four rows;
#   3) retain the analysis columns used in the original workflow;
#   4) remove trials with response times < 200 ms or > 4000 ms;
#   5) save a revised CSV file for each subject;
#   6) compute WSAP bias scores and save a subject-level Excel file;
#   7) merge all subject-level bias scores into a single Excel file.

# ------------------------------------------------------------------
# Base paths
# ------------------------------------------------------------------
BASE_DIR = "~/behavior_results" # modify as needed
RAW_DIR_FMT = os.path.join(BASE_DIR, "{subj:03d}", "WSAP-nrl-{subj:03d}.csv")
REVISED_DIR_FMT = os.path.join(BASE_DIR, "{subj:03d}", "rrevised-WSAP-nrl-{subj:03d}.csv")

RESULT_DIR = os.path.join(BASE_DIR, "WSAP_results")
os.makedirs(RESULT_DIR, exist_ok=True)


# ------------------------------------------------------------------
# Main analysis loop
# ------------------------------------------------------------------
def main() -> None:
    merged_results = []

    for subj in range(101, 121):
        try:
            # ------------------------------------------------------
            # 1) Load the raw subject-level CSV file
            # ------------------------------------------------------
            file_path = RAW_DIR_FMT.format(subj=subj)
            df = pd.read_csv(file_path)

            # ------------------------------------------------------
            # 2) Remove the first four rows
            # ------------------------------------------------------
            df = df.drop(index=range(0, 4))

            # ------------------------------------------------------
            # 3) Keep the analysis columns used in the original script
            # ------------------------------------------------------
            df = select_wsap_columns(df)

            # ------------------------------------------------------
            # 4) Remove trials outside the response-time range
            # ------------------------------------------------------
            df = winsorize_response_times(df)

            # ------------------------------------------------------
            # 5) Save the revised CSV file
            # ------------------------------------------------------
            revised_path = REVISED_DIR_FMT.format(subj=subj)
            df.to_csv(revised_path, index=False)

            # ------------------------------------------------------
            # 6) Compute WSAP bias scores and save the subject-level
            #    Excel file
            # ------------------------------------------------------
            bias_scores = calculate_bias_scores(df)
            bias_scores["Subject"] = subj

            indiv_out = os.path.join(RESULT_DIR, f"WSAP-score-nrl-{subj:03d}.xlsx")
            pd.DataFrame([bias_scores]).to_excel(indiv_out, index=False)

            merged_results.append(bias_scores)
            print(f"[{subj}] Completed -> {indiv_out}")

        except FileNotFoundError:
            print(f"[{subj}] Source file not found: {file_path}")
        except Exception as exc:
            print(f"[{subj}] Error during processing: {exc}")

    # --------------------------------------------------------------
    # 7) Save the merged subject-level bias-score table
    # --------------------------------------------------------------
    if merged_results:
        merged_df = pd.DataFrame(merged_results)
        merged_out = os.path.join(RESULT_DIR, "WSAP-score-nrl-merged-101-120.xlsx")
        merged_df.to_excel(merged_out, index=False)
        print(f"\nMerged results saved -> {merged_out}")
    else:
        print("\nNo results were available for merging.")


if __name__ == "__main__":
    main()
