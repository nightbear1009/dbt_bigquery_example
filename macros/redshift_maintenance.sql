{% macro get_vacuumable_tables() %}
    {#- -- find max column width from https://docs.aws.amazon.com/redshift/latest/dg/vacuum-column-limit-exceeded-error.html -#}
    {% set vacuumable_tables_sql %}
        select
            '"' || table_schema || '"."' || table_name || '"' as table_name
        from information_schema.tables
        order by table_schema, table_name
        -- limit 2
    {% endset %}
    {% set vacuumable_tables=run_query(vacuumable_tables_sql) %}
    {{ return(vacuumable_tables.columns[0].values()) }}


{% endmacro %}

{% macro redshift_maintenance() %}

    {% for table in get_vacuumable_tables() %}
        {% set message_prefix=loop.index ~ " of " ~ loop.length %}
        {{ dbt_utils.log_info(message_prefix ~ " Vacuuming " ~ table) }}
        {% set results=run_query("vacuum " ~ table) %}
        {{ dbt_utils.log_info(message_prefix ~ " Analyzing " ~ table) }}
        {% do run_query("analyze " ~ table) %}
        {{ dbt_utils.log_info(message_prefix ~ " Finished " ~ table) }}
    {% endfor %}


{% endmacro %}
