{{
    config(
        materialized   = 'table',
        table_type     = 'iceberg',
        partitioned_by = ['geography', 'month(order_date)']
    )
}}

-- Open-format mirror of fct_orders, written as an Apache Iceberg table on S3
-- via Redshift's native Iceberg support (dbt-redshift >= 1.6).
--
-- NOTE: Fusion (dbt1060) warns on table_type/partitioned_by because its
-- config schema for dbt-redshift doesn't yet include Iceberg keys.
-- These warnings are false positives — the config is valid at runtime.
-- Track: https://github.com/dbt-labs/dbt-redshift/issues
--
-- DEMO TALKING POINT:
-- Same Redshift connection. Same dbt project. One config change.
-- Output is open Iceberg on S3 — readable by Athena, Spark/EMR,
-- SageMaker, Redshift Spectrum, and any Iceberg-compatible engine.
-- No separate query engine, no extra profile, no data copy.
--
-- Who reads this table:
--   - Amazon Athena         (ad-hoc SQL, pay-per-query)
--   - Amazon Redshift Spectrum (federated query from Redshift)
--   - Amazon SageMaker      (training data, feature store ingestion)
--   - Amazon Bedrock        (Knowledge Base source, text-to-SQL)
--   - Apache Spark on EMR   (large-scale batch processing)
--   - Any Iceberg-compatible engine (Flink, Trino, Snowflake external table)
--
-- Partitioned by geography + month so AI query engines scan only the data
-- they need — critical for cost control on pay-per-query services like Athena.

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
