
`include "bsg_defines.v"

module bsg_wormhole_stream_out
 #(parameter flit_width_p  = "inv"
   , parameter len_width_p     = "inv"
   , parameter cord_width_p    = "inv"
   , parameter pr_hdr_width_p  = "inv"
   , parameter pr_data_width_p = "inv"

   , parameter wh_hdr_width_lp = cord_width_p + len_width_p
   , parameter hdr_width_lp = wh_hdr_width_lp + pr_hdr_width_p
   )
  (input                       clk_i
   , input                     reset_i

   , input [flit_width_p-1:0]  link_data_i
   , input                     link_v_i
   , output                    link_ready_o

   , output [hdr_width_lp-1:0] hdr_o
   , output                    hdr_v_o
   , input                     hdr_yumi_i

   , output [flit_width_p-1:0] data_o
   , output                    data_v_o
   , input                     data_yumi_i
   );

  enum logic [1:0] {e_hdr, e_data} state_n, state_r;
  wire is_hdr = (state_r == e_hdr);
  wire is_data = (state_r == e_data);

  localparam [len_width_p-1:0] hdr_len_lp = `BSG_CDIV(hdr_width_lp, flit_width_p);

  wire                link_accept = link_ready_o & link_v_i;
  wire [cord_width_p-1:0] cord_li = link_data_i[0+:cord_width_p];
  wire [len_width_p-1:0]   len_li = link_data_i[cord_width_p+:len_width_p] - (hdr_len_lp - 1'b1);

  logic hdr_v_li, hdr_ready_lo;
  assign hdr_v_li = is_hdr & link_accept;
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
  assign data_v_li = is_data & link_accept;
  if (flit_width_p >= pr_data_width_p)
    begin : narrow
      localparam [len_width_p-1:0] data_len_lp = `BSG_CDIV(flit_width_p, pr_data_width_p);
      bsg_parallel_in_serial_out
       #(.width_p(pr_data_width_p)
         ,.els_p(data_len_lp)
         )
       data_piso
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(link_data_i)
         ,.valid_i(data_v_li)
         ,.ready_o(data_ready_lo)

         ,.data_o(data_o)
         ,.valid_o(data_v_o)
         ,.yumi_i(data_yumi_i)
         );
    end
  else
    begin : narrow
      localparam [len_width_p-1:0] data_len_lp = `BSG_CDIV(pr_data_width_p, flit_width_p);
      bsg_serial_in_parallel_out_full
       #(.width_p(flit_width_p)
         ,.els_p(data_len_lp)
         )
       data_sipo
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(link_data_i)
         ,.valid_i(data_v_li)
         ,.ready_o(data_ready_lo)

         ,.data_o(data_o)
         ,.valid_o(data_v_o)
         ,.yumi_i(data_yumi_i)
         );
    end

  assign link_ready_o = is_hdr ? hdr_ready_lo : data_ready_lo;

  if (hdr_width_lp % flit_width_p != 0)
    $fatal("Header width: %d must be multiple of flit width: %d", hdr_width_lp, flit_width_p);

  if ((pr_data_width_p % flit_width_p != 0) && (flit_width_p % pr_data_width_p != 0))
    $fatal("Protocol data width: %d must be multiple of flit width: %d", pr_data_width_p, flit_width_p);

endmodule

