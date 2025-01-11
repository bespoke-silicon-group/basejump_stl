
module bsg_link_delay_line

 import bsg_tag_pkg::*;
 import bsg_link_pkg::*;

 // Hardcoded for channel width 16
 #(localparam width_lp = 18)

  (input  tag_clk_i
  ,input  bsg_link_delay_tag_lines_s tag_lines_i
  ,input  [width_lp-1:0] i
  ,output [width_lp-1:0] o
  );

  wire [width_lp-1:0][1:0] sel;
  wire [width_lp-1:0] dly0, dly1, dly2;

  for (genvar k = 0; k < width_lp; k++)
  begin: sig
    sky130_fd_sc_hd__clkdlybuf4s15_1 dly0_BSG_DONT_TOUCH (.I(i   [k]),.Z(dly0[k]));
    sky130_fd_sc_hd__clkdlybuf4s15_1 dly1_BSG_DONT_TOUCH (.I(dly0[k]),.Z(dly1[k]));
    sky130_fd_sc_hd__clkdlybuf4s15_1 dly2_BSG_DONT_TOUCH (.I(dly1[k]),.Z(dly2[k]));

    sky130_fd_sc_hd__mux4_1 mux_BSG_DONT_TOUCH
    (.A0(i[k]),.A1(dly0[k]),.A2(dly1[k]),.A3(dly2[k])
    ,.S0(sel[k][0]),.S1(sel[k][1]),.X(o[k]));
  end

  wire bsg_tag_s btc0_tag_lines_li = {tag_clk_i, tag_lines_i.data[0][2:0]};
  wire bsg_tag_s btc1_tag_lines_li = {tag_clk_i, tag_lines_i.data[1][2:0]};
  wire bsg_tag_s btc2_tag_lines_li = {tag_clk_i, tag_lines_i.data[2][2:0]};
  wire bsg_tag_s btc3_tag_lines_li = {tag_clk_i, tag_lines_i.clk    [2:0]};

  bsg_tag_client_unsync #(.width_p(12), harden_p(1)) btc0
  (.bsg_tag_i     (btc0_tag_lines_li)
  ,.data_async_r_o(sel[0+:6]));
  bsg_tag_client_unsync #(.width_p(12), harden_p(1)) btc1
  (.bsg_tag_i     (btc1_tag_lines_li)
  ,.data_async_r_o(sel[6+:6]));
  bsg_tag_client_unsync #(.width_p(10), harden_p(1)) btc2
  (.bsg_tag_i     (btc2_tag_lines_li)
  ,.data_async_r_o(sel[12+:5]));
  bsg_tag_client_unsync #(.width_p(2), .harden_p(1)) btc3
  (.bsg_tag_i     (btc3_tag_lines_li)
  ,.data_async_r_o(sel[17]));

endmodule
