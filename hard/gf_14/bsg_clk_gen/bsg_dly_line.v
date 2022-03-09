
module bsg_dly_line
 import bsg_tag_pkg::*;
 #(parameter `BSG_INV_PARAM(num_row_p)
   , parameter `BSG_INV_PARAM(num_col_p)
   )
  (input bsg_tag_s bsg_tag_trigger_i
   , input [`BSG_SAFE_CLOG2(num_row_p*num_col_p)-1:0] ctl_r_i
   , input async_reset_i
   , output logic clk_o
   );

  wire fb, n0, n1, n2, fb_dly
  SC7P5T_CKBUFX2_SSC14SL B0 (.Z(n0    ), .CLK(fb));
  SC7P5T_CKBUFX2_SSC14SL B1 (.Z(n1    ), .CLK(n0));
  SC7P5T_CKBUFX2_SSC14SL B2 (.Z(n2    ), .CLK(n1));
  SC7P5T_CKBUFX2_SSC14SL B3 (.Z(fb_dly), .CLK(n2));

  wire fb_inv;
  SC7P5T_CKINVX8_SSC14SL I0 (.Z(fb_inv), .CLK(clk_i));
  SC7P5T_CKINVX8_SSC14SL I1 (.Z(clk_o ), .CLK(fb_dly));

  logic gate_en_r;
  bsg_tag_client_unsync #(.width_p(1))
   btc_clkgate
    (.bsg_tag_i(bsg_tag_trigger_i)
     ,.data_async_r_o(gate_en_r)
     );

  logic gate_en_sync_r;
  bsg_sync_sync #(.width_p(1))
   bss
    (.oclk_i(fb_inv)
     ,.iclk_data_i(gate_en_r)
     ,.oclk_data_o(gate_en_sync_r)
     );

  wire lobit;
  SC7P5T_TIELOX1_SSC14SL T0 (.Z(lobit));

  wire fb_gated;
  SC7P5T_CKGPRELATNX24_SSC14SL CG0 (.Z(fb_gated), .CLK(fb_inv), .E(gate_en_sync_r), .TE(lobit));
  
  logic [num_col_p-1:0][num_row_p-1:0] ctl_one_hot_lo;
  bsg_decode #(.num_out_p(num_col_p*num_row_p)) decode
   (.i(ctl_r_i)
    ,.o(ctl_one_hot_lo)
    );

  wire [num_col_p:0] fb_col;
  assign fb_col[0] = lobit;
  for (genvar i = 0; i < num_col_p; i++)
    begin : c
      bsg_clk_gen_osc_column #(.num_row_p(num_row_p)) col
       (.async_reset_i(async_reset_i)
        ,.clkgate_i(fb_gated)
        ,.clkdly_i(fb_dly)
        ,.clkfb_i(fb_col[i])
        ,.ctl_one_hot_i(ctl_one_hot_lo[i])
        ,.clk_o(fb_col[i+1])
        );
    end
  assign fb = fb_col[num_col_p];

endmodule


