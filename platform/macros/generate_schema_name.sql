{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
        Use the configured schema name directly without adding a dev prefix.
        This ensures seeds, models, and source references all use the same
        schema names (raw / staging / intermediate / marts) regardless of
        the dbt Cloud user or target, which is required for this shared
        demo environment.
    -#}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
