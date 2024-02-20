{% macro transition_matrix(base_table_name, lookback_column, event_criteria, default_event_name = 'level') -%}
    with adaject_values as (select q.*,
                                   lag({{lookback_column}}, 1, {{lookback_column}})  over (partition by symbol order by date) as prev_{{lookback_column}}
                            from {{ ref(base_table_name) }} as q),

         events as (select symbol,
                           date,
                           -- subtract 1 for the last record
                           count(*) over (partition by symbol) - 1 as count_per_symbol,
                           case
                               {% for event, condition in event_criteria.items() %}
                                   when {{ condition }} then '{{ event }}'
                               {% endfor %}
                                   else '{{ default_event_name }}'
                           end as event
                    from adaject_values av),

         adaject_events as (select lag(event) over (partition by symbol order by date)  as prev_event,
                                   lead(event) over (partition by symbol order by date) as next_event,
                                   e.*
                            from events e),

         event_tuple_cnt as
             (select count(*) over (partition by symbol, event, next_event)::float8  as count_per_event_tuple,
                     count(*) over (partition by symbol, event)::float8   as count_per_event,
                     -- start and end should never be part of the transitions
                     -- the coalesce is there to ease debugging if these occur in a tuple
                     coalesce(event, 'start')as event,
                     coalesce(next_event, 'end') as next_event,
                     count_per_symbol,
                     symbol
              from adaject_events ae
              where next_event is not null)

    select distinct symbol,
                    event,
                    next_event,
                    count_per_event_tuple / count_per_symbol as tuple_p,
                    count_per_event_tuple / count_per_event as transition_p
    from event_tuple_cnt etc
    order by symbol, event, next_event
{% endmacro -%}