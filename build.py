"""Build and validate in staging, then replace each completed output."""
import csv
import json
import sqlite3
import tempfile
from pathlib import Path

from simulate import populate
from validate import fixture, validate

ROOT = Path(__file__).resolve().parent
SQL = ROOT / "sql"
OUTPUT = ROOT / "output"


def build():
    OUTPUT.mkdir(exist_ok=True)
    fixture(SQL)
    with tempfile.TemporaryDirectory(dir=OUTPUT) as tmp:
        stage = Path(tmp)
        db = sqlite3.connect(stage / "retention.sqlite")
        try:
            db.executescript((SQL / "01_sources.sql").read_text())
            populate(db)
            for filename in ("02_lifecycle.sql", "03_marts.sql"):
                db.executescript((SQL / filename).read_text())
            checks = validate(db)
            db.commit()
            db.row_factory = sqlite3.Row
            data = {}
            for view in ("monthly_kpi", "collections", "cohorts", "first_churn_risk"):
                rows = [dict(row) for row in db.execute(f"SELECT * FROM {view} ORDER BY 1,2,3")]
                data[view] = rows
                with (stage / f"{view}.csv").open("w", newline="") as stream:
                    writer = csv.DictWriter(stream, fieldnames=rows[0])
                    writer.writeheader()
                    writer.writerows(rows)
            html = (ROOT / "dashboard.template.html").read_text()
            (stage / "dashboard.html").write_text(html.replace("__DATA__", json.dumps(data,separators=(",",":"))))
        finally:
            db.close()
        for artifact in stage.iterdir():
            artifact.replace(OUTPUT / artifact.name)
    print(f"Built output/. Passed {checks} warehouse checks and the hand-calculated lifecycle fixture.")


if __name__ == "__main__":
    build()
