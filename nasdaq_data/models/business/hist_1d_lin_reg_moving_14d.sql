with calc as (select q.*,
                     (open + high + low + close) / 4                                                                 as olhc4,
                     open - close                                                                                    as oc_delta,
                     high - low                                                                                      as hl_delta,
                     (open - close) / ((open + high + low + close) / 4)                                              as relative_oc,
                     (high - low) / ((open + high + low + close) / 4)                                                as relative_hl,
                     avg(volume)
                     over (partition by symbol order by date rows between 13 preceding and current row )             as ma_vol_14,
                     avg((open + high + low + close) / 4)
                     over (partition by symbol order by date rows between 13 preceding and current row )             as ma_olhc_14,
                     row_number() over (partition by symbol order by date) as x
              from {{ref('historical_1d_quotes_cleansed')}} q),
     lin_reg as (
         select  c.*,
                 regr_slope(olhc4, x) over (partition by symbol order by date rows between 13 preceding and current row) slope_olhc_14,
                 regr_intercept(olhc4, x) over (partition by symbol order by date rows between 13 preceding and current row) intercept_olhc_14
         from calc c
     ),
     atan as (
         select l.*,
                atan(slope_olhc_14) as phi_slope_olhc_14
         from lin_reg l
     )
select * from atan
order by symbol, date