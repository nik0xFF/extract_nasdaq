import json
import logging
import os
import sys

import requests
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


def main():
    with open('../../resources/constituents.json') as titles:
        title_list = json.load(titles)
        for t in title_list:
            root.info("Processing Symbol:%s", t['Symbol'])
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
            res = requests.get(f"https://api.nasdaq.com/api/quote/{t['Symbol']}/historical",
                               params=parameters,
                               headers=headers)
            path_to_store_res = f"../../results/{t['Symbol']}/"
            os.makedirs(path_to_store_res, exist_ok=True)

            if WRITE_RESULT_TO_DISK:
                with open(os.path.join(path_to_store_res, f"{t['Symbol']}_1D.json"), 'wb') as res_file:
                    res_file.write(res.content)

            with sync_engine.connect() as conn:
                conn.execute(text("insert into landing.historical_1d_quotes(raw_data) "
                                  "values (to_json(cast(:raw_data as text)))"),
                             {"raw_data": res.content.decode()})
                conn.commit()


if __name__ == "__main__":
    main()
