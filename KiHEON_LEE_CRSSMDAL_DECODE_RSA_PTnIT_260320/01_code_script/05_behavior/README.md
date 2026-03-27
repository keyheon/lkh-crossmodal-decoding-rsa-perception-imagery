Place all files in the same package directory, keeping the utility_functions
folder alongside the main script.

Recommended structure:
  wsap_behavior_analysis_package/
      analyze_wsap_scores.py
      utility_functions/
          __init__.py
          calculate_bias_scores.py
          select_wsap_columns.py
          winsorize_response_times.py

This package preserves the logic and output filenames of the original WSAP
analysis script.

Outputs:
  - Revised subject-level CSV files:
      rrevised-WSAP-nrl-<subj>.csv
  - Subject-level Excel files:
      WSAP-score-nrl-<subj>.xlsx
  - Merged Excel file:
      WSAP-score-nrl-merged-101-120.xlsx

Run from the package directory with:
  python analyze_wsap_scores.py

Edit BASE_DIR at the top of analyze_wsap_scores.py as needed for your local
filesystem.
