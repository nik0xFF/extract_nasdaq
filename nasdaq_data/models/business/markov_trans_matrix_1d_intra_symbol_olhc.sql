{{ transition_matrix(table_name='hist_1d_lin_reg_moving_14d',
                    column='olhc4',
                    event_criteria = {'up': 'olhc4 > prev_olhc4',
                                      'down': 'olhc4 < prev_olhc4'}
                    )
}}