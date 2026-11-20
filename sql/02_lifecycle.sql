-- Turn sparse contract changes into a complete spine from signup through cutoff.
-- The zero-MRR spans retain inactive months and prevent a win-back looking new.
CREATE TABLE customer_month AS
WITH intervals AS (
 SELECT account_id, month AS valid_from,
        LEAD(month) OVER (PARTITION BY account_id ORDER BY month) AS valid_to,
        mrr_cents AS closing
 FROM contract_event
), spine AS (
 SELECT a.id, a.channel, a.joined, c.month, c.seq-j.seq AS age,
        i.closing
 FROM intervals i JOIN account a ON a.id=i.account_id
 JOIN calendar j ON j.month=a.joined
 JOIN calendar c ON c.month>=i.valid_from AND (c.month<i.valid_to OR i.valid_to IS NULL)
), lagged AS (
 SELECT *, LAG(closing,1,0) OVER (PARTITION BY id ORDER BY month) AS opening
 FROM spine
)
SELECT *, closing-opening AS delta,
 CASE WHEN age=0 THEN 'new'
      WHEN opening=0 AND closing>0 THEN 'reactivation'
      WHEN opening>0 AND closing=0 THEN 'churn'
      WHEN closing>opening THEN 'expansion'
      WHEN closing<opening THEN 'contraction'
      WHEN closing>0 THEN 'renewal' ELSE 'inactive' END AS movement
FROM lagged;
CREATE UNIQUE INDEX customer_month_pk ON customer_month(id,month);
CREATE INDEX customer_month_period ON customer_month(month,channel);
