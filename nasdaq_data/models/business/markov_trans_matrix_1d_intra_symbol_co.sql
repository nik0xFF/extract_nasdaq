{{ transition_matrix(base_table_name='historical_1d_quotes_cleansed',
                    lookback_column='close',
                    event_criteria= {'up': 'open > prev_close',
                                      'down': 'open < prev_close'}
                    )
}}