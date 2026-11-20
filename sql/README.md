# SQL analysis

| File | What it does |
|---|---|
| `01_sources.sql` | Defines the customer, contract, invoice, and payment tables. |
| `02_lifecycle.sql` | Reconstructs each customer's monthly history and classifies upgrades, downgrades, churn, and win-backs. |
| `03_marts.sql` | Calculates recurring revenue, cohort retention, and payment recovery. |
| `04_investigation.sql` | Answers five business questions using the reporting tables. |

To explore the results, open `output/retention.sqlite` from the project root
and run a query from `04_investigation.sql`.
