-- Finance revenue recognition model.
-- One row per order. Adds recognised_revenue (completed orders only) and
-- returned_amount fields for P&L reporting.
--
-- Cross-project ref to platform.fct_orders — the canonical order grain.
-- Finance owns the revenue recognition rules; platform owns the order fact.

with orders as (
    -- Cross-project ref: reads the public contract from aws_ecommerce platform
    select * from {{ ref('aws_ecommerce', 'fct_orders') }}
)

select
    order_id,
    customer_id,
    customer_name,
    company,
    aws_region,
    region_name,
    geography,
    customer_tier,
    status,
    order_date,
    order_month,
    order_revenue,
    -- Revenue recognition: only completed orders count as recognised revenue
    case
        when status = 'completed'   then order_revenue
        else                             cast(0 as decimal(12,2))
    end                                                         as recognised_revenue,
    -- Returns: record the value of returned orders for reconciliation
    case
        when status = 'returned'    then order_revenue
        else                             cast(0 as decimal(12,2))
    end                                                         as returned_amount,
    -- Finance period (same as order_month — used for period close queries)
    order_month                                                 as finance_period
from orders
