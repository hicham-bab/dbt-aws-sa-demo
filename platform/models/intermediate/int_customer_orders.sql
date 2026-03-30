-- Aggregates completed order history per customer.
-- One row per customer — used as input to the CLV mart model.

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('int_orders_enriched') }}
    where is_completed = true
),

customer_orders as (
    select
        customer_id,
        count(order_id)                                             as total_orders,
        sum(order_revenue)                                          as total_revenue,
        min(created_at)                                             as first_order_at,
        max(created_at)                                             as last_order_at,
        avg(order_revenue)                                          as avg_order_value,
        -- days between first and last order (tenure)
        datediff('day', min(created_at), max(created_at))          as order_tenure_days
    from orders
    group by 1
),

joined as (
    select
        c.customer_id,
        c.full_name,
        c.email,
        c.company,
        c.country,
        c.aws_region,
        c.customer_tier,
        c.created_at                                                as customer_since,
        coalesce(co.total_orders, 0)                                as total_orders,
        coalesce(co.total_revenue, 0)                               as total_revenue,
        co.first_order_at,
        co.last_order_at,
        coalesce(co.avg_order_value, 0)                             as avg_order_value,
        coalesce(co.order_tenure_days, 0)                           as order_tenure_days
    from customers c
    left join customer_orders co using (customer_id)
)

select * from joined
