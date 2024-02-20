{{ transition_matrix(base_table_name='hist_1d_lin_reg_moving_14d',
                    lookback_column='relative_oc',
                    event_criteria = {'up': 'relative_oc + prev_relative_oc > 0.01',
                                      'down': 'relative_oc + prev_relative_oc > 0.01'}
                    )
}}