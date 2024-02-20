{{ transition_matrix(table_name='historical_1d_quotes_cleansed',
                    column='close',
                    event_criteria = {'up': 'open > prev_close',
                                      'down': 'open < prev_close'}
                    )
}}