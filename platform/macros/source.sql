{% macro source(source_name, table_name) %}
  {#-
      Redshift does not support 3-part identifiers (database.schema.table)
      when querying tables in the current database. Strip the database so
      dbt renders schema.table references only in compiled SQL.
  -#}
  {%- set rel = builtins.source(source_name, table_name) -%}
  {{ return(rel.include(database=False)) }}
{% endmacro %}
