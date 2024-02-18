with calc_olhc4 as (select q.*,
                           (open + high + low + close) / 4 as olhc4
                    from raw.historical_1d_quotes_cleansed q
                    where date > '01.01.2023'),
     adaject_values as (select o.*,
                               lag(olhc4, 1, olhc4) over (partition by symbol order by date) as prev_olhc4,
                               lead(open, 1, open) over (partition by symbol order by date)  as next_open
                        from calc_olhc4 o
                        where date > '01.01.2023'),
     events as (select symbol,
                       date,
                       -- subtract 1 for the last record
                       count(*) over (partition by symbol) - 1 as total_per_symbol,
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
         (select count(*) over (partition by symbol, event, next_event)  as count_per_event_tuple,
                 -- start and end should never be part of the transitions
                 -- the coalesce is there to ease debugging if these occur in a tuple
                 coalesce(event, 'start') || coalesce(next_event, 'end') as event_tuple,
                 ae.*
          from adaject_events ae
          where next_event is not null)

select distinct symbol,
                event_tuple,
                count_per_event_tuple::float8 / total_per_symbol::float8 as tuple_p
from event_tuple_cnt etc
order by symbol, tuple_p desc;