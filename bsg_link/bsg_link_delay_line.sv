
module bsg_link_delay_line
 import bsg_tag_pkg::*;
 import bsg_link_pkg::*;

 // Hardcoded for channel width 16
 #(localparam width_lp = 18)

  (input  tag_clk_i
  ,input  bsg_chip_delay_tag_lines_s tag_lines_i
  ,input  [width_lp-1:0] i
  ,output [width_lp-1:0] o
  );

  wire [width_lp-1:0][1:0] sel;

  for (genvar k = 0; k < width_lp; k++)
    assign #(sel[k]*50) o[k] = i[k];

  wire bsg_tag_s btc0_tag_lines_li = {tag_clk_i, tag_lines_i.data[0][2:0]};
  wire bsg_tag_s btc1_tag_lines_li = {tag_clk_i, tag_lines_i.data[1][2:0]};
  wire bsg_tag_s btc2_tag_lines_li = {tag_clk_i, tag_lines_i.data[2][2:0]};
  wire bsg_tag_s btc3_tag_lines_li = {tag_clk_i, tag_lines_i.clk    [2:0]};

  // hardcoded for bsg_link_channel_width_gp = 16 and tag payload width 12
  bsg_tag_client_unsync #(.width_p(12)) btc0
  (.bsg_tag_i     (btc0_tag_lines_li)
  ,.data_async_r_o(sel[0+:6]));
  bsg_tag_client_unsync #(.width_p(12)) btc1
  (.bsg_tag_i     (btc1_tag_lines_li)
  ,.data_async_r_o(sel[6+:6]));
  bsg_tag_client_unsync #(.width_p(10)) btc2
  (.bsg_tag_i     (btc2_tag_lines_li)
  ,.data_async_r_o(sel[12+:5]));
  bsg_tag_client_unsync #(.width_p(2)) btc3
  (.bsg_tag_i     (btc3_tag_lines_li)
  ,.data_async_r_o(sel[17]));

endmodule
