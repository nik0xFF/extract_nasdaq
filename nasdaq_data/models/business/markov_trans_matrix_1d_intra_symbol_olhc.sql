with adaject_values as (select o.*,
                               lag(olhc4, 1, olhc4) over (partition by symbol order by date) as prev_olhc4
                        from {{ ref('hist_1d_lin_reg_moving_14d') }} as o),
     events as (select symbol,
                       date,
                       -- subtract 1 for the last record
                       count(*) over (partition by symbol) - 1 as count_per_symbol,
                       case
                           when olhc4 > prev_olhc4 then 'up'
                           when olhc4 < prev_olhc4 then 'down'
                           else 'level' end                    as event
                from adaject_values av),

     adaject_events as (select lag(event) over (partition by symbol order by date)  as prev_event,
                               lead(event) over (partition by symbol order by date) as next_event,
                               e.*
                        from events e),

     event_tuple_cnt as
         (select count(*) over (partition by symbol, event, next_event)::float8 as count_per_event_tuple,
                 count(*) over (partition by symbol, event)::float8             as count_per_event,
                 -- start and end should never be part of the transitions
                 -- the coalesce is there to ease debugging if these occur in a tuple
                 coalesce(event, 'start')                                       as event,
                 coalesce(next_event, 'end')                                    as next_event,
                 count_per_symbol,
                 symbol
          from adaject_events ae
          where next_event is not null)

select distinct symbol,
                event,
                next_event,
                count_per_event_tuple / count_per_symbol as tuple_p,
                count_per_event_tuple / count_per_event  as transition_p
from event_tuple_cnt etc
order by symbol, event, next_event