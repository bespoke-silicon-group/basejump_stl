///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_dmc_sys_cfg_gen
//  DESCRIPTION: Part of the bsg_dmc hierarchy. Input: chip side tag liens, Output: decoded tag values, DFI 2x clock
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/26/22
///////////////////////////////////////////////////////////////////////////////////////////////////
module bsg_dmc_sys_cfg_gen
						import bsg_tag_pkg::*;
						import bsg_dmc_pkg::*;
						(
						input  bsg_dmc_cfg_tag_lines_s cfg_tag_lines_i
						,input bsg_dmc_sys_tag_lines_s sys_tag_lines_i
						,input dfi_clk_1x_i
						,output bsg_dmc_s dmc_p_o
						,output async_reset_o
						,output logic dfi_stall_transactions_o
						,output logic dfi_test_mode_o
						);

    for (genvar i = 0; i < 2; i++)
      begin : trefi
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.trefi[i] )
           ,.recv_clk_i    ( dfi_clk_1x_i             )
           ,.recv_new_r_o  (                          )
           ,.recv_data_r_o ( dmc_p_o.trefi[i*bsg_dmc_tag_client_width_gp+:bsg_dmc_tag_client_width_gp] )
           );
      end

    for (genvar i = 0; i < 1; i++)
      begin : trfc_tmrd
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.trfc_tmrd    )
           ,.recv_clk_i    ( dfi_clk_1x_i                 )
           ,.recv_new_r_o  (                              )
           ,.recv_data_r_o ( {dmc_p_o.trfc, dmc_p_o.tmrd} )
           );
      end

    for (genvar i = 0; i < 1; i++)
      begin : trp_trc
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.trp_trc    )
           ,.recv_clk_i    ( dfi_clk_1x_i               )
           ,.recv_new_r_o  (                            )
           ,.recv_data_r_o ( {dmc_p_o.trp, dmc_p_o.trc} )
           );
      end

    for (genvar i = 0; i < 1; i++)
      begin : trrd_tras
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.trrd_tras    )
           ,.recv_clk_i    ( dfi_clk_1x_i                 )
           ,.recv_new_r_o  (                              )
           ,.recv_data_r_o ( {dmc_p_o.trrd, dmc_p_o.tras} )
           );
      end

    for (genvar i = 0; i < 1; i++)
      begin : twr_trcd
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.twr_trcd    )
           ,.recv_clk_i    ( dfi_clk_1x_i                )
           ,.recv_new_r_o  (                             )
           ,.recv_data_r_o ( {dmc_p_o.twr, dmc_p_o.trcd} )
           );
      end

    for (genvar i = 0; i < 1; i++)
      begin : trtp_twtr
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.trtp_twtr    )
           ,.recv_clk_i    ( dfi_clk_1x_i                 )
           ,.recv_new_r_o  (                              )
           ,.recv_data_r_o ( {dmc_p_o.trtp, dmc_p_o.twtr} )
           );
      end

    for (genvar i = 0; i < 1; i++)
      begin : dqs_sel_cal_tcas
        // DQS sel cal is only 3 bits
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp-1))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.dqs_sel_cal_tcas    )
           ,.recv_clk_i    ( dfi_clk_1x_i                        )
           ,.recv_new_r_o  (                                     )
           ,.recv_data_r_o ( {dmc_p_o.dqs_sel_cal, dmc_p_o.tcas} )
           );
      end

    for (genvar i = 0; i < 1; i++)
      begin : row_width_col_width
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.row_width_col_width    )
           ,.recv_clk_i    ( dfi_clk_1x_i                           )
           ,.recv_new_r_o  (                                        )
           ,.recv_data_r_o ( {dmc_p_o.row_width, dmc_p_o.col_width} )
           );
      end

    for (genvar i = 0; i < 1; i++)
      begin : bank_pos_bank_width
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.bank_pos_bank_width    )
           ,.recv_clk_i    ( dfi_clk_1x_i                           )
           ,.recv_new_r_o  (                                        )
           ,.recv_data_r_o ( {dmc_p_o.bank_pos, dmc_p_o.bank_width} )
           );
      end

    for (genvar i = 0; i < 2; i++)
      begin : init_cycles
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.init_cycles[i]         )
           ,.recv_clk_i    ( dfi_clk_1x_i                           )
           ,.recv_new_r_o  (                                        )
           ,.recv_data_r_o ( dmc_p_o.init_cycles[i*bsg_dmc_tag_client_width_gp+:bsg_dmc_tag_client_width_gp] )
           );
      end

    for (genvar i = 0; i < 2; i++)
      begin : tcalr
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.tcalr[i]     )
           ,.recv_clk_i    ( dfi_clk_1x_i                           )
           ,.recv_new_r_o  (                                        )
           ,.recv_data_r_o ( dmc_p_o.tcalr[i*bsg_dmc_tag_client_width_gp+:bsg_dmc_tag_client_width_gp] )
           );
    end

    for (genvar i = 0; i < 2; i++)
      begin : init_calib_reads
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.init_calib_reads[i]    )
           ,.recv_clk_i    ( dfi_clk_1x_i                           )
           ,.recv_new_r_o  (                                        )
           ,.recv_data_r_o ( dmc_p_o.init_calib_reads[i*bsg_dmc_tag_client_width_gp+:bsg_dmc_tag_client_width_gp] )
           );
    end

    for (genvar i = 0; i < 1; i++)
      begin : calib_num_reads
        bsg_tag_client #(.width_p(bsg_dmc_tag_client_width_gp))
         btc
          (.bsg_tag_i      ( cfg_tag_lines_i.calib_num_reads)
           ,.recv_clk_i    ( dfi_clk_1x_i                   )
           ,.recv_new_r_o  (                                )
           ,.recv_data_r_o ( dmc_p_o.calib_num_reads        )
           );
    end

    for (genvar i = 0; i < 1; i++)
      begin : async_reset
        bsg_tag_client #(.width_p(1))
         btc
          (.bsg_tag_i      ( sys_tag_lines_i.async_reset            )
           ,.recv_clk_i    ( dfi_clk_1x_i                           )
           ,.recv_new_r_o  (                                        )
           ,.recv_data_r_o ( async_reset_o                          )
           );
      end

    for (genvar i = 0; i < 1; i++)
      begin : stall_transactions
        bsg_tag_client #(.width_p(1))
         btc
          (.bsg_tag_i      ( sys_tag_lines_i.stall_transactions     )
           ,.recv_clk_i    ( dfi_clk_1x_i                           )
           ,.recv_new_r_o  (                                        )
           ,.recv_data_r_o ( dfi_stall_transactions_o                   )
           );
       end

    for (genvar i = 0; i < 1; i++)
      begin : dfi_test_mode
        bsg_tag_client #(.width_p(1))
         btc
          (.bsg_tag_i      ( sys_tag_lines_i.test_mode     )
           ,.recv_clk_i    ( dfi_clk_1x_i                  )
           ,.recv_new_r_o  (                               )
           ,.recv_data_r_o ( dfi_test_mode_o                   )
           );
      end

endmodule

`BSG_ABSTRACT_MODULE(bsg_dmc_sys_cfg_gen)
