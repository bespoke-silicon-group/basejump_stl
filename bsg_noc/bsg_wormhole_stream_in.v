
`include "bsg_defines.v"

module bsg_wormhole_stream_in
 #(parameter flit_width_p  = "inv"
   , parameter hdr_width_p = "inv"
   )
  (input                             clk_i
   , input                           reset_i

   , input [hdr_width_p-1:0]         hdr_i
   , input                           hdr_v_i
   , output                          hdr_ready_o

   , input [flit_width_p-1:0]        data_i
   , input                           data_v_i
   , output                          data_ready_o

   , output logic [flit_width_p-1:0] link_data_o
   , output logic                    link_v_o
   , input                           link_ready_i
   );

  localparam hdr_len_lp = `BSG_CDIV(hdr_width_p, flit_width_p);


  logic [flit_width_p-1:0] hdr_lo;
  logic hdr_v_lo, hdr_yumi_li;
  bsg_parallel_in_serial_out
   #(.width_p(flit_width_p)
     ,.els_p(hdr_len_lp)
     )
   hdr_piso
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(hdr_i)
     ,.valid_i(hdr_v_i)
     ,.ready_o(hdr_ready_o)

     ,.data_o(hdr_lo)
     ,.valid_o(hdr_v_lo)
     ,.yumi_i(hdr_yumi_li)
     );
  assign hdr_yumi_li = link_ready_i & link_v_o & hdr_v_lo;

  // There is a bubble here which could be avoided with a bypassable fifo
  logic [flit_width_p-1:0] data_lo;
  logic data_v_lo, data_yumi_li;
  bsg_two_fifo
   #(.width_p(flit_width_p))
   data_fifo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(data_i)
     ,.v_i(data_v_i)
     ,.ready_o(data_ready_o)

     ,.data_o(data_lo)
     ,.v_o(data_v_lo)
     ,.yumi_i(data_yumi_li)
     );
  assign data_yumi_li = link_ready_i & link_v_o & ~hdr_v_lo;

  assign link_data_o = hdr_v_lo ? hdr_lo : data_lo;
  assign link_v_o = hdr_v_lo | data_v_lo;

  if (hdr_width_p % flit_width_p != 0)
    $fatal("Header width: %d must be multiple of flit width: %d", hdr_width_p, flit_width_p);

endmodule

