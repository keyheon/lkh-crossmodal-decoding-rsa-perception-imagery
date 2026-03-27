RSA × behavior correlation package
==================================

Files
-----
- analyze_rsa_behavior_correlations.py
- utility_functions/
    - read_rs_csv.py
    - permutation_p_spearman.py
    - sanitize_filename.py
    - pretty_text.py
    - pretty_roi_label.py
    - roi_color_from_short.py
    - fit_ols_line.py
    - fdr_bh.py
    - plot_roi_behavior_scatter.py

What this package does
----------------------
This package computes permutation-based Spearman correlations between
ROI-wise RSA values and four behavioral variables used in the manuscript:

- ERQ_reappraisal
- ERQ_suppression
- Benign_Endorsement_Rate
- Threat_Endorsement_Rate

The script assumes that the RS table already contains only the manuscript
ROIs (left/right amygdala, insula, ACC, vmPFC).

Outputs
-------
- RSA_Behavior_perm_results_ALL.csv
- plots_by_roi/<ROI_short>/<DV>__<ROI_short>.png

To-do before running this script
--------------------------------
- extract data from SubjectRS_runbeta_24x24_<yymmdd>.csv
- create csv file "subject_RS_roi.csv" with the following columns:

	ROI    Subject    RS_spearman


How to run
----------
1. Edit BEHAVIOR_CSV, RS_CSV, and OUT_BASE at the top of
   analyze_rsa_behavior_correlations.py.
2. Run:

   python analyze_rsa_behavior_correlations.py

Required Python packages
------------------------
- numpy
- pandas
- scipy
- matplotlib
