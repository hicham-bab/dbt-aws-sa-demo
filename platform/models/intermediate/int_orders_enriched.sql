-- Joins orders with their line items to produce order-level revenue totals.
-- One row per order.

with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

order_totals as (
    select
        order_id,
        count(order_item_id)            as item_count,
        sum(quantity)                   as total_units,
        sum(line_total)                 as order_revenue
    from order_items
    group by 1
),

enriched as (
    select
        o.order_id,
        o.customer_id,
        o.status,
        o.is_completed,
        o.created_at,
        o.updated_at,
        o.order_month,
        ot.item_count,
        ot.total_units,
        ot.order_revenue
    from orders o
    left join order_totals ot using (order_id)
)

select * from enriched
