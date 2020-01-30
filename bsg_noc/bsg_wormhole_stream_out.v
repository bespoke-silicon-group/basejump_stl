
`include "bsg_defines.v"

module bsg_wormhole_stream_out
 #(parameter flit_width_p  = "inv"
   , parameter hdr_width_p = "inv"
   )
  (input                             clk_i
   , input                           reset_i

   , input [flit_width_p-1:0]        link_data_i
   , input                           link_v_i
   , output logic                    link_ready_o

   , output logic [hdr_width_p-1:0]  hdr_o
   , output logic                    hdr_v_o
   , input                           hdr_yumi_i

   , output logic [flit_width_p-1:0] data_o
   , output logic                    data_v_o
   , input                           data_yumi_i
   );

  localparam hdr_len_lp = `BSG_CDIV(hdr_width_p, flit_width_p);

  logic hdr_v_li, hdr_ready_lo;
  assign hdr_v_li = link_ready_o & link_v_i & ~hdr_v_o;
  bsg_serial_in_parallel_out_full
   #(.width_p(flit_width_p)
     ,.els_p(hdr_len_lp)
     )
   hdr_sipo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(link_data_i)
     ,.v_i(hdr_v_li)
     ,.ready_o(hdr_ready_lo)

     ,.data_o(hdr_o)
     ,.v_o(hdr_v_o)
     ,.yumi_i(hdr_yumi_i)
     );

  logic data_v_li, data_ready_lo;
  assign data_v_li = link_ready_o & link_v_i & hdr_v_o;
  bsg_two_fifo
   #(.width_p(flit_width_p))
   data_fifo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(link_data_i)
     ,.v_i(data_v_li)
     ,.ready_o(data_ready_lo)

     ,.data_o(data_o)
     ,.v_o(data_v_o)
     ,.yumi_i(data_yumi_i)
     );

  assign link_ready_o = hdr_v_o ? data_ready_lo : hdr_ready_lo;

  if (hdr_width_p % flit_width_p != 0)
    $fatal("Header width: %d must be multiple of flit width: %d", hdr_width_p, flit_width_p);

endmodule

