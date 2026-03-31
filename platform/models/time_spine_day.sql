{{
    config(
        materialized = 'table',
        schema = 'metrics'
    )
}}

-- Time spine required by MetricFlow for the dbt Semantic Layer.
-- Provides one row per calendar day for all time-based metric aggregations:
--   - revenue_ytd (grain_to_date: year)
--   - revenue_trailing_3m (window: 3 months)
--   - revenue_mom_growth (offset_window: 1 month)
--
-- Consumed by: Amazon Bedrock AgentCore, QuickSight Q, Kiro dbt MCP Server.

with base_dates as (
    {{
        dbt.date_spine(
            'day',
            "cast('2020-01-01' as date)",
            "cast('2029-01-01' as date)"
        )
    }}
),

final as (
    select cast(date_day as date) as date_day
    from base_dates
)

select * from final
where date_day > dateadd('year', -5, current_date)
  and date_day < dateadd('year',  3, current_date)
