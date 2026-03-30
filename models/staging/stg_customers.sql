with source as (
    select * from {{ source('raw', 'raw_customers') }}
),

renamed as (
    select
        customer_id,
        first_name,
        last_name,
        first_name || ' ' || last_name                          as full_name,
        lower(email)                                            as email,
        company,
        country,
        aws_region,
        lower(customer_tier)                                    as customer_tier,
        cast(created_at as timestamp)                           as created_at
    from source
)

select * from renamed
