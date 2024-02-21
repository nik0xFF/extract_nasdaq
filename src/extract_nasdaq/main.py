import json
import logging
import os
import sys

import requests
from alpha_vantage.timeseries import TimeSeries
from pandas import DataFrame
from sqlalchemy import create_engine, text

WRITE_RESULT_TO_DISK = False

root = logging.getLogger()
root.setLevel(logging.DEBUG)

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
root.addHandler(handler)

sync_engine = create_engine("postgresql+psycopg://func_nasdaq_data_rw:nasdaq@localhost/nasdaq_data",
                            connect_args={'options': '-csearch_path=landing'})


def get_daily_from_alpha_vantage_api(symbol: str):
    ts = TimeSeries(key=os.getenv('ALPHA_VANTAGE_API_KEY'), output_format='pandas')
    data: DataFrame
    data, meta_data = ts.get_daily(symbol, outputsize='full')
    data.columns = [col.split(" ")[1].strip() for col in data.columns]
    data['symbol'] = symbol
    with sync_engine.connect() as conn:
        data.to_sql(name="daily_quotes", con=conn, schema='raw', if_exists='append')
    data.head(2)


def get_daily_from_nasdaq_api(symbol: str):
    parameters = {
        "assetclass": "stocks",
        "fromdate": "2014-02-10",
        "todate": "2024-02-10",
        "limit": "9999",
        "ramdom": "26"
    }

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:122.0) Gecko/20100101 Firefox/122.0",
        "Accept": "application/json, text/plain, */*"
    }
    res = requests.get(f"https://api.nasdaq.com/api/quote/{symbol}/historical",
                       params=parameters,
                       headers=headers)
    path_to_store_res = f"../../results/{symbol}/"
    os.makedirs(path_to_store_res, exist_ok=True)

    if WRITE_RESULT_TO_DISK:
        with open(os.path.join(path_to_store_res, f"{symbol}_1D.json"), 'wb') as res_file:
            res_file.write(res.content)
    json_s = res.content.decode()
    with sync_engine.connect() as conn:
        conn.execute(text("insert into landing.historical_1d_quotes(raw_data) "
                          "values (:raw_data)"),
                     {"raw_data": json_s})
        conn.commit()


def main():
    with open('../../resources/constituents.json') as titles:
        title_list = json.load(titles)
        for t in title_list:
            root.info("Processing Symbol:%s", t['Symbol'])
            get_daily_from_alpha_vantage_api(t['Symbol'])


if __name__ == "__main__":
    main()
