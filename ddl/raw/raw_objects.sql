create table raw.historical_1d_quotes
(
    symbol varchar,
    timestamp timestamp,
    open float,
    low float,
    high float,
    close float,
    volume bigint,
    _run_id bigint references meta.pipeline_runs,
    _hash varchar
);
