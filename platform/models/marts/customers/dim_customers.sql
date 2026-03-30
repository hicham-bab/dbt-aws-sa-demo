-- Customer dimension table. One row per customer.
-- Joins customer attributes with their AWS region geography.

with customers as (
    select * from {{ ref('stg_customers') }}
),

regions as (
    select * from {{ ref('stg_aws_regions') }}
)

select
    c.customer_id,
    c.full_name,
    c.email,
    c.company,
    c.country,
    c.aws_region,
    r.region_name,
    r.geography,
    c.customer_tier,
    c.created_at                                        as customer_since
from customers c
left join regions r on c.aws_region = r.region_code
