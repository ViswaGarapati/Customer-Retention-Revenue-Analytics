# Acquisition hid a small decline in recurring revenue from existing customers

**Decision brief · October 2026 · Simulated INR subscription business**

October closed with 2,908 active customers and ₹41,98,420 in monthly recurring revenue (MRR), up ₹1,96,290 or 4.90%. An executive looking only at this growth would miss that the customers active at the start of the month contributed ₹28,160 less recurring revenue by month end.

| October movement | Change in monthly INR |
|---|---:|
| Opening MRR | 40,02,130 |
| New subscriptions | +1,73,780 |
| Reactivations | +50,670 |
| Expansion | +1,14,000 |
| Contraction | −28,000 |
| Churn | −1,14,160 |
| Closing MRR | 41,98,420 |

Expansion almost covered cancellations. Downgrades explain most of the remaining shortfall. Net revenue retention was 99.30%, with gross revenue retention at 96.45%. If the opening base and losses had stayed fixed, another ₹28,160 in expansion or avoided losses would have brought monthly NRR to 100%.

## Where would you investigate first?

| Acquisition channel | Active at month six / eligible | Month-six point retention | 12-month endpoint NRR* |
|---|---:|---:|---:|
| Partner | 728 / 835 | 87.19% | 113.59% |
| Organic | 1,210 / 1,493 | 81.04% | 92.01% |
| Paid search | 688 / 970 | 70.93% | 76.51% |

*The endpoint comparison follows accounts active in October 2025 through October 2026. Month-six retention pools all signup cohorts old enough to reach six months. These columns use different populations.*

Paid-search customers showed a 16.26 percentage-point retention gap versus partner customers at month six. A focused next experiment would randomize new paid-search accounts between standard onboarding and an assisted first-month setup. Predefine month-six active status as the primary outcome and support cost per assigned account as a guardrail. Channel acquisition costs, margins and customer mix would be needed before making a budget allocation decision.

## What did billing contribute?

Across 50,811 invoices, 2,781 initial charges failed. A retry recovered 1,869 invoices (67.21%) worth ₹25,02,310. The remaining 912 invoices represented ₹12,49,880 in unpaid bills. A failed charge does not automatically cancel a contract in this simulation. That distinction lets finance reconcile collections while the subscription team measures contracted MRR.

## What can this case establish?

The channel-specific churn probabilities and payment failure rates are inputs to the simulator. The findings demonstrate how to detect and quantify those differences. Estimating the effect of onboarding, retry timing or acquisition channel would require additional data and a suitable comparison group. The simulation includes one monthly contract per customer, full-month billing and at most one retry. It omits taxes, refunds, partial settlements, annual contracts and acquisition costs.

Run `python3 investigate.py` to reproduce the revenue bridge, cohort comparison, survival estimates, retry breakdown and endpoint NRR. The value collected on retries is `SELECT SUM(collected)/100 FROM payment_attempt WHERE attempt=2`.
