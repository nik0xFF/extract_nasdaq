{{ transition_matrix(base_table_name='hist_1d_lin_reg_moving_14d',
                    lookback_column='relative_oc',
                    event_criteria = {
                    'up_g_0.01': 'relative_oc > 0.01',
                    'up_b_0.01_0.005': 'relative_oc > 0.005 and relative_oc <= 0.01',
                    'up_b_0.005_0.0025': 'relative_oc > 0.0025 and relative_oc <= 0.005',
                    'down_b_0.005_0.0025': 'relative_oc < -0.0025 and relative_oc >= -0.005',
                    'down_b_0.01_0.005': 'relative_oc < -0.005 and relative_oc >= -0.01',
                    'down_g_0.01': 'relative_oc < -0.01'}
                    )
}}