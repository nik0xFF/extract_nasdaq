with adaject_values as (select q.*,
                               lag(close, 0, close)  over (partition by symbol order by date) as prev_close,
                               lead(open, 0, open) over (partition by symbol order by date) as next_open
                        from {{ref('historical_1d_quotes_cleansed')}} q),

     events as (select symbol,
                       date,
                       -- subtract 1 for the last record
                       count(*) over (partition by symbol) - 1 as total_per_symbol,
                       case
                           when open > prev_close then 'up'
                           when open < prev_close then 'down'
                           else 'level' end                as event
                from adaject_values av),

     adaject_events as (select lag(event) over (partition by symbol order by date)  as prev_event,
                               lead(event) over (partition by symbol order by date) as next_event,
                               e.*
                        from events e),

     event_tuple_cnt as
         (select count(*) over (partition by symbol, event, next_event) as count_per_event_tuple,
                 coalesce(event, 'start') || coalesce(next_event,'end')                                    as event_tuple,
                 ae.*
          from adaject_events ae
          where next_event is not null)

select distinct symbol,
                event_tuple,
                count_per_event_tuple::float8 / total_per_symbol::float8 as tuple_p
from event_tuple_cnt etc
order by symbol