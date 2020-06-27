/**
 *    bsg_noc_crossbar.v
 *
 *    WARNING: this NOC scales as (N*width)^2 or worse.
 *    Large crossbars will have very poor efficiency in the backend.
 *
 */

`include "bsg_noc_links.vh"

module bsg_noc_crossbar 
  #(parameter num_in_p="inv"
    , parameter width_p="inv"

    , parameter lg_num_in_lp = `BSG_SAFE_CLOG2(num_in_p)
    , parameter link_sif_width_lp=`bsg_ready_and_link_sif_width(width_p)
  )
  (
    input clk_i
    , input reset_i

    , input  [num_in_p-1:0][link_sif_width_lp-1:0] links_sif_i
    , output [num_in_p-1:0][link_sif_width_lp-1:0] links_sif_o

    , output [num_in_p-1:0] links_credit_o
  );


  `declare_bsg_ready_and_link_sif_s(width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [num_in_p-1:0] links_sif_in;
  bsg_ready_and_link_sif_s [num_in_p-1:0] links_sif_out;

  assign links_sif_in = links_sif_i;
  assign links_sif_o = links_sif_out;


  // input buffer
  logic [num_in_p-1:0] fifo_v_lo;
  logic [num_in_p-1:0][width_p-1:0] fifo_data_lo;
  logic [num_in_p-1:0] fifo_yumi_li;

  for (genvar i = 0; i < num_in_p; i++) begin: fi

    bsg_two_fifo #(
      .width_p(width_p)
    ) fifo (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.v_i     (links_sif_in[i].v)
      ,.data_i  (links_sif_in[i].data)
      ,.ready_o (links_sif_out[i].ready_and_rev)

      ,.v_o     (fifo_v_lo[i])
      ,.data_o  (fifo_data_lo[i])
      ,.yumi_i  (fifo_yumi_li[i])
    );
      
    assign links_credit_o[i] = fifo_yumi_li[i];

  end

 
  // crossbar demux
  // [src][dest]
  logic [num_in_p-1:0][lg_num_in_lp-1:0] coords;
  logic [num_in_p-1:0][num_in_p-1:0] dest_select, dest_select_t;
 
  for (genvar i = 0; i < num_in_p; i++) begin: dx

    assign coords[i] = fifo_data_lo[i][0+:lg_num_in_lp];

    bsg_decode_with_v #(
      .num_out_p(num_in_p)
    ) demux0 (
      .v_i(fifo_v_lo[i])
      ,.i(coords[i])
      ,.o(dest_select[i]) 
    );
  end 
 

  // transpose
  bsg_transpose #(
    .width_p(num_in_p)
    ,.els_p(num_in_p)
  ) trans0 (
    .i(dest_select)
    ,.o(dest_select_t)
  );

 
 
  // crossbar round robin
  logic [num_in_p-1:0][num_in_p-1:0] rr_yumi_lo, rr_yumi_lo_t;

  for (genvar i = 0; i < num_in_p; i++) begin: rr

    bsg_arb_round_robin #(
      .width_p(num_in_p)
    ) arr (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.reqs_i(dest_select_t[i])
      ,.grants_o(rr_yumi_lo[i])
      ,.yumi_i(links_sif_out[i].v & links_sif_in[i].ready_and_rev)
    );

    bsg_mux_one_hot #(
      .width_p(width_p)
      ,.els_p(num_in_p)
    ) mx0 (
      .data_i(fifo_data_lo)
      ,.sel_one_hot_i(rr_yumi_lo[i])
      ,.data_o(links_sif_out[i].data)
    );

    assign links_sif_out[i].v = |dest_select_t[i];

  end


  // transpose
  bsg_transpose #(
    .width_p(num_in_p)
    ,.els_p(num_in_p)
  ) trans1 (
    .i(rr_yumi_lo)
    ,.o(rr_yumi_lo_t)
  );


  for (genvar i = 0; i < num_in_p; i++)
    assign fifo_yumi_li[i] = |rr_yumi_lo_t[i];



  // synopsys translate_off
  always_ff @ (negedge clk_i) begin
    if (~reset_i) begin
      for (integer i = 0; i < num_in_p; i++) begin
        if (fifo_v_lo[i]) begin
          assert(coords[i] < num_in_p)
            else $error("index out of range. num_in_p=%d, idx=%d", num_in_p, coords[i]);
        end
      end
    end
  end
  // synopsys translate_on



endmodule
