import pandas as pd
import numpy as np
from pathlib import Path

from common.featurize import add_features
from common.plots import (
    plot_target_hist, plot_corr_matrix, plot_scatter
)

DATA = Path(__file__).resolve().parents[1] / "data" / "dataset.csv"
OUT = Path(__file__).resolve().parents[1] / "runs" / "eda"
OUT.mkdir(parents=True, exist_ok=True)

df = pd.read_csv(DATA)
df = add_features(df)

# Target
if "attendance_rate" not in df.columns:
    df["attendance_rate"] = (df["attendance"] / df["capacity"]).clip(0,1)

# Plots
plot_target_hist(df["attendance_rate"].values, str(OUT/"target_hist.png"))

num_cols = ["price_syp","capacity","duration_hours","days_before_event_posted","start_hour","day_of_week","month","attendance_rate"]
plot_corr_matrix(df[num_cols], str(OUT/"corr_matrix.png"))

plot_scatter(df["price_syp"], df["attendance_rate"],
             "price_syp","attendance_rate","Price vs Attendance Rate",
             str(OUT/"price_vs_rate.png"))

plot_scatter(df["days_before_event_posted"], df["attendance_rate"],
             "days_before_event_posted","attendance_rate","Lead time vs Attendance Rate",
             str(OUT/"leadtime_vs_rate.png"))

# Summary
summary = {
    "rows": int(len(df)),
    "mean_rate": float(df["attendance_rate"].mean()),
    "sellout_rate": float((df["attendance_rate"] >= 0.999).mean()),
    "weekend_mean": float(df.loc[df["day_of_week"].isin([4,5]), "attendance_rate"].mean()),
    "weekday_mean": float(df.loc[~df["day_of_week"].isin([4,5]), "attendance_rate"].mean()),
}
(OUT/"summary.json").write_text(pd.Series(summary).to_json(), encoding="utf-8")
print("EDA saved to:", OUT)
print(summary)
