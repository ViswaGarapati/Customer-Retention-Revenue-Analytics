# Customer Retention & Revenue Analytics

A SQL-first investigation of a fictional B2B subscription business with three acquisition channels and three monthly plans. The question for finance is whether growth comes from retaining existing revenue, expanding accounts or continuing to acquire customers.

## Start here

1. Open **output/dashboard.html** in a browser. Filter by month and channel to inspect the MRR bridge, retention cohorts and failed-payment recovery. The page works offline.
2. Read **CASE_STUDY.md** for the October 2026 decision brief.
3. Run the five analyses from the project directory with **python3 investigate.py**. You can also open **output/retention.sqlite** in a SQLite database browser and run individual statements from **sql/04_investigation.sql**.

To rebuild every data output and the dashboard on Fedora, macOS or Windows with Python installed, run the commands below (on Windows, use `py` in place of `python3`). Tested with Python 3.12 and SQLite 3.53. The project uses only the Python standard library. SQLite 3.25+ is required for window functions.

```bash
python3 build.py
python3 investigate.py
```

## Warehouse design

| Source or model | Grain | Function |
|---|---|---|
| calendar | One calendar month | January 2024 through October 2026 inclusive |
| account | One customer | Signup month and original acquisition channel |
| contract_event | Customer and effective month | Replacement MRR on signup, upgrade, downgrade, cancellation or reactivation |
| invoice | Active customer and billing month | One bill for each active contract-month |
| payment_attempt | Invoice and attempt number | Initial charge and optional retry within the billing month |
| customer_month | Customer and observed month since signup | Opening and closing MRR, tenure, movement and signed change |
| bridge / monthly_kpi | Month and channel | Revenue bridge, active base and normalized retention metrics |
| collections | Month and channel | Invoices, failures, recovered invoices and cash |
| cohorts | Signup month, channel and observable age | Original cohort size, active count and retained MRR |
| first_churn_risk | Channel and observable age | Risk set and first exits for product-limit survival |

**Build order.** The seeded generator creates the source facts. SQL turns changes into half-open effective intervals with LEAD, expands them against a calendar and uses LAG to calculate movement. Payment attempts aggregate to the invoice grain before joining. Python exports SQL results and embeds them in the standalone dashboard. Four CSVs in output/ are ready for Excel or Power BI.

## Metric contract

- Monetary database fields use integer **paise** (including the source field named mrr_cents). Divide by 100 for INR. CSV currency columns also use paise. Ratios in monthly_kpi.csv are decimals. Months are labeled by their first day.
- Opening MRR is the prior month's closing contracted run rate. Closing MRR equals opening plus new, expansion and win-back MRR minus contraction and churn. Losses in the bridge view are positive magnitudes.
- Monthly NRR is (opening + expansion − contraction − churn) / opening. GRR excludes expansion. Logo churn is customers lost / opening active customers. Zero denominators produce NULL. Aggregate amounts before dividing across channels.
- A signup starts at cohort age zero. Point retention counts a customer active at the specified age even after a gap. The denominator includes inactive customers. Future ages are unobserved and excluded. For pooled retention use total active / total eligible.
- First-churn survival multiplies one minus the first-exit rate at each age, conditional on remaining at risk. The dataset ends in October 2026, so later ages draw on fewer cohorts. Follow-up and mix can differ across ages.
- Twelve-month endpoint NRR freezes the opening set of active accounts and compares their revenue at both endpoints. It includes any win-backs among those same accounts.
- Collections are successful payments, measured within invoice month. MRR reflects the contracted run rate. Neither measure implements formal revenue-recognition accounting.

## Code map and verification

| File | Role |
|---|---|
| simulate.py | Fixed-seed source data and explicit simulation assumptions |
| sql/01_sources.sql | Source schema and constraints |
| sql/02_lifecycle.sql | Customer-month transformation |
| sql/03_marts.sql | Reporting views |
| sql/04_investigation.sql | Five reproducible business analyses |
| validate.py | Eight checks plus a six-month hand-calculated fixture |
| build.py | Build, validate, stage and replace outputs |
| dashboard.template.html | Dashboard rendering and interactions |

Every rebuild checks source integrity, lifecycle coverage, invoice coverage in both directions, retry integrity, cohort denominators, retention bounds and the MRR bridge. The hand-calculated case includes an expansion, a downgrade, a cancellation, an inactive month and a win-back. It verifies that a recovered invoice counts once and first-churn exposure stops at the original exit.

