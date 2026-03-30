-- Revenue aggregated by AWS geography and month.
-- Primary source for the Bedrock text-to-SQL demo:
--   "What was total revenue from EMEA customers in Q1 2025?"

with orders as (
    select * from {{ ref('fct_orders') }}
    where is_completed = true
)

select
    order_month,
    geography,
    aws_region,
    region_name,
    count(distinct customer_id)                             as unique_customers,
    count(order_id)                                         as total_orders,
    sum(order_revenue)                                      as total_revenue,
    avg(order_revenue)                                      as avg_order_value,
    sum(order_revenue) / nullif(count(distinct customer_id), 0) as revenue_per_customer
from orders
group by 1, 2, 3, 4
