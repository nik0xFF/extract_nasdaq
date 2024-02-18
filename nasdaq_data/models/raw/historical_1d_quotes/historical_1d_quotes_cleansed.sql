select symbol,
       date,
       to_number(open, 'FML999G999G999D9999')                        as open,
       to_number(high, 'FML999G999G999D9999')                        as high,
       to_number(low, 'FML999G999G999D9999')                         as low,
       to_number(close, 'FML999G999G999D9999')                       as close,
       to_number(case when volume = 'N/A' then 0::text else volume end::text, 'FM9G999G999') as volume
from {{ref('historical_1d_quotes')}}