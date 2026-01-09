
import json
import numpy as np
import pandas as pd
from pathlib import Path

from sklearn.pipeline import Pipeline
from sklearn.model_selection import TimeSeriesSplit, GridSearchCV, RandomizedSearchCV
from sklearn.metrics import make_scorer, mean_absolute_error

from common.featurize import add_features, select_X
from common.split import time_split
from common.preprocessing import make_preprocess
from common.metrics import regression_metrics, attendees_mae
from common.plots import plot_actual_vs_pred, plot_residuals, plot_overfit, plot_hyperparam_curve, plot_param_vs_best
from common.io import make_run_dir, save_json



RANDOM_STATE = 42
DATA = Path(__file__).resolve().parents[2] / "data" / "dataset.csv"

def neg_mae(y_true, y_pred):
    y_pred = np.clip(y_pred, 0, 1)
    return -mean_absolute_error(y_true, y_pred)

SCORER = make_scorer(neg_mae, greater_is_better=True)

def load_data():
    df = pd.read_csv(DATA)
    df = add_features(df)
    if "attendance_rate" not in df.columns:
        df["attendance_rate"] = (df["attendance"] / df["capacity"]).clip(0,1)
    return df

def save_common_outputs(run_dir, y_test, y_pred, test_df, model_name, extra_metrics):
    # Save predictions
    out = test_df[["event_start_datetime","capacity","attendance","attendance_rate","organizer_name","category","place","price_syp"]].copy()
    out["pred_rate"] = np.clip(y_pred, 0, 1)
    out["pred_attendance"] = (out["pred_rate"] * out["capacity"]).round().astype(int)
    out.to_csv(run_dir / "preds_test.csv", index=False)

    # Plots
    plot_actual_vs_pred(y_test, np.clip(y_pred, 0, 1), f"Actual vs Pred (TEST) — {model_name}", str(run_dir/"plots"/"actual_vs_pred.png"))
    plot_residuals(y_test, np.clip(y_pred, 0, 1), f"{model_name} (TEST)", str(run_dir/"plots"))

    # Metrics
    m = {}
    m.update(regression_metrics(y_test, y_pred, prefix="test_"))
    m["test_Attendees_MAE"] = attendees_mae(y_test, y_pred, test_df["capacity"].values)
    m.update(extra_metrics)
    save_json(m, run_dir / "metrics.json")
    return m

from sklearn.linear_model import Ridge

RUNS_BASE = Path(__file__).resolve().parent

def main():
    df = load_data()
    split, df_sorted = time_split(df, time_col="event_start_datetime")
    train_df = df_sorted.loc[split.train_idx]
    val_df   = df_sorted.loc[split.val_idx]
    test_df  = df_sorted.loc[split.test_idx]

    X_train = select_X(train_df)
    y_train = train_df["attendance_rate"].values
    X_val   = select_X(val_df)
    y_val   = val_df["attendance_rate"].values
    X_test  = select_X(test_df)
    y_test  = test_df["attendance_rate"].values

    preprocess = make_preprocess(scale_numeric=True)

    # Hyperparameter sweep for Ridge alpha
    alphas = [0.05, 0.1, 0.3, 1, 3, 10, 30, 100]
    train_scores, val_scores = [], []
    best = None
    best_mae = 1e9
    best_alpha = None
    best_pipe = None

    for a in alphas:
        pipe = Pipeline(steps=[("preprocess", preprocess),
                               ("model", Ridge(alpha=a, random_state=RANDOM_STATE))])
        pipe.fit(X_train, y_train)
        pred_train = pipe.predict(X_train)
        pred_val = pipe.predict(X_val)

        tr_mae = mean_absolute_error(y_train, np.clip(pred_train,0,1))
        va_mae = mean_absolute_error(y_val, np.clip(pred_val,0,1))
        # for "improvement" plots, higher score is better, so use -MAE
        train_scores.append(-tr_mae)
        val_scores.append(-va_mae)

        if va_mae < best_mae:
            best_mae = va_mae
            best_alpha = a
            best_pipe = pipe

    run_dir = make_run_dir(RUNS_BASE, "try1_ridge")
    save_json({"alphas": alphas, "train_score_-mae": train_scores, "val_score_-mae": val_scores}, run_dir/"curve.json")

    plot_overfit(train_scores, val_scores, "Ridge: Train vs Val (-MAE) across alpha trials", str(run_dir/"plots"/"overfit_curve.png"))
    plot_hyperparam_curve(alphas, val_scores, "alpha", "Ridge: CV proxy (-MAE) vs alpha", str(run_dir/"plots"/"alpha_curve.png"))
    plot_param_vs_best(
    alphas,
    val_scores,
    best_alpha,
    "Ridge: Validation score (-MAE) vs alpha (best highlighted)",
    "alpha",
    str(run_dir/"plots"/"alpha_vs_best.png")
)

    # Refit on train+val, test
    X_tv = pd.concat([X_train, X_val])
    y_tv = np.concatenate([y_train, y_val])
    best_pipe.fit(X_tv, y_tv)
    pred_test = best_pipe.predict(X_test)

    extra = {"model": "RidgeRegression", "best_alpha": best_alpha, "val_MAE": float(best_mae)}
    m = save_common_outputs(run_dir, y_test, pred_test, test_df, "Ridge", extra)

    import joblib
    joblib.dump(best_pipe, run_dir/"model.joblib")

    print("Saved run:", run_dir)
    print("Test metrics:", m)

if __name__ == "__main__":
    main()
