{{ transition_matrix(base_table_name='hist_1d_lin_reg_moving_14d',
                    lookback_column='olhc4',
                    event_criteria= {'up': 'olhc4 > prev_olhc4',
                                      'down': 'olhc4 < prev_olhc4'}
                    )
}}