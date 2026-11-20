-- 1. Reconcile the latest month across channels. Weight ratios by the opening base.
SELECT month, sum(opening)/100.0 AS opening_inr, sum(closing)/100.0 AS closing_inr,
 sum(new_mrr)/100 AS new_inr,sum(expansion)/100 AS expansion_inr,
 sum(winback)/100 AS winback_inr,sum(contraction)/100 AS contraction_inr,
 sum(churn)/100 AS churn_inr, sum(ending_logos) AS active_accounts,
 round(100.0*sum(opening-churn-contraction+expansion)/sum(opening),2) AS nrr_pct,
 round(100.0*sum(opening-churn-contraction)/sum(opening),2) AS grr_pct
FROM bridge WHERE month=(SELECT max(month) FROM calendar) GROUP BY month;

-- 2. Only compare cohorts that have reached their sixth renewal.
SELECT channel,sum(cohort_size) AS eligible, sum(active) AS still_active,
 round(100.0*sum(active)/sum(cohort_size),2) AS m6_point_retention_pct
FROM cohorts WHERE age=6 GROUP BY channel ORDER BY m6_point_retention_pct DESC;

-- 3. Product-limit survival through first churn. Age-specific risk sets exclude
-- earlier exits and customers without enough observable follow-up.
WITH RECURSIVE survival(channel,age,probability) AS (
 SELECT DISTINCT channel,0,1.0 FROM account
 UNION ALL
 SELECT s.channel,r.age,s.probability*(1.0-1.0*r.first_churns/r.at_risk)
 FROM survival s JOIN first_churn_risk r ON r.channel=s.channel AND r.age=s.age+1
)
SELECT channel,age,round(100*probability,2) AS uninterrupted_survival_pct
FROM survival WHERE age IN (3,6,12) ORDER BY channel,age;

-- 4. Separate acquired revenue from cash actually recovered on retry.
SELECT channel,sum(failed) AS initial_failures,sum(recovered) AS recoveries,
 round(100.0*sum(recovered)/sum(failed),2) AS recovery_pct,sum(unpaid)/100 AS unpaid_inr
FROM collections GROUP BY channel ORDER BY unpaid_inr DESC;

-- 5. Endpoint NRR for customers active 12 months earlier (includes their win-backs).
-- A one-year endpoint ratio answers a different question from multiplying monthly NRR.
WITH anchor AS (SELECT max(month) AS finish,date(max(month),'-12 months') AS start FROM calendar)
SELECT b.channel,count(*) AS opening_customers,sum(b.closing)/100 AS opening_inr,
 sum(e.closing)/100 AS endpoint_inr, round(100.0*sum(e.closing)/sum(b.closing),2) AS endpoint_nrr_pct
FROM anchor JOIN customer_month b ON b.month=anchor.start AND b.closing>0
JOIN customer_month e ON e.id=b.id AND e.month=anchor.finish GROUP BY b.channel;
