-- Order fact table. One row per order.
-- Enriched with customer geography and order-level revenue.

with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

customers as (
    select * from {{ ref('dim_customers') }}
)

select
    o.order_id,
    o.customer_id,
    c.full_name                                             as customer_name,
    c.company,
    c.aws_region,
    c.region_name,
    c.geography,
    c.customer_tier,
    o.status,
    o.is_completed,
    o.created_at                                            as order_date,
    o.order_month,
    o.item_count,
    o.total_units,
    o.order_revenue
from orders o
left join customers c using (customer_id)
