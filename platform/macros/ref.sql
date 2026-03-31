{% macro ref(model_name, version=none) %}
  {#-
      Redshift does not support 3-part identifiers (database.schema.table)
      when querying tables in the current database. Strip the database so
      dbt renders schema.table references only in compiled SQL.
  -#}
  {%- set rel = builtins.ref(model_name, version=version) -%}
  {{ return(rel.include(database=False)) }}
{% endmacro %}
