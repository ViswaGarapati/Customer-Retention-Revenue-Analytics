"""Run the five read-only investigations against the completed database."""
import sqlite3
from pathlib import Path

root = Path(__file__).resolve().parent
with sqlite3.connect((root/"output/retention.sqlite").as_uri()+"?mode=ro", uri=True) as db:
    statement = ""
    for line in (root/"sql/04_investigation.sql").read_text().splitlines(True):
        statement += line
        if sqlite3.complete_statement(statement):
            result = db.execute(statement)
            print(" | ".join(col[0] for col in result.description))
            for row in result:
                print(" | ".join(map(str,row)))
            print()
            statement = ""
