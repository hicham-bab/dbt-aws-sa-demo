-- Product performance fact. One row per product.
-- Summarises total units sold, revenue, and order count.

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select order_id, is_completed
    from {{ ref('stg_orders') }}
    where is_completed = true
),

products as (
    select * from {{ ref('dim_products') }}
),

item_sales as (
    select
        oi.product_id,
        count(distinct oi.order_id)                         as total_orders,
        sum(oi.quantity)                                    as total_units_sold,
        sum(oi.line_total)                                  as total_revenue,
        avg(oi.unit_price)                                  as avg_selling_price
    from order_items oi
    inner join orders o using (order_id)
    group by 1
)

select
    p.product_id,
    p.product_name,
    p.sku,
    p.category_name,
    p.list_price,
    p.is_active,
    coalesce(s.total_orders, 0)                             as total_orders,
    coalesce(s.total_units_sold, 0)                         as total_units_sold,
    coalesce(s.total_revenue, 0)                            as total_revenue,
    s.avg_selling_price
from products p
left join item_sales s using (product_id)
