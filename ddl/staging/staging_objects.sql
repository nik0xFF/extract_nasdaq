
create sequence staging.seq_sid_historical_1_quotes start 1;
create table staging.historical_1d_quotes
(
    staging_id         bigint primary key default nextval('staging.seq_sid_historical_1_quotes'),
    raw_data           jsonb   not null,
    _landing_id        bigint,
    _staging_timestamp timestamp          default current_timestamp,
    _landing_timestamp timestamp,
    _hash              varchar not null,
    _run_id            bigint  not null references meta.pipeline_runs
);

drop table staging.processed;
create table staging.processed
(
    hash             varchar   not null primary key,
    base_object_name varchar not null ,
    landing_id       bigint    not null,
    run_id           bigint    not null
);


create or replace function staging.get_new_landing_records(p_object_basename varchar)
    returns table
            (
                raw_data           jsonb,
                _landing_id        bigint,
                _landing_timestamp timestamp,
                _hash              varchar,
                _run_id            bigint
            )
    language plpgsql
as
$$
declare
    v_stmt varchar =
        'select  x.raw_data, x.landing_id, x._landing_timestamp, x._hash, x._run_id
        from (
            with processed_hashes as (
                select hash from staging.processed
                where base_object_name = '|| quote_literal(p_object_basename) ||'
            )
            select src.*,
                   row_number() over (partition by _hash order by _hash) as rn
            from landing.'|| p_object_basename ||' src
            left join processed_hashes ph on ph.hash = src._hash
            where ph is null
            ) x
        where x.rn = 1;';
begin
    return query execute v_stmt;
end;
$$;


create or replace function staging.landing_to_staging(p_object_basename varchar)
    returns bigint
    language plpgsql
as
$$
declare
    v_truncate_stmt varchar = 'truncate table staging.' || p_object_basename;
    v_insert_landing_data_stmt varchar =
        'insert into staging.'|| p_object_basename || ' (raw_data, _landing_id, _landing_timestamp, _hash, _run_id)
        select raw_data, _landing_id, _landing_timestamp, _hash, _run_id
        from staging.get_new_landing_records(' || quote_literal(p_object_basename) || ');';
    v_insert_hashes_stmt varchar =
        'insert into staging.processed (hash, base_object_name, landing_id, run_id)
        select  _hash,''historical_1d_quotes'', _landing_id, _run_id
        from staging.'|| p_object_basename ;
    v_cnt_stmt varchar = 'select count(*) from staging.' || p_object_basename;
    v_cnt bigint;
begin
    execute v_truncate_stmt;
    execute v_insert_landing_data_stmt;
    execute v_insert_hashes_stmt;
    execute v_cnt_stmt into v_cnt;
    return v_cnt;
end;
$$;
