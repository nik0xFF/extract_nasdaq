create sequence landing.lid_historical_1_quotes start 1;
create table landing.historical_1d_quotes
(
    landing_id bigint primary key default nextval('landing.lid_historical_1_quotes'),
    raw_data jsonb not null,
    _landing_timestamp timestamp default current_timestamp,
    _hash varchar not null,
    _run_id bigint not null references meta.pipeline_runs
);

create or replace function landing.set_landing_table_metadata_columns()
returns trigger
language plpgsql
    as
$$
    begin
        NEW._hash = md5(NEW.raw_data::text);
        NEW._run_id = meta.get_current_run_id(TG_TABLE_NAME::regclass::text);
        return NEW;
    end;
$$;

create trigger trg_metadata_historical_1d_quotes_bi
    before insert on landing.historical_1d_quotes
    for each row execute function landing.set_landing_table_metadata_columns();
