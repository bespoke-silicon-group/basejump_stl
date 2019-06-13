`include "bsg_defines.v"
`include "bsg_noc_links.vh"

// this is a partial packet header, which should always go at the bottom bits of a packet
// move to bsg_wormhole_router.vh
`define declare_bsg_wormhole_router_header_s(in_cord_width,in_len_width,in_struct_name) \
typedef struct packed {                 \
  logic [in_len_width-1:0]    len;      \
  logic [in_cord_width-1:0 ]  cord;     \
} in_struct_name

module bsg_wormhole_router
     import bsg_wormhole_router_pkg::StrictXY;
     import bsg_wormhole_router_pkg::StrictX;
  #(parameter flit_width_p        = 32 // "inv"
   ,parameter dims_p                = 1 // 2
   ,parameter dirs_lp         = dims_p*2+1
   ,parameter int cord_markers_pos_p[dims_p:0] = '{5,0} // '{ 5, 4, 0 }
   ,parameter bit [1:0][dirs_lp-1:0][dirs_lp-1:0] routing_matrix_p = StrictX  /* 0 = [input][output], 1=[output][input] */
   ,parameter reverse_order_p       = 0
   ,parameter len_width_p     = 5 // = "inv"

   )

  (input clk_i
  ,input reset_i

  // Traffics
  ,input  [dirs_lp-1:0][`bsg_ready_and_link_sif_width(flit_width_p)-1:0] link_i
  ,output [dirs_lp-1:0][`bsg_ready_and_link_sif_width(flit_width_p)-1:0] link_o

  // My coordinate data
   ,input [cord_markers_pos_p[dims_p]-1:0] my_cord_i
  );

  localparam input_dirs_lp  = dirs_lp;
  localparam output_dirs_lp = dirs_lp;

  // FIXME: move to bsg_wormhole_router.vh
  `declare_bsg_wormhole_router_header_s(cord_markers_pos_p[dims_p], len_width_p, bsg_wormhole_router_header_s);

  bsg_wormhole_router_header_s hdr;

`ifndef SYNTHESIS
    localparam[dirs_lp-1:0][dirs_lp-1:0] matrix_out_in_transpose;

    bsg_transpose #(.width_p(dirs_lp),.els_p(dirs_lp)) (.i(routing_matrix_p[0])
                                                       ,.o(matrix_out_in_transpose)
                                                       );
    initial
      begin
        #1000;
        assert (routing_matrix_p[1] == matrix_out_in_transpose)
          else $error("inconsistent matrixes");
      end
`endif

  // we collect the information for each FIFO here
  wire [input_dirs_lp-1:0][flit_width_p-1:0] fifo_data_lo;
  wire [input_dirs_lp-1:0]                     fifo_valid_lo;

  // one for each input channel; it broadcasts that it is finished to all of the outputs
  wire [dirs_lp-1:0] releases;

  // from each input to each output
  wire [dirs_lp-1:0][dirs_lp-1:0] reqs,     reqs_transpose;

  // from each output to each input
  wire [dirs_lp-1:0][dirs_lp-1:0] yumis,    yumis_transpose;

  `declare_bsg_ready_and_link_sif_s(flit_width_p,bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [dirs_lp-1:0] link_i_cast, link_o_cast;

  genvar i,j;

  for (i = 0; i < input_dirs_lp; i=i+1)
    begin: in_ch
      localparam output_dirs_sparse_lp = `BSG_COUNTONES_SYNTH(routing_matrix_p[0][i]);

      // live decoding of output dirs from header

      wire [output_dirs_lp-1:0] decoded_dest_lo;
      wire [output_dirs_sparse_lp-1:0] decoded_dest_sparse_lo;
      wire [output_dirs_sparse_lp-1:0] reqs_lo, yumis_li;

      bsg_concentrate_static #(.pattern_els_p(routing_matrix_p[0][i])) conc
      (.i(yumis_transpose[i])
       ,.o(yumis_li)
      );

      wire any_yumi = | yumis_li;

      bsg_two_fifo #(.width_p(flit_width_p)) twofer
        (.clk_i
         ,.reset_i
        ,.ready_o(link_o_cast[i].ready_and_rev)
        ,.data_i (link_i_cast[i].data)
        ,.v_i    (link_i_cast[i].v)
        ,.v_o    (fifo_valid_lo[i])
        ,.data_o (fifo_data_lo [i])
        ,.yumi_i (any_yumi)
         );

      bsg_wormhole_router_header_s hdr;

      assign hdr = fifo_data_lo[i][$bits(bsg_wormhole_router_header_s)-1:0];

      bsg_wormhole_router_decoder_dor #(.dims_p(dims_p)
                                       ,.reverse_order_p(reverse_order_p)
                                       ,.cord_markers_pos_p(cord_markers_pos_p)
                                       ) dor
      (.target_cord_i(hdr.cord)
       ,.my_cord_i
       ,.req_o(decoded_dest_lo)
      );

      bsg_concentrate_static #(.pattern_els_p(routing_matrix_p[0][i])) conc_dec
      (.i(decoded_dest_lo)
       ,.o(decoded_dest_sparse_lo)
      );

      // fixme: add assertions for stubbed out parameters

      bsg_wormhole_router_input_control #(.output_dirs_p(output_dirs_sparse_lp), .payload_len_bits_p($bits(hdr.len))) wic
      (.clk_i
       ,.reset_i
       ,.fifo_v_i           (fifo_valid_lo[i])
       ,.fifo_yumi_i        (any_yumi)
       ,.fifo_decoded_dest_i(decoded_dest_sparse_lo)
       ,.fifo_payload_len_i (hdr.len)
       ,.reqs_o             (reqs_lo)
       ,.release_o          (releases[i]) // broadcast to all
      );

       // switch to dense matrix form
      bsg_unconcentrate_static #(.pattern_els_p(routing_matrix_p[0][i])) unc
        (.i (reqs_lo)
         ,.o (reqs[i]) // unicast
       );
    end

   // flip signal wires from input-indexed to output-indexed
   // this is swizzling the wires that connect input ports and output ports
   bsg_transpose #(.width_p(dirs_lp),.els_p(dirs_lp)) reqs_trans
   (.i(reqs)
    ,.o(reqs_transpose)
   );

  // iterate through each output channel
  for (i = 0; i < output_dirs_lp; i=i+1)
    begin: out_ch
      localparam input_dirs_sparse_lp = `BSG_COUNTONES_SYNTH(routing_matrix_p[1][i]);
      wire [input_dirs_sparse_lp-1:0] reqs_li, release_li, valids_li, yumis_lo, data_sel_lo;
      wire [input_dirs_sparse_lp-1:0][flit_width_p-1:0] fifo_data_sparse_lo;

      bsg_concentrate_static #(.pattern_els_p(routing_matrix_p[1][i])) conc
      (.i(reqs_transpose[i]),.o(reqs_li));

      bsg_concentrate_static #(.pattern_els_p(routing_matrix_p[1][i])) conc2
      (.i(releases),.o(release_li));

      bsg_concentrate_static #(.pattern_els_p(routing_matrix_p[1][i])) conc3
      (.i(fifo_valid_lo),.o(valids_li));

      bsg_array_concentrate_static #(.width_p(flit_width_p), .pattern_els_p(routing_matrix_p[1][i])) conc4
      (.i(fifo_data_lo),.o(fifo_data_sparse_lo));

      assign link_o_cast[i].v = |valids_li;

      bsg_wormhole_router_output_control #(.input_dirs_p(input_dirs_sparse_lp)) woc
      (.clk_i
      ,.reset_i
      ,.reqs_i    (reqs_li   )
      ,.release_i (release_li)
      ,.valid_i   (valids_li )
      ,.yumi_o    (yumis_lo  )
      ,.ready_i   (link_i_cast[i].ready_and_rev)
      ,.valid_o   (link_o_cast[i].v)
      ,.data_sel_o(data_sel_lo)
      );

      bsg_mux_one_hot #(.width_p(flit_width_p)
                       ,.els_p(input_dirs_sparse_lp)
                       ) data_mux
      (.data_i(fifo_data_sparse_lo)
       ,.sel_one_hot_i(data_sel_lo)
       ,.data_o(link_o_cast[i].data)
      );

      bsg_unconcentrate_static #(.pattern_els_p(routing_matrix_p[1][i])) unc1
      (.i (yumis_lo)
       ,.o (yumis[i])
      );
    end

   // flip signal wires from output-indexed to input-indexed
   // this is swizzling the wires that connect input ports and output ports
   bsg_transpose #(.width_p(dirs_lp),.els_p(dirs_lp)) yumis_trans
   (.i(yumis)
    ,.o(yumis_transpose)
   );

endmodule
