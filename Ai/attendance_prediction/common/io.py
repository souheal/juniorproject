import json, os, time
from pathlib import Path

def make_run_dir(base_dir: Path, run_name: str) -> Path:
    ts = time.strftime("%Y-%m-%d_%H-%M-%S")
    run_dir = base_dir / "runs" / f"{run_name}_{ts}"
    run_dir.mkdir(parents=True, exist_ok=True)
    (run_dir / "plots").mkdir(exist_ok=True)
    return run_dir

def save_json(obj, path: Path):
    path.write_text(json.dumps(obj, indent=2), encoding="utf-8")
