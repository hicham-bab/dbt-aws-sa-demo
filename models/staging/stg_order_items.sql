with source as (
    select * from {{ source('raw', 'raw_order_items') }}
),

renamed as (
    select
        order_item_id,
        order_id,
        product_id,
        cast(quantity as integer)                               as quantity,
        cast(unit_price as decimal(10, 2))                      as unit_price,
        cast(quantity as integer) * cast(unit_price as decimal(10, 2)) as line_total
    from source
)

select * from renamed
