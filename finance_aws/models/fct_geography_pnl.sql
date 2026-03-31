-- Finance geography P&L model.
-- Monthly revenue summary by AWS geography for CFO/regional P&L reporting.
-- This is the finance team's view on top of the platform's fct_revenue_by_region.
-- Adds quarter, YTD revenue, and MoM growth.

with regional as (
    select * from {{ ref('aws_ecommerce', 'fct_revenue_by_region') }}
),

with_growth as (
    select
        order_month,
        geography,
        aws_region,
        region_name,
        total_orders,
        total_revenue,
        avg_order_value,
        unique_customers,
        -- Quarter label for period reporting
        'Q' || cast(extract(quarter from order_month) as varchar)
            || ' ' || cast(extract(year from order_month) as varchar) as fiscal_quarter,
        -- Month-over-month revenue growth (LAG window function)
        lag(total_revenue) over (
            partition by geography, aws_region
            order by order_month
        )                                                           as prev_month_revenue,
        case
            when lag(total_revenue) over (
                    partition by geography, aws_region
                    order by order_month
                 ) > 0
            then (total_revenue
                  - lag(total_revenue) over (
                        partition by geography, aws_region
                        order by order_month
                    ))
                 / lag(total_revenue) over (
                       partition by geography, aws_region
                       order by order_month
                   )
            else null
        end                                                         as mom_growth_rate
    from regional
)

select * from with_growth
