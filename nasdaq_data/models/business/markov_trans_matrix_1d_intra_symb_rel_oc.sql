{{ transition_matrix(base_table_name='hist_1d_lin_reg_moving_14d',
                    lookback_column='relative_oc',
                    event_criteria = {
                    'up_g_1': 'relative_oc > 0.01',
                    'up_s_1': 'relative_oc > 0.005 and relative_oc <= 0.01',
                    'up_s_1': 'relative_oc > 0.005 and relative_oc <= 0.01',
                    'down_s_1': 'relative_oc < -0.005 and relative_oc >= -0.01',
                    'down_g_1': 'relative_oc < -0.01'}
                    )
}}