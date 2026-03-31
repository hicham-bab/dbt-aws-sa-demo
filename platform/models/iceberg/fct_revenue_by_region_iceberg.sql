{{
    config(
        materialized   = 'table',
        table_type     = 'iceberg',
        partitioned_by = ['geography'],
        s3_data_location = 's3://{{ var("iceberg_bucket") }}/iceberg/fct_revenue_by_region/'
    )
}}

-- Open-format mirror of fct_revenue_by_region, written as Apache Iceberg on S3.
--
-- This is the primary table for the demo query:
--   "What was total revenue from EMEA customers in Q1 2025?" → $68,299.60
--
-- By writing this to Iceberg, the same answer is available to:
--   - dbt Semantic Layer (Redshift path) — governed metric: total_revenue
--   - Amazon Athena (open lakehouse path) — direct Iceberg scan, pay-per-query
--   - Amazon Bedrock (Knowledge Base or text-to-SQL agent)
--   - SageMaker Feature Store (regional revenue feature for ML models)
--
-- DEMO TALKING POINT:
-- "Same SQL. Same tests. Same lineage. Different storage format.
--  Your Redshift customers get a table. Your lakehouse customers get Iceberg.
--  dbt governs both."

with orders as (
    select * from {{ ref('fct_orders') }}
    where is_completed = true
)

select
    order_month,
    geography,
    aws_region,
    region_name,
    count(distinct customer_id)                                     as unique_customers,
    count(order_id)                                                 as total_orders,
    sum(order_revenue)                                              as total_revenue,
    avg(order_revenue)                                              as avg_order_value,
    sum(order_revenue) / nullif(count(distinct customer_id), 0)    as revenue_per_customer
from orders
group by 1, 2, 3, 4
