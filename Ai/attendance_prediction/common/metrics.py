import numpy as np
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

def clip_rate(y_pred):
    return np.clip(y_pred, 0.0, 1.0)

def regression_metrics(y_true, y_pred, prefix=""):
    y_pred = clip_rate(y_pred)
    mse = mean_squared_error(y_true, y_pred)
    rmse = float(np.sqrt(mse))
    return {
        f"{prefix}MAE": float(mean_absolute_error(y_true, y_pred)),
        f"{prefix}RMSE": rmse,
        f"{prefix}R2": float(r2_score(y_true, y_pred)),
    }

def attendees_mae(y_true_rate, y_pred_rate, capacity):
    y_pred_rate = clip_rate(y_pred_rate)
    true_att = y_true_rate * capacity
    pred_att = y_pred_rate * capacity
    return float(mean_absolute_error(true_att, pred_att))
