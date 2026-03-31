-- Marketing customer segmentation model.
-- Consumes platform.fct_customer_lifetime_value and platform.fct_orders
-- via cross-project ref() — the dbt Mesh contract in action.
--
-- Adds recency-based marketing segments on top of the platform CLV data.
-- The platform team owns the CLV definition; marketing owns the segment logic.

with clv as (
    -- Cross-project ref: reads the public contract from aws_ecommerce platform
    select * from {{ ref('aws_ecommerce', 'fct_customer_lifetime_value') }}
),

recent_orders as (
    select
        customer_id,
        max(order_date)                                         as last_order_date,
        count(order_id)                                         as orders_last_90d
    from {{ ref('aws_ecommerce', 'fct_orders') }}
    where is_completed = true
      and order_date >= dateadd('day', -90, current_date)
    group by 1
),

segmented as (
    select
        c.customer_id,
        c.full_name,
        c.email,
        c.company,
        c.aws_region,
        c.region_name,
        c.geography,
        c.customer_tier,
        c.total_orders,
        c.total_revenue,
        c.ltv_segment,
        r.last_order_date,
        coalesce(r.orders_last_90d, 0)                          as orders_last_90d,
        -- Marketing engagement segment (recency + value)
        case
            when c.ltv_segment = 'champion'
             and coalesce(r.orders_last_90d, 0) > 0             then 'champion'
            when c.ltv_segment in ('champion', 'loyal')
             and coalesce(r.orders_last_90d, 0) > 0             then 'loyal'
            when c.ltv_segment in ('champion', 'loyal')
             and coalesce(r.orders_last_90d, 0) = 0             then 'at_risk'
            when c.ltv_segment = 'potential'                    then 'potential'
            when c.total_orders = 0                             then 'never_purchased'
            else                                                     'lapsed'
        end                                                     as marketing_segment,
        -- Campaign eligibility flags
        case when coalesce(r.orders_last_90d, 0) = 0
              and c.total_revenue > 0                           then true
             else false
        end                                                     as is_winback_candidate,
        case when c.ltv_segment = 'potential'
              and c.total_orders >= 2                           then true
             else false
        end                                                     as is_upsell_candidate
    from clv c
    left join recent_orders r using (customer_id)
)

select * from segmented
