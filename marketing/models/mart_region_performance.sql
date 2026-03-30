-- Marketing regional performance model.
-- Aggregates customer acquisition, revenue, and segment distribution by AWS geography.
-- Cross-project ref to platform.fct_revenue_by_region and platform.dim_customers.

with revenue as (
    select * from {{ ref('aws_ecommerce', 'fct_revenue_by_region') }}
),

customers as (
    select
        geography,
        customer_tier,
        count(customer_id)                                      as total_customers
    from {{ ref('aws_ecommerce', 'dim_customers') }}
    group by 1, 2
),

geography_totals as (
    select
        geography,
        sum(total_customers)                                    as total_customers
    from customers
    group by 1
),

regional as (
    select
        r.order_month,
        r.geography,
        r.total_orders,
        r.total_revenue,
        r.avg_order_value,
        r.unique_customers                                      as active_customers,
        gt.total_customers                                      as total_registered_customers,
        -- Activation rate: % of registered customers who ordered this month
        cast(r.unique_customers as decimal(10,2))
            / nullif(cast(gt.total_customers as decimal(10,2)), 0) as activation_rate
    from revenue r
    left join geography_totals gt using (geography)
)

select * from regional
