
`include "bsg_defines.v"

//
// Converts a wormhole router stream into a higher level protocol without
//   deserializing the data. This module can be used for converting various 
//   DMA formats to wormhole flits efficently and with minimal buffering. 
//   It can also be used to forward data between wormholes on different 
//   networks, or to convert between multiple protocol formats.
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
//  Header will arrive at or before data and either can be acked at any time.
//  Typical users of this module will simply ack the header to learn the 
//  protocol information of the impending transaction, begin the transaction,
//  and then forward or accept all of the data serially.
//
module bsg_wormhole_stream_out
 #(// The wormhole router protocol information
   // flit_width_p: number of physical data wires between links
   // cord_width_p: the width of the {y,x} coordinate of the destination
   // len_width_p : the width of the length field, denoting #flits+1
   // cid_width   : the width of the concentrator id of the destination
   // Default to 0 for cord and cid, so that this module can be used either
   //   for concentrator or router
   parameter flit_width_p      = "inv"
   , parameter cord_width_p    = 0
   , parameter len_width_p     = "inv"
   , parameter cid_width_p     = 0

   // Higher level protocol information
   , parameter pr_hdr_width_p  = "inv"
   , parameter pr_data_width_p = "inv"

   // Size of the wormhole header + the protocol header. The data starts afterwards.
   // Users may set this directly rather than relying on the protocol header derived default
   , parameter hdr_width_p = cord_width_p + len_width_p + cid_width_p + pr_hdr_width_p
   )
  (input                          clk_i
   , input                        reset_i

   // The output of a wormhole network
   , input [flit_width_p-1:0]     link_data_i
   , input                        link_v_i
   , output                       link_ready_and_o

   // The wormhole and protocol header information
   , output [hdr_width_p-1:0]     hdr_o
   , output                       hdr_v_o
   , input                        hdr_yumi_i

   // The protocol data information
   , output [pr_data_width_p-1:0] data_o
   , output                       data_v_o
   , input                        data_yumi_i
   );

  wire is_hdr, is_data;
  
  localparam [len_width_p-1:0] hdr_len_lp = `BSG_CDIV(hdr_width_p, flit_width_p);

  wire link_accept = link_ready_and_o & link_v_i;

  // Aggregate flits until we have a full header-worth of data, then let the
  //   client process it
  logic hdr_v_li, hdr_ready_lo;
  assign hdr_v_li = is_hdr & link_v_i;
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
  assign data_v_li = is_data & link_v_i;
  // Protocol data is less than a single flit-sized. We accept a large
  //   wormhole flit, then let the client process it piecemeal
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
    // Protocol data is 1 or multiple flit-sized. We aggregate wormhole data 
    //   until we have a full protocol data and then let the client process it
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
         ,.v_i(data_v_li)
         ,.ready_o(data_ready_lo)

         ,.data_o(data_o)
         ,.v_o(data_v_o)
         ,.yumi_i(data_yumi_i)
         );
    end
  
  // Identifies which flits are header vs data flits
  bsg_wormhole_stream_control
 #(.len_width_p  (len_width_p)
  ,.hdr_len_p    (hdr_len_lp)
  ) stream_control
  (.clk_i        (clk_i)
  ,.reset_i      (reset_i)

  ,.len_i        (link_data_i[cord_width_p+:len_width_p])
  ,.link_accept_i(link_accept)

  ,.is_hdr_o     (is_hdr)
  ,.is_data_o    (is_data)
  );

  assign link_ready_and_o = is_hdr ? hdr_ready_lo : data_ready_lo;

  //synopsys translate_off
  if (hdr_width_p % flit_width_p != 0)
    $fatal("Header width: %d must be multiple of flit width: %d", hdr_width_p, flit_width_p);

  if ((pr_data_width_p % flit_width_p != 0) && (flit_width_p % pr_data_width_p != 0))
    $fatal("Protocol data width: %d must be multiple of flit width: %d", pr_data_width_p, flit_width_p);
  //synopsys translate_on

endmodule

