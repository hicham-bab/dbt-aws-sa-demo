{{
    config(
        materialized   = 'table',
        table_type     = 'iceberg',
        partitioned_by = ['customer_tier']
    )
}}

-- Open-format mirror of fct_customer_lifetime_value, written as Apache Iceberg on S3
-- via Redshift's native Iceberg support (dbt-redshift >= 1.6).
--
-- NOTE: Fusion (dbt1060) warns on table_type/partitioned_by because its
-- config schema for dbt-redshift doesn't yet include Iceberg keys.
-- These warnings are false positives — the config is valid at runtime.
--
--
-- Partitioned by customer_tier so SageMaker and Bedrock can efficiently
-- pull champion / loyal / potential / new cohorts without full table scans.
--
-- Key AI use cases for this Iceberg table:
--   SageMaker:   churn prediction training data (filtered by tier, time travel for labels)
--   Bedrock:     "Who are our top customers by LTV?" — Knowledge Base source
--   Athena:      ad-hoc customer analytics, pay-per-query
--   Spark/EMR:   large-scale feature engineering pipelines
--
-- ICEBERG ADVANTAGE HERE: time travel
--   SELECT * FROM fct_customer_lifetime_value_iceberg
--   FOR SYSTEM_TIME AS OF TIMESTAMP '2025-01-01 00:00:00'
--   WHERE ltv_segment = 'champion'
-- → Reproduces the exact champion cohort used for any historical ML training run.
--   No data warehouse snapshot needed. Built into the open format.

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
        case
            when co.last_order_at >= dateadd('day', -90, current_date)
            then co.total_revenue * 1.2
            else co.total_revenue
        end                                                         as ltv_score,
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
