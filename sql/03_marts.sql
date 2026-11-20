CREATE VIEW bridge AS
SELECT month, channel,
 SUM(opening) AS opening, SUM(closing) AS closing,
 SUM(CASE WHEN movement='new' THEN delta ELSE 0 END) AS new_mrr,
 SUM(CASE WHEN movement='reactivation' THEN delta ELSE 0 END) AS winback,
 SUM(CASE WHEN movement='expansion' THEN delta ELSE 0 END) AS expansion,
 SUM(CASE WHEN movement='contraction' THEN -delta ELSE 0 END) AS contraction,
 SUM(CASE WHEN movement='churn' THEN -delta ELSE 0 END) AS churn,
 SUM(opening>0) AS starting_logos, SUM(closing>0) AS ending_logos,
 SUM(movement='churn') AS lost_logos
FROM customer_month GROUP BY month,channel;

-- Collapse retries before joining invoices so billed amounts cannot multiply.
CREATE VIEW collections AS
WITH settled AS (
 SELECT invoice_id, MAX(CASE WHEN attempt=1 THEN collected END)=0 AS failed,
        SUM(collected) AS paid
 FROM payment_attempt GROUP BY invoice_id
)
SELECT i.month,a.channel,COUNT(*) AS invoices,SUM(i.amount) AS billed,
 SUM(s.paid) AS collected,SUM(s.failed) AS failed,
 SUM(s.failed AND s.paid>0) AS recovered,SUM(i.amount-s.paid) AS unpaid
FROM invoice i JOIN settled s ON i.id=s.invoice_id
JOIN account a ON a.id=i.account_id GROUP BY i.month,a.channel;

-- Point retention includes customers who left and later returned.
CREATE VIEW cohorts AS
SELECT joined,channel,age,month,COUNT(*) AS cohort_size,
 SUM(closing>0) AS active,SUM(closing) AS retained_mrr
FROM customer_month GROUP BY joined,channel,age,month;

-- Earliest cancellation is absorbing for survival, even if a customer returns.
-- Incomplete follow-up contributes only months actually observed.
CREATE VIEW first_churn_risk AS
WITH exposure AS (
 SELECT *, MIN(CASE WHEN movement='churn' THEN age END)
 OVER (PARTITION BY id) AS first_exit
 FROM customer_month
)
SELECT channel,age,COUNT(*) AS at_risk,SUM(first_exit IS age) AS first_churns
FROM exposure WHERE age>0 AND (first_exit IS NULL OR age<=first_exit)
GROUP BY channel,age;

CREATE VIEW monthly_kpi AS
SELECT *, 1.0*(opening-churn-contraction+expansion)/NULLIF(opening,0) AS nrr,
 1.0*(opening-churn-contraction)/NULLIF(opening,0) AS grr,
 1.0*lost_logos/NULLIF(starting_logos,0) AS logo_churn_rate
FROM bridge;
