
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

RUNS_BASE = Path(__file__).resolve().parent

def main():
    try:
        from xgboost import XGBRegressor
    except Exception as e:
        raise ImportError(
            "xgboost is not installed. Install it (pip install xgboost) or switch TRY3 to sklearn HistGradientBoostingRegressor."
        ) from e

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

    preprocess = make_preprocess(scale_numeric=False)

    pipe = Pipeline(steps=[
        ("preprocess", preprocess),
        ("model", XGBRegressor(
            objective="reg:squarederror",
            random_state=RANDOM_STATE,
            n_jobs=-1
        ))
    ])

    # Tune with TimeSeriesSplit on train+val
    X_tv = pd.concat([X_train, X_val])
    y_tv = np.concatenate([y_train, y_val])

    tscv = TimeSeriesSplit(n_splits=5)

    param_dist = {
        "model__n_estimators": [300, 600, 1000, 1500, 2000],
        "model__learning_rate": [0.01, 0.03, 0.05, 0.1],
        "model__max_depth": [3, 4, 6, 8],
        "model__subsample": [0.7, 0.85, 1.0],
        "model__colsample_bytree": [0.7, 0.85, 1.0],
        "model__min_child_weight": [1, 3, 5, 10],
        "model__reg_lambda": [1, 5, 10],
    }

    search = RandomizedSearchCV(
        pipe,
        param_distributions=param_dist,
        n_iter=45,
        scoring=SCORER,
        cv=tscv,
        random_state=RANDOM_STATE,
        n_jobs=-1,
        return_train_score=True
    )
    search.fit(X_tv, y_tv)

    run_dir = make_run_dir(RUNS_BASE, "try3_xgboost")
    pd.DataFrame(search.cv_results_).to_csv(run_dir/"cv_results.csv", index=False)

    train_scores = search.cv_results_["mean_train_score"].tolist()
    val_scores = search.cv_results_["mean_test_score"].tolist()
    plot_overfit(train_scores, val_scores, "XGBoost: Train vs CV (-MAE) across trials", str(run_dir/"plots"/"overfit_curve.png"))

    # Hyperparameter curve: max_depth vs best CV score
    dfres = pd.DataFrame(search.cv_results_)
    best_depth = int(search.best_params_["model__max_depth"])
    grp = dfres.groupby("param_model__max_depth")["mean_test_score"].max().reset_index()
    param_vals = grp["param_model__max_depth"].astype(int).tolist()
    scores = grp["mean_test_score"].tolist()

    plot_param_vs_best(
        param_vals,
        scores,
        best_depth,
        "XGBoost: best CV score (-MAE) vs max_depth (best highlighted)",
        "max_depth",
        str(run_dir/"plots"/"max_depth_vs_best.png")
    )

    grp = dfres.groupby("param_model__max_depth")["mean_test_score"].max().reset_index()
    plot_hyperparam_curve(grp["param_model__max_depth"].astype(int).tolist(),
                          grp["mean_test_score"].tolist(),
                          "max_depth",
                          "XGBoost: best CV (-MAE) vs max_depth",
                          str(run_dir/"plots"/"max_depth_curve.png"))

    best_pipe = search.best_estimator_
    pred_test = best_pipe.predict(X_test)

    extra = {
        "model": "XGBRegressor",
        "best_params": search.best_params_,
        "best_cv_score_-mae": float(search.best_score_),
    }
    m = save_common_outputs(run_dir, y_test, pred_test, test_df, "XGBoost", extra)

    import joblib
    joblib.dump(best_pipe, run_dir/"model.joblib")

    print("Saved run:", run_dir)
    print("Test metrics:", m)

if __name__ == "__main__":
    main()
