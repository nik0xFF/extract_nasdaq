create sequence meta.seq_id_pipelines start 1;
create table meta.pipelines (
  id bigint primary key default nextval('meta.seq_id_pipelines'),
  name varchar not null,
  description varchar
);

create sequence meta.seq_id_pipeline_runs start 1;
create table meta.pipeline_runs (
    id bigint primary key default nextval('meta.seq_id_pipeline_runs'),
    pipeline_id bigint not null references meta.pipelines,
    started timestamp,
    finished timestamp
);

create sequence meta.seq_id_pipeline_objects start 1;
create table meta.pipeline_objects (
    id bigint primary key default nextval('meta.seq_id_pipeline_objects'),
    pipeline_id bigint not null references meta.pipelines,
    base_name varchar
);

drop view meta.v_pipelines_overview;
create or replace view meta.v_pipelines_overview as
with last_runs as (
    select * from (
        select *, row_number() over (partition by pipeline_id order by started desc) as rn
        from meta.pipeline_runs
    ) cur
    where cur.rn = 1
)
select pi.id as pipeline_id
     , name
     , string_agg(po.base_name, ',') over ( partition by pi.id) as pipline_objects
     , pr.id as current_run_id
     , pr.started as current_started
     , pr.finished as current_finished
from meta.pipelines pi
left join meta.pipeline_objects po on pi.id = po.pipeline_id
left join last_runs pr on pi.id = pr.pipeline_id;

create or replace function meta.start_pipeline_run(p_pipeline_name varchar)
returns bigint
language plpgsql
as
$$
    declare
        v_current_run_id bigint;
        v_pipeline_id bigint;
        v_current_finished bigint;
        v_current_started bigint;
    begin
        select current_run_id, pipeline_id
        into v_current_run_id, v_pipeline_id,v_current_started, v_current_finished
        from meta.v_pipelines_overview
        where name = p_pipeline_name;

        if v_current_run_id is null or v_current_finished is not null then
            insert into meta.pipeline_runs
                ( pipeline_id, started)
            values (v_pipeline_id, current_timestamp)
            returning id into v_current_run_id;
        end if;

        return v_current_run_id;
    end;
$$;

select * from meta.v_pipelines_overview where pipline_objects like 'historical_1d_quotes';

create or replace function meta.get_current_run_id(p_object_name varchar)
    returns bigint
    language plpgsql
as
$$
    declare
        v_current_run_id bigint;
    begin
        select current_run_id
        into v_current_run_id
        from meta.v_pipelines_overview
        where lower(pipline_objects) like '%' || lower(p_object_name) || '%'
        and current_finished is null;


        return v_current_run_id;

    end;
$$;

create function meta.finish_pipeline_run(p_pipeline_name varchar)
    returns bigint
    language plpgsql
as
$$
    declare
        v_current_run_id bigint;
        v_current_finished bigint;
    begin
        select current_run_id, pipeline_id
        into v_current_run_id, v_current_finished
        from meta.v_pipelines_overview
        where name = p_pipeline_name;
        if v_current_finished is not null then
            update meta.pipeline_runs
            set finished = current_timestamp
            where id = v_current_run_id
            returning id into v_current_run_id;
        end if;
        return v_current_run_id;
    end;
$$;