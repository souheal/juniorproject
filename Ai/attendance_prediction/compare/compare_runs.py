import json
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

BASE = Path(__file__).resolve().parents[1]
EXP = BASE / "experiments"
OUT = BASE / "compare"
OUT.mkdir(parents=True, exist_ok=True)

def find_metrics():
    metrics_files = list(EXP.glob("**/runs/*/metrics.json"))
    rows = []
    for mf in metrics_files:
        data = json.loads(mf.read_text(encoding="utf-8"))
        data["run_dir"] = str(mf.parent)
        # include try name
        data["try"] = mf.parents[2].name  # experiments/<try>/runs/<run>/metrics.json
        rows.append(data)
    return pd.DataFrame(rows)

df = find_metrics()
if df.empty:
    raise SystemExit("No metrics found. Run the training scripts first.")

# Sort by test_MAE (lower is better)
df = df.sort_values("test_MAE")
df.to_csv(OUT/"results.csv", index=False)
print("Saved:", OUT/"results.csv")
print(df[["try","model","test_MAE","test_RMSE","test_R2","test_Attendees_MAE","run_dir"]].head(20))

# Bar plot MAE
plt.figure(figsize=(8,4))
plt.bar(range(len(df)), df["test_MAE"].values)
plt.title("Test MAE by Run (lower is better)")
plt.xlabel("run (sorted)")
plt.ylabel("test_MAE")
plt.tight_layout()
plt.savefig(OUT/"test_mae_bar.png", dpi=160)
plt.close()

# Bar plot attendees MAE
plt.figure(figsize=(8,4))
plt.bar(range(len(df)), df["test_Attendees_MAE"].values)
plt.title("Test Attendees MAE by Run (lower is better)")
plt.xlabel("run (sorted)")
plt.ylabel("test_Attendees_MAE")
plt.tight_layout()
plt.savefig(OUT/"test_attendees_mae_bar.png", dpi=160)
plt.close()

print("Saved plots to compare/")
