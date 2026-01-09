import numpy as np
import pandas as pd

# Posting-time safe feature engineering.
# Keep this consistent across all tries.

NUMERIC_FEATURES = [
    "price_syp",
    "log_price_syp",
    "capacity",
    "duration_hours",
    "days_before_event_posted",
    "start_hour",
    "day_of_week",
    "month",
    "is_weekend_syria",
]

CATEGORICAL_FEATURES = ["organizer_name", "category", "place"]

RAW_REQUIRED = [
    "posted_datetime",
    "event_start_datetime",
    "event_end_datetime",
    "price_syp",
    "capacity",
    "organizer_name",
    "category",
    "place",
]

def add_features(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # Parse datetimes
    df["posted_datetime"] = pd.to_datetime(df["posted_datetime"])
    df["event_start_datetime"] = pd.to_datetime(df["event_start_datetime"])
    df["event_end_datetime"] = pd.to_datetime(df["event_end_datetime"])

    # Time features
    df["day_of_week"] = df["event_start_datetime"].dt.weekday
    df["is_weekend_syria"] = df["day_of_week"].isin([4, 5]).astype(int)
    df["start_hour"] = df["event_start_datetime"].dt.hour
    df["month"] = df["event_start_datetime"].dt.month

    # Lead time (days, float)
    df["days_before_event_posted"] = (df["event_start_datetime"] - df["posted_datetime"]).dt.total_seconds() / (3600 * 24)

    # Duration
    df["duration_hours"] = (df["event_end_datetime"] - df["event_start_datetime"]).dt.total_seconds() / 3600.0

    # Price transform
    df["log_price_syp"] = np.log1p(df["price_syp"].astype(float))

    return df

def select_X(df: pd.DataFrame) -> pd.DataFrame:
    missing = [c for c in RAW_REQUIRED if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")
    df2 = add_features(df)
    return df2[NUMERIC_FEATURES + CATEGORICAL_FEATURES]
