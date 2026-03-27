This package contains the cleaned decoding accuracy × behavior analysis code.

Files
-----
merge_overall_accuracy.py
    Merge subject-level ROI decoding outputs into one long-format table.

analyze_accuracy_behavior_correlations.py
    Run ROI-wise accuracy × behavior correlations using:
      - Spearman correlation
      - two-sided permutation test
      - within-ROI Benjamini-Hochberg FDR
      - per-ROI scatter plots

utility_functions/
    Helper functions used by the scripts.

Outputs
-------
merge_overall_accuracy.py
    - SubjectOverallAccuracy_long.csv
    - SubjectOverallAccuracy_long.xlsx

analyze_accuracy_behavior_correlations.py
    - ACC_Behavior_perm_results_ALL.csv
    - plots_by_roi/<ROI_short>/*.png

Notes
-----
1. Edit the path variables at the top of each main script to match your local environment.
2. The correlation script assumes that only the manuscript ROIs are present in the merged
   decoding accuracy file and analyzes only the following behavioral variables:
       ERQ_reappraisal
       ERQ_suppression
       Benign_Endorsement_Rate
       Threat_Endorsement_Rate
