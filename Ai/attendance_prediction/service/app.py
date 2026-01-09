from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import numpy as np
import pandas as pd
from pathlib import Path

app = FastAPI(title="Eventy Attendance Predictor")

MODEL_PATH = Path(__file__).resolve().parents[1] / "artifacts" / "best_model.joblib"
model = joblib.load(MODEL_PATH)

# These must match what your training used (select_X / preprocess)
MODEL_FEATURES = [
    "price_syp",
    "capacity",
    "duration_hours",
    "days_before_event_posted",
    "start_hour",
    "is_weekend_syria",
    "category",
    "place",
]

class EventInput(BaseModel):
    posted_datetime: str
    event_start_datetime: str
    event_end_datetime: str
    price_syp: float
    capacity: int
    category: str
    place: str

def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # Parse datetimes safely
    df["posted_datetime"] = pd.to_datetime(df["posted_datetime"], errors="coerce")
    df["event_start_datetime"] = pd.to_datetime(df["event_start_datetime"], errors="coerce")
    df["event_end_datetime"] = pd.to_datetime(df["event_end_datetime"], errors="coerce")

    # Validate parsing
    if df[["posted_datetime", "event_start_datetime", "event_end_datetime"]].isna().any().any():
        raise ValueError("Invalid datetime format. Use ISO format like '2026-01-10 19:00:00'.")

    # Validate logical order
    if (df["event_end_datetime"] <= df["event_start_datetime"]).any():
        raise ValueError("event_end_datetime must be after event_start_datetime.")

    # Compute derived features
    df["day_of_week"] = df["event_start_datetime"].dt.weekday  # Mon=0 ... Sun=6
    df["is_weekend_syria"] = df["day_of_week"].isin([4, 5]).astype(int)  # Fri=4 Sat=5
    df["start_hour"] = df["event_start_datetime"].dt.hour

    df["days_before_event_posted"] = (
        (df["event_start_datetime"] - df["posted_datetime"]).dt.total_seconds()
        / (3600 * 24)
    )

    df["duration_hours"] = (
        (df["event_end_datetime"] - df["event_start_datetime"]).dt.total_seconds()
        / 3600
    )

    # Enforce the business rule: posted at least 24h before start (optional but consistent with your dataset)
    # If you prefer to allow shorter lead times, delete this block.
    if (df["days_before_event_posted"] < 1.0).any():
        raise ValueError("posted_datetime must be at least 24 hours before event_start_datetime.")

    # Safety clamps
    df["days_before_event_posted"] = df["days_before_event_posted"].clip(lower=0.0)
    df["duration_hours"] = df["duration_hours"].clip(lower=0.25)

    # Final: keep only the features the model expects (prevents mismatch / leakage)
    df = df[MODEL_FEATURES].copy()

    return df

@app.post("/predict")
def predict(inp: EventInput):
    try:
        X_raw = pd.DataFrame([inp.model_dump() if hasattr(inp, "model_dump") else inp.dict()])
        X = engineer_features(X_raw)

        pred_rate = float(np.clip(model.predict(X)[0], 0.0, 1.0))
        pred_att = int(round(pred_rate * int(inp.capacity)))

        return {
            "predicted_attendance_rate": pred_rate,
            "predicted_attendance": pred_att,
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        # Unknown errors -> 500
        raise HTTPException(status_code=500, detail=f"Prediction failed: {e}")
