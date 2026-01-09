# Eventy Attendance Prediction — Regression Experiments (3 Tries)

## Important correction
You asked for **logistic regression**, but logistic regression is a **classification** algorithm.
Since your target is **attendance_rate** (a continuous value), TRY 1 uses **Ridge Regression** as the linear baseline.
(If you truly want classification, you'd have to convert attendance_rate into classes — but that changes the problem.)

## Dataset
`data/dataset.csv` (copied from your `new_last_realistic.csv`)

## What to run right now (in order)
1) **EDA + plots**
```bash
python experiments/eda.py
```
Outputs to: `runs/eda/` (target hist, correlation matrix, scatter plots, summary).

2) **Try 1 — Ridge (linear baseline)**
```bash
python experiments/try1_linear_ridge/train.py
```

3) **Try 2 — Random Forest (hyperparameter search)**
```bash
python experiments/try2_random_forest/train.py
```

4) **Try 3 — XGBoost (hyperparameter search)**
```bash
python experiments/try3_xgboost/train.py
```
> If this fails with "xgboost not installed", run:
> `pip install xgboost`
> Or tell me and I will switch TRY3 to sklearn HistGradientBoosting.

5) **Compare all runs**
```bash
python compare/compare_runs.py
```
This produces:
- `compare/results.csv` (sorted by test_MAE)
- `compare/test_mae_bar.png`
- `compare/test_attendees_mae_bar.png`

## What gets saved for each try
Inside `experiments/<try>/runs/<run_timestamp>/`:
- `model.joblib` (full pipeline)
- `metrics.json` (test metrics + best params)
- `cv_results.csv` (for Try2/3)
- `preds_test.csv` (actual vs predicted)
- `plots/` (overfitting curve + hyperparam curve + residual plots)

## Notes about “accuracy”
For regression, “accuracy” is not the right metric. We use:
- MAE (primary)
- RMSE
- R²
Plus attendees-MAE for a business-friendly number.
