create role func_nasdaq_data_rw with login password 'nasdaq';
create database nasdaq_data with owner func_nasdaq_data_rw;
grant all on database nasdaq_data to func_nasdaq_data_rw;
set role trading_data;