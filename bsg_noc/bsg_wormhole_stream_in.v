
`include "bsg_defines.v"

//
// Converts a higher level protocol into a wormhole router without deserializing
//   the data. This module can be used for converting various DMA formats to 
//   wormhole flits efficently and with minimal buffering. It can also be used to
//   forward data between wormholes on different networks, or to convert between
//   multiple protocol formats.
//
// Assumptions:
//   - data width is a multiple of flit width (would be easy to add support)
//   - header width is a multiple of flit width  (would be more challenging)
//     - header width == wormhole header width + protocol header width
//   - wormhole packets are laid out like the following:
//   ---------------------------------------------------------------
//   | data   | data  | data  | data  | protocol info | len   cord |
//   ---------------------------------------------------------------
//
//  Header and data can be sent at the same time, but only 1 message at a time 
//    is supported. 
//  - Legal: H     H
//             D-D   D-D
//  - Legal: H   H
//           D-D D-D
//  - Illegal: H H
//             D-D-D-D
//
module bsg_wormhole_stream_in
 #(// The wormhole router protocol information
   parameter flit_width_p      = "inv"
   // Default to 0 for cord and cid, so that this can be used either
   //   for concentrator or router
   , parameter cord_width_p    = 0
   , parameter len_width_p     = "inv"
   , parameter cid_width_p     = 0

   // Higher level protocol information
   , parameter pr_hdr_width_p  = "inv"
   , parameter pr_data_width_p = "inv"

   // Derived size of the wormhole header
   , parameter wh_hdr_width_lp = cord_width_p + len_width_p + cid_width_p
   // Size of the wormhole header + the protocol header. The data starts afterwards
   , parameter hdr_width_lp = wh_hdr_width_lp + pr_hdr_width_p
   )
  (input                         clk_i
   , input                       reset_i

   // The wormhole and protocol header information
   , input [hdr_width_lp-1:0]    hdr_i
   , input                       hdr_v_i
   , output                      hdr_ready_o

   // The protocol data information
   , input [pr_data_width_p-1:0] data_i
   , input                       data_v_i
   , output                      data_ready_o

   // The input to a wormhole network
   , output [flit_width_p-1:0]   link_data_o
   , output                      link_v_o
   , input                       link_ready_i
   );

  wire is_hdr, is_data;

  localparam [len_width_p-1:0] hdr_len_lp = `BSG_CDIV(hdr_width_lp, flit_width_p);

  wire link_accept = link_ready_i & link_v_o;

  // Header is input all at once and streamed out 1 flit at a time
  logic [flit_width_p-1:0] hdr_lo;
  logic hdr_ready_lo, hdr_v_lo, hdr_yumi_li;
  bsg_parallel_in_serial_out
   #(.width_p(flit_width_p)
     ,.els_p(hdr_len_lp)
     )
   hdr_piso
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(hdr_i)
     ,.valid_i(hdr_v_i)
     ,.ready_o(hdr_ready_lo)

     ,.data_o(hdr_lo)
     ,.valid_o(hdr_v_lo)
     ,.yumi_i(hdr_yumi_li)
     );
  assign hdr_ready_o = hdr_ready_lo;
  assign hdr_yumi_li = is_hdr & link_accept;

  logic [flit_width_p-1:0] data_lo;
  logic data_ready_lo, data_v_lo, data_yumi_li;

  // Protocol data is 1 or multiple flit-sized. We accept a large protocol data
  //   and then stream out 1 flit at a time
  if (pr_data_width_p >= flit_width_p)
    begin : wide
      localparam [len_width_p-1:0] data_len_lp = `BSG_CDIV(pr_data_width_p, flit_width_p);
      bsg_parallel_in_serial_out
       #(.width_p(flit_width_p)
         ,.els_p(data_len_lp)
         )
       data_piso
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(data_i)
         ,.valid_i(data_v_i)
         ,.ready_o(data_ready_lo)

         ,.data_o(data_lo)
         ,.valid_o(data_v_lo)
         ,.yumi_i(data_yumi_li)
         );
    end
  else
    // Protocol data is less than a single flit-sized. We accept a small
    //   protocol data, aggregate it, and then send it out on the wormhole network
    begin : narrow
      localparam [len_width_p-1:0] data_len_lp = `BSG_CDIV(flit_width_p, pr_data_width_p);
      bsg_serial_in_parallel_out_full
       #(.width_p(pr_data_width_p)
         ,.els_p(data_len_lp)
         ,.use_minimal_buffering_p(1)
         )
       data_sipo
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(data_i)
         ,.v_i(data_v_i)
         ,.ready_o(data_ready_lo)

         ,.data_o(data_lo)
         ,.v_o(data_v_lo)
         ,.yumi_i(data_yumi_li)
         );
    end
  assign data_ready_o = data_ready_lo;
  assign data_yumi_li = is_data & link_accept;
  
  // Identifies which flits are header vs data flits
  bsg_wormhole_stream_control
 #(.len_width_p  (len_width_p)
  ,.hdr_len_p    (hdr_len_lp)
  ) stream_control
  (.clk_i        (clk_i)
  ,.reset_i      (reset_i)

  ,.len_i        (hdr_lo[cord_width_p+:len_width_p])
  ,.link_accept_i(link_accept)

  ,.is_hdr_o     (is_hdr)
  ,.is_data_o    (is_data)
  );

  assign link_data_o = is_hdr ? hdr_lo   : data_lo;
  assign link_v_o    = is_hdr ? hdr_v_lo : data_v_lo;

  if (hdr_width_lp % flit_width_p != 0)
    $fatal("Header width: %d must be multiple of flit width: %d", hdr_width_lp, flit_width_p);

  if ((pr_data_width_p % flit_width_p != 0) && (flit_width_p % pr_data_width_p != 0))
    $fatal("Protocol data width: %d must be multiple of flit width: %d", pr_data_width_p, flit_width_p);

endmodule

