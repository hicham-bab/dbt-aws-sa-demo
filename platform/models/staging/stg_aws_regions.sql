-- Staging model for the aws_regions reference table.
-- This model was created by the dbt MCP + Kiro agent skill demo in Scene 3.
-- The agent read stg_customers.sql to learn our naming conventions,
-- then generated this model with the correct source() macro and column docs.

with source as (
    select * from {{ source('raw', 'aws_regions') }}
),

renamed as (
    select
        region_code,
        region_name,
        upper(geography)                                        as geography,
        primary_az
    from source
)

select * from renamed
