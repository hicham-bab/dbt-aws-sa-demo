-- Customer Lifetime Value fact table.
-- One row per customer. The primary mart queried by Amazon Bedrock agents
-- to answer revenue and CLV questions.

with customer_orders as (
    select * from {{ ref('int_customer_orders') }}
),

regions as (
    select * from {{ ref('stg_aws_regions') }}
),

clv as (
    select
        co.customer_id,
        co.full_name,
        co.email,
        co.company,
        co.country,
        co.aws_region,
        r.region_name,
        r.geography,
        co.customer_tier,
        co.customer_since,
        co.total_orders,
        co.total_revenue,
        co.avg_order_value,
        co.first_order_at,
        co.last_order_at,
        co.order_tenure_days,
        -- Simple LTV score: revenue weighted by recency (recency bonus if ordered in last 90 days)
        case
            when co.last_order_at >= dateadd('day', -90, current_date)
            then co.total_revenue * 1.2
            else co.total_revenue
        end                                                         as ltv_score,
        -- Segment based on total revenue
        case
            when co.total_revenue >= 10000  then 'champion'
            when co.total_revenue >= 3000   then 'loyal'
            when co.total_revenue >= 500    then 'potential'
            else                                 'new'
        end                                                         as ltv_segment
    from customer_orders co
    left join regions r on co.aws_region = r.region_code
)

select * from clv
