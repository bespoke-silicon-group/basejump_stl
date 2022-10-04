  parameter clk_gen_num_adgs_p = 1;
  //address format: {bank_addr, row_addr, col_addr}
  parameter ui_addr_width_p    = 28;
  parameter ui_data_width_p    = 32;
  parameter ui_burst_length_p  = 8;
  parameter dq_data_width_p    = 32;
  parameter cmd_afifo_depth_p  = 4;
  parameter cmd_sfifo_depth_p  = 4;
  parameter debug_p            = 1'b1;

  localparam burst_data_width_lp = ui_data_width_p * ui_burst_length_p;
  localparam ui_mask_width_lp    = ui_data_width_p >> 3;
  localparam dq_group_lp         = dq_data_width_p >> 3;
  localparam dq_burst_length_lp  = burst_data_width_lp / dq_data_width_p;
