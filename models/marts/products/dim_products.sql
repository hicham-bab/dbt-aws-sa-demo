-- Product dimension. One row per product, enriched with category name.

with products as (
    select * from {{ ref('stg_products') }}
),

categories as (
    select * from {{ source('raw', 'raw_product_categories') }}
)

select
    p.product_id,
    p.product_name,
    p.sku,
    p.category_id,
    c.name                                                  as category_name,
    p.list_price,
    p.is_active
from products p
left join categories c using (category_id)
