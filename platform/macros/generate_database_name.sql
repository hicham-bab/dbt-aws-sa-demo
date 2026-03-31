{% macro generate_database_name(custom_database_name=none, node=none) -%}
    {#-
        Redshift does not support 3-part identifiers (database.schema.table)
        when referencing tables in the current database. Returning none causes
        dbt to generate schema.table references only, which Redshift requires.
    -#}
    {{ return(none) }}
{%- endmacro %}
