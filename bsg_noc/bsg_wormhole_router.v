`include "bsg_defines.v"
`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_wormhole_router
     import bsg_wormhole_router_pkg::StrictXY;
     import bsg_wormhole_router_pkg::StrictX;
  #(parameter flit_width_p        = "inv"
   ,parameter dims_p              = 2 // 1
   ,parameter dirs_lp         = dims_p*2+1

    // this list determines the range of bit values used to determine each dimension in the N-D router
    // cord_dims_p is normally the same as dims_p.  However, the override allows users to pass
    // a larger cord array than necessary, useful for parameterizing between 1d/nd networks
   ,parameter cord_dims_p = dims_p
   ,parameter int cord_markers_pos_p[cord_dims_p:0] =   '{ 5, 4, 0 }  // '{5,0} //
   ,parameter bit [1:0][dirs_lp-1:0][dirs_lp-1:0] routing_matrix_p =  (dims_p == 2) ? StrictXY : StrictX
   ,parameter reverse_order_p       = 0
   ,parameter len_width_p           = "inv"
   ,parameter debug_lp              = 0
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

`ifndef SYNTHESIS
    wire [dirs_lp-1:0][dirs_lp-1:0] matrix_out_in_transpose;

    bsg_transpose #(.width_p(dirs_lp),.els_p(dirs_lp)) tr (.i(routing_matrix_p[0])
                                                          ,.o(matrix_out_in_transpose)
                                                          );
    always_ff @(negedge reset_i)
      begin
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

  assign link_i_cast = link_i;
  assign link_o = link_o_cast;

  genvar i,j;

  for (i = 0; i < input_dirs_lp; i=i+1)
    begin: in_ch
      localparam output_dirs_sparse_lp = `BSG_COUNTONES_SYNTH(routing_matrix_p[0][i]);

      // live decoding of output dirs from header

      wire [output_dirs_lp-1:0]        decoded_dest_lo;
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

`ifndef SYNTHESIS
      if (debug_lp)
        begin
           logic release_r;

           always_ff @(posedge clk_i)
             release_r <= releases[i];

           always_ff @(negedge clk_i)
             begin
                if (releases[i] & ~release_r)
                  $display("%m in  ch%2d: packet finished last cycle",i);

                if ((reset_i === 1'b0) && link_i_cast[i].v && !link_o_cast[i].ready_and_rev)
                  $display("%m in  ch%2d: nacking   packet %h",i,link_i_cast[i].data);
                else
                  if ((reset_i === 1'b0) && link_i_cast[i].v && link_o_cast[i].ready_and_rev)
                    $display("%m in  ch%2d: accepting packet %h",i,link_i_cast[i].data);
                if ((reset_i === 1'b0) && any_yumi)
                  begin
                     assert (fifo_valid_lo[i]) else $error("Error dequeing when data not available");
                     if (reqs_lo)
                       $display("%m in  ch%2d: dequeing  header %h (outch=%b,len=%b,dest=%b)",i,fifo_data_lo[i],reqs_lo,hdr.len,hdr.cord);
                     else
                       $display ("%m in  ch%2d: dequeing  packet %h",i, fifo_data_lo[i]);
                  end

             end // always_ff @
        end
`endif

      bsg_wormhole_router_decoder_dor #(.dims_p(dims_p)
                                       ,.cord_dims_p(cord_dims_p)
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

      wire detected_header_lo;

      bsg_wormhole_router_input_control #(.output_dirs_p(output_dirs_sparse_lp), .payload_len_bits_p($bits(hdr.len))) wic
      (.clk_i
       ,.reset_i
       ,.fifo_v_i           (fifo_valid_lo[i])
       ,.fifo_yumi_i        (any_yumi)
       ,.fifo_decoded_dest_i(decoded_dest_sparse_lo)
       ,.fifo_payload_len_i (hdr.len)
       ,.reqs_o             (reqs_lo)
       ,.release_o          (releases[i]) // broadcast to all
       ,.detected_header_o  (detected_header_lo)
      );

       // switch to dense matrix form
      bsg_unconcentrate_static #(.pattern_els_p(routing_matrix_p[0][i])) unc
        (.i  (reqs_lo)
         ,.o (reqs[i]) // unicast
       );

`ifndef SYNTHESIS
      always_ff @(negedge clk_i)
        if (debug_lp)
          assert (detected_header_lo!==1'b1 || !(decoded_dest_lo & ~ routing_matrix_p[0][i]))
            else $error("%m input port %d request to route in direction not supported by router %b %b",i,decoded_dest_lo, routing_matrix_p[0][i]);
`endif

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

`ifndef SYNTHESIS
       always_ff @(negedge clk_i)
         begin
            if (debug_lp)
              begin
                if ((reset_i === 1'b0) && link_o_cast[i].v)
                  begin
                    if (link_i_cast[i].ready_and_rev)
                      begin
                        $display("%m out ch%2d: sending   packet %h",i,link_o_cast[i].data);
                      end
                  end
              end
         end
`endif

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
