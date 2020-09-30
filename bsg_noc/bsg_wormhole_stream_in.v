
`include "bsg_defines.v"

//
// Converts a higher level protocol into a wormhole router without deserializing
//   the data. This module can be used for converting various DMA formats to 
//   wormhole flits efficently and with minimal buffering. It can also be used to
//   forward data between wormholes on different networks, or to convert between
//   multiple protocol formats.
//
// Example use cases:
//   - bsg_cache {dma_pkt, data/v/yumi} format <-> wormhole
//   - SRAM read/write <-> bsg_wormhole_stream_in/out <-> Wormhole Network
//   - Wide Network <-> bsg_wormhole_stream_in/out <-> Narrow Network
//
// Assumptions:
//  Usage of this module requires correctly formed wormhole headers. The length
//    field of the wormhole message determines how many protocol data beats are
//    expected (some multiple or divisor of the flit_width). We expect most
//    link and protocol data widths to be powers of 2 (32, 64, 512), so this
//    length restriction is lenient.
//
//   - data width is a multiple of flit width (would be easy to add support)
//   - header width is a multiple of flit width  (would be more challenging)
//     - header width == wormhole header width + protocol header width
//   - wormhole packets are laid out like the following:
//   ---------------------------------------------------------------
//   | data   | data  | data  | data  | protocol info | len   cord |
//   ---------------------------------------------------------------
//
// Data can be sent the same or any cycle after header, but only 1 message at
//   a time is supported.
// - Legal: H     H
//            D-D   D-D
// - Legal: H   H
//          D-D D-D
// - Illegal: H H
//            D-D-D-D
//   (Header sent too early)
//
module bsg_wormhole_stream_in
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
  (input                         clk_i
   , input                       reset_i

   // The wormhole and protocol header information
   , input [hdr_width_p-1:0]     hdr_i
   , input                       hdr_v_i
   , output                      hdr_ready_and_o

   // The protocol data information
   , input [pr_data_width_p-1:0] data_i
   , input                       data_v_i
   , output                      data_ready_and_o

   // The input to a wormhole network
   , output [flit_width_p-1:0]   link_data_o
   , output                      link_v_o
   , input                       link_ready_and_i
   );

  wire is_hdr, is_data;

  localparam [len_width_p-1:0] hdr_len_lp = `BSG_CDIV(hdr_width_p, flit_width_p);

  wire link_accept = link_ready_and_i & link_v_o;

  logic [flit_width_p-1:0] hdr_lo;
  logic hdr_ready_lo, hdr_v_lo, hdr_yumi_li;

  // Header is input all at once and streamed out 1 flit at a time
  if (hdr_width_p == flit_width_p)
    begin : hdr_passthrough
      assign hdr_lo = hdr_i;
      assign hdr_v_lo = hdr_v_i;
      assign hdr_ready_and_o = is_hdr & link_ready_and_i;
    end
  else
    begin : piso
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
      assign hdr_ready_and_o = hdr_ready_lo;
      assign hdr_yumi_li = is_hdr & link_accept;
    end

  logic [flit_width_p-1:0] data_lo;
  logic data_v_lo, data_yumi_li;

  // Protocol data is 1 or multiple flit-sized. We accept a large protocol data
  //   and then stream out 1 flit at a time
  if (pr_data_width_p == flit_width_p)
    begin : data_passthrough
      assign data_lo = data_i;
      assign data_v_lo = data_v_i;
      assign data_ready_and_o = is_data & link_ready_and_i;
    end
  else if (pr_data_width_p >= flit_width_p)
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
         ,.ready_o(data_ready_and_o)

         ,.data_o(data_lo)
         ,.valid_o(data_v_lo)
         ,.yumi_i(data_yumi_li)
         );
      assign data_yumi_li = is_data & link_accept;
    end
  else
    // Protocol data is less than a single flit-sized. We accept a small
    //   protocol data, aggregate it, and then send it out on the wormhole network
    begin : narrow
      localparam [len_width_p-1:0] data_len_lp = `BSG_CDIV(flit_width_p, pr_data_width_p);
      bsg_serial_in_parallel_out_full
       #(.width_p(pr_data_width_p)
         ,.els_p(data_len_lp)
         )
       data_sipo
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(data_i)
         ,.v_i(data_v_i)
         ,.ready_o(data_ready_and_o)

         ,.data_o(data_lo)
         ,.v_o(data_v_lo)
         ,.yumi_i(data_yumi_li)
         );
      assign data_yumi_li = is_data & link_accept;
    end
  
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

  //synopsys translate_off
  if (hdr_width_p % flit_width_p != 0)
    $fatal("Header width: %d must be multiple of flit width: %d", hdr_width_p, flit_width_p);

  if ((pr_data_width_p % flit_width_p != 0) && (flit_width_p % pr_data_width_p != 0))
    $fatal("Protocol data width: %d must be multiple of flit width: %d", pr_data_width_p, flit_width_p);
  //synopsys translate_on

endmodule

