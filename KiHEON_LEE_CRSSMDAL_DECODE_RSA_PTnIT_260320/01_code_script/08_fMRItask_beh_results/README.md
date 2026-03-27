Contents
--------
1) analyze_nrl_ratings.py
   Output:
     - ratings_subject_emotion_stats.csv
     - ratings_group_emotion_stats.csv

2) analyze_nrl_behavior_summary.py
   Output:
     - descriptives_all_variables.csv
     - descriptives_ratings_only.csv
     - anova_PT_perceived_intensity.csv
     - anova_IT_vividness.csv
     - ttests_perceived_vs_neutral.csv
     - ttests_vividness_vs_neutral.csv
     - behavioral_report.txt

Structure
---------
Place the package in a single folder with the following layout:

  08_fMRItask_beh_results/
    analyze_nrl_ratings.py
    analyze_nrl_behavior_summary.py
    utility_functions/
      __init__.py
      is_subject_dir.py
      read_ratings.py
      stats_from_array.py
      clean_text.py
      stars.py
      cohens_dz_from_diff.py
      partial_eta_squared_from_F.py
      find_subject_col.py
      paired_t.py
      wide_to_long.py
      run_rm_anova.py
      summarize_means.py

Requirements
------------
- Python 3.9+
- pandas
- numpy
- scipy
- statsmodels
- Optional: pingouin (for repeated-measures ANOVA with sphericity output)

Notes
-----
- If pingouin is not installed, repeated-measures ANOVA is run using statsmodels.AnovaRM.
- Edit the path constants at the top of each main script before execution.

To-do before running the script "analyze_nrl_behavior_summary.py"
-----------------------------------------------------------------
- extract data from "ratings_subject_emotion_stats.csv" via "analyze_nrl_ratings.py"
- create csv file "nrl_behavioral_descript.csv" with the following columns added to the
  "260320_behavioral_results.csv" columns:

	ang_perceived_intensity    hap_perceived_intensity    sad_perceived_intensity

	neut_perceived_intensity   ang_vividness              hap_vividness

        sad_vividness              neut_vividness


Usage
-----
python analyze_nrl_ratings.py
python analyze_nrl_behavior_summary.py
