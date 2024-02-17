{%- call statement('create_hist_1d_quotes_t', fetch_result=False) -%}
    do
    $$
        begin
            if not exists (select *
                           from pg_type typ
                                    inner join pg_namespace nsp
                                               on nsp.oid = typ.typnamespace
                           where nsp.nspname ='raw'
                             and typ.typname = 'hist_1d_quotes_t') then
                create type raw.hist_1d_quotes_t as
                (
                    date   timestamp,
                    close  text,
                    volume text,
                    open   text,
                    high   text,
                    low    text
                );
            end if;
        end;
    $$
    language plpgsql;
{%- endcall -%}

with flattened as (
    select raw_data::json -> 'data' -> 'symbol' as symbol,
           json_populate_record(null::raw.hist_1d_quotes_t, json_array_elements(raw_data::json -> 'data' -> 'tradesTable' -> 'rows')) as row
    from staging.historical_1d_quotes
)
select symbol,
       (row).date,
       (row).open,
       (row).high,
       (row).low,
       (row).close,
       (row).volume
from flattened