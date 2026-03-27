from __future__ import annotations

import numpy as np
import pandas as pd


# ===================================================================
# Author of this script:
#   Ki Heon Lee
# Contact:
#   kiheon97@gmail.com
# ===================================================================
def calculate_bias_scores(df: pd.DataFrame) -> dict:
    """Compute WSAP endorsement rates and endorsed-trial response-time summaries."""
    benign_trials = df[df["type"] == "benign"]
    threat_trials = df[df["type"] == "negative"]

    benign_endorsed = benign_trials[benign_trials["correct"] == 1]
    threat_endorsed = threat_trials[threat_trials["correct"] == 1]

    benign_rate = (
        len(benign_endorsed) / len(benign_trials) * 100
        if len(benign_trials)
        else np.nan
    )
    threat_rate = (
        len(threat_endorsed) / len(threat_trials) * 100
        if len(threat_trials)
        else np.nan
    )

    return {
        "Benign Endorsement Rate (%)": benign_rate,
        "Threat Endorsement Rate (%)": threat_rate,
        "Average Response Time (Benign)": benign_endorsed["response_time"].mean(),
        "Average Response Time (Threat)": threat_endorsed["response_time"].mean(),
        "Sem Response Time (Benign)": benign_endorsed["response_time"].sem(),
        "Sem Response Time (Threat)": threat_endorsed["response_time"].sem(),
    }
