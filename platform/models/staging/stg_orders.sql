with source as (
    select * from {{ source('raw', 'raw_orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        lower(status)                                           as status,
        cast(created_at as timestamp)                           as created_at,
        cast(updated_at as timestamp)                           as updated_at,
        -- derived fields
        case
            when lower(status) = 'completed'  then true
            else false
        end                                                     as is_completed,
        date_trunc('month', cast(created_at as timestamp))      as order_month
    from source
)

select * from renamed
