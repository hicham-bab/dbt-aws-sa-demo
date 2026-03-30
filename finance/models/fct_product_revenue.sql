-- Finance product revenue model.
-- Revenue and return rates by product and category, by month.
-- Cross-project refs to platform.fct_orders and platform.dim_products.

with orders as (
    select * from {{ ref('aws_ecommerce', 'fct_orders') }}
),

order_items as (
    -- Note: stg_order_items is protected — we join via the public fct_orders grain.
    -- For line-item detail, finance uses fct_product_performance from the platform.
    select * from {{ ref('aws_ecommerce', 'fct_product_performance') }}
),

revenue_by_product as (
    select
        p.product_id,
        p.product_name,
        p.sku,
        p.category_name,
        p.list_price,
        p.total_orders,
        p.total_units_sold,
        p.total_revenue,
        p.avg_selling_price,
        -- Discount rate: how far below list price are we selling?
        case
            when p.list_price > 0
            then 1 - (p.avg_selling_price / p.list_price)
            else cast(0 as decimal(10,4))
        end                                                     as avg_discount_rate,
        -- Gross margin proxy (no cost data in demo — placeholder)
        p.total_revenue                                         as gross_revenue
    from order_items p
)

select * from revenue_by_product
