import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def savefig(path: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    plt.tight_layout()
    plt.savefig(path, dpi=160)
    plt.close()

def plot_target_hist(y, outpath):
    plt.figure()
    plt.hist(y, bins=20)
    plt.title("Attendance Rate Distribution")
    plt.xlabel("attendance_rate")
    plt.ylabel("count")
    savefig(outpath)

def plot_corr_matrix(df_numeric: pd.DataFrame, outpath: str):
    corr = df_numeric.corr(numeric_only=True)
    plt.figure(figsize=(7,6))
    plt.imshow(corr.values, aspect="auto")
    plt.title("Correlation Matrix (numeric features)")
    plt.xticks(range(len(corr.columns)), corr.columns, rotation=90, fontsize=8)
    plt.yticks(range(len(corr.columns)), corr.columns, fontsize=8)
    plt.colorbar()
    savefig(outpath)

def plot_scatter(x, y, xlabel, ylabel, title, outpath):
    plt.figure()
    plt.scatter(x, y)
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    savefig(outpath)

def plot_actual_vs_pred(y_true, y_pred, title, outpath):
    plt.figure()
    plt.scatter(y_true, y_pred)
    plt.plot([0,1],[0,1])
    plt.title(title)
    plt.xlabel("Actual attendance_rate")
    plt.ylabel("Predicted attendance_rate")
    savefig(outpath)

def plot_residuals(y_true, y_pred, title_prefix, outdir):
    res = y_true - y_pred
    plt.figure()
    plt.hist(res, bins=20)
    plt.title(f"{title_prefix} Residuals Histogram")
    plt.xlabel("residual (actual - pred)")
    plt.ylabel("count")
    savefig(os.path.join(outdir, "residuals_hist.png"))

    plt.figure()
    plt.scatter(y_pred, res)
    plt.axhline(0)
    plt.title(f"{title_prefix} Residuals vs Predicted")
    plt.xlabel("predicted")
    plt.ylabel("residual")
    savefig(os.path.join(outdir, "residuals_vs_pred.png"))

def plot_overfit(train_scores, val_scores, title, outpath):
    plt.figure()
    plt.plot(range(len(train_scores)), train_scores, label="train")
    plt.plot(range(len(val_scores)), val_scores, label="val")
    plt.title(title)
    plt.xlabel("trial")
    plt.ylabel("score (higher is better)")
    plt.legend()
    savefig(outpath)

def plot_hyperparam_curve(param_values, scores, xlabel, title, outpath):
    plt.figure()
    plt.plot(param_values, scores, marker="o")
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel("CV score (higher is better)")
    savefig(outpath)
def plot_param_vs_best(param_values, scores, best_param, title, xlabel, outpath):
    # scores are "higher is better" (we use -MAE)
    best_score = max(scores)

    plt.figure()
    plt.plot(param_values, scores, marker="o")
    plt.axhline(best_score, linestyle="--", label=f"best score = {best_score:.4f}")

    # mark best param point
    try:
        best_i = list(param_values).index(best_param)
        plt.scatter([param_values[best_i]], [scores[best_i]], s=80, label=f"best {xlabel} = {best_param}")
    except Exception:
        pass

    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel("score (higher is better) = -MAE")
    plt.legend()
    savefig(outpath)
