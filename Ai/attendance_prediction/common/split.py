import pandas as pd
from dataclasses import dataclass

@dataclass
class Split:
    train_idx: pd.Index
    val_idx: pd.Index
    test_idx: pd.Index

def time_split(df: pd.DataFrame, time_col: str = "event_start_datetime",
               train_frac: float = 0.70, val_frac: float = 0.15) -> Split:
    if time_col not in df.columns:
        raise ValueError(f"{time_col} not found in dataframe")
    df_sorted = df.sort_values(time_col).reset_index(drop=True)
    n = len(df_sorted)
    train_end = int(n * train_frac)
    val_end = int(n * (train_frac + val_frac))
    return Split(
        train_idx=df_sorted.index[:train_end],
        val_idx=df_sorted.index[train_end:val_end],
        test_idx=df_sorted.index[val_end:],
    ), df_sorted
