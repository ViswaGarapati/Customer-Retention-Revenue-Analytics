import sqlite3


def validate(db):
    checks = {
        "foreign keys": "PRAGMA foreign_key_check",
        "unique, complete lifecycle": """SELECT a.id FROM account a JOIN calendar c ON c.month>=a.joined
            LEFT JOIN customer_month m ON m.id=a.id AND m.month=c.month WHERE m.id IS NULL""",
        "opening to closing bridge": """SELECT * FROM bridge WHERE
            opening+new_mrr+winback+expansion-contraction-churn<>closing""",
        "invoice per active contract": """SELECT m.id FROM customer_month m LEFT JOIN invoice i
            ON m.id=i.account_id AND m.month=i.month WHERE m.closing<>coalesce(i.amount,0)""",
        "no unmatched invoices": """SELECT i.id FROM invoice i LEFT JOIN customer_month m
            ON i.account_id=m.id AND i.month=m.month WHERE m.id IS NULL""",
        "retry integrity": """SELECT i.id FROM invoice i LEFT JOIN payment_attempt p ON i.id=p.invoice_id
            GROUP BY i.id HAVING min(attempt) IS NOT 1 OR sum(collected)>amount
            OR (count(attempt)>1 AND max(CASE WHEN attempt=1 THEN collected END)>0)""",
        "stable cohort denominator": """SELECT c.joined FROM cohorts c JOIN cohorts b
            ON c.joined=b.joined AND c.channel=b.channel AND b.age=0
            WHERE c.cohort_size<>b.cohort_size OR b.active<>b.cohort_size""",
        "retention bounds": """SELECT * FROM monthly_kpi WHERE grr<0 OR grr>1 OR grr>nrr
            OR logo_churn_rate<0 OR logo_churn_rate>1""",
    }
    for name, sql in checks.items():
        if db.execute(sql).fetchone() is not None:
            raise ValueError(f"Failed check: {name}")
    return len(checks)


def fixture(sql_dir):
    """Hand-calculated contract, with a failed renewal and a win-back."""
    with sqlite3.connect(":memory:") as db:
        db.executescript((sql_dir/"01_sources.sql").read_text())
        for i in range(6):
            db.execute("INSERT INTO calendar VALUES (?,?)", (f"2024-0{i+1}-01", i))
        db.execute("INSERT INTO account VALUES (1,'Organic','2024-01-01')")
        for i, amount in enumerate([100, 150, 120, 0, 0, 90], 1):
            month = f"2024-0{i}-01"
            if i != 5:
                db.execute("INSERT INTO contract_event VALUES (1,?,?)", (month, amount))
            if amount:
                db.execute("INSERT INTO invoice VALUES (?,1,?,?)", (i, month, amount))
                db.execute("INSERT INTO payment_attempt VALUES (?,1,?)", (i, 0 if i==2 else amount))
                if i==2:
                    db.execute("INSERT INTO payment_attempt VALUES (?,2,150)", (i,))
        for name in ["02_lifecycle.sql", "03_marts.sql"]:
            db.executescript((sql_dir/name).read_text())
        validate(db)
        rows = db.execute("SELECT movement FROM customer_month ORDER BY month").fetchall()
        assert [r[0] for r in rows] == ["new","expansion","contraction","churn","inactive","reactivation"]
        assert db.execute("SELECT nrr,grr FROM monthly_kpi WHERE month='2024-02-01'").fetchone()==(1.5,1)
        assert db.execute("SELECT billed,collected,recovered FROM collections WHERE failed=1").fetchone()==(150,150,1)
        assert db.execute("SELECT max(age),sum(first_churns) FROM first_churn_risk").fetchone()==(3,1)
