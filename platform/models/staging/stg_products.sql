with source as (
    select * from {{ source('raw', 'raw_products') }}
),

renamed as (
    select
        product_id,
        name                                                    as product_name,
        category_id,
        cast(price as decimal(10, 2))                           as list_price,
        sku,
        is_active
    from source
)

select * from renamed
