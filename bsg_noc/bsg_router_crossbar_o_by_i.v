/**
 *    bsg_router_crossbar_o_by_i.v
 *
 *    This module connects N inputs to M outputs with a crossbar network.
 */


`include "bsg_defines.v"

module bsg_router_crossbar_o_by_i
  #(parameter i_els_p=2
    , parameter o_els_p="inv"
    , parameter i_width_p="inv"

    , parameter logic [i_els_p-1:0] i_use_credits_p = {i_els_p{1'b0}}
    , parameter int i_fifo_els_p[i_els_p-1:0] = '{2,2}
    , parameter lg_o_els_lp = `BSG_SAFE_CLOG2(o_els_p)

    // drop_header_p drops the lower bits to select dest id from the datapath.
    // The drop header parameter can be optionally used to combine multiple crossbars
    // into a network and implement source routing.
    , parameter drop_header_p   = 0
    , parameter o_width_lp = i_width_p-(drop_header_p*lg_o_els_lp)
  )
  (
    input clk_i
    , input reset_i

    // fifo inputs
    , input [i_els_p-1:0] valid_i
    , input [i_els_p-1:0][i_width_p-1:0] data_i // lower bits = dest id.
    , output [i_els_p-1:0] credit_ready_and_o // this can be either credits or ready_and_i on inputs based on i_use_credits_p

    // crossbar output 
    , output [o_els_p-1:0] valid_o
    , output [o_els_p-1:0][o_width_lp-1:0] data_o
    , input [o_els_p-1:0] ready_and_i
  );


  // parameter checking
  initial begin
    // for now we leave this case unhandled
    // awaiting an actual use case so we can
    // determine whether the code is cleaner with
    // 0-bit or 1-bit source routing.
    assert(o_els_p > 1) else $error("o_els_p needs to be greater than 1.");
  end


  // input FIFO
  logic [i_els_p-1:0] fifo_ready_lo;
  logic [i_els_p-1:0] fifo_v_lo;
  logic [i_els_p-1:0][i_width_p-1:0] fifo_data_lo;
  logic [i_els_p-1:0] fifo_yumi_li;

  for (genvar i = 0; i < i_els_p; i++) begin: fifo
    bsg_fifo_1r1w_small #(
      .width_p(i_width_p)
      ,.els_p(i_fifo_els_p[i])
    ) fifo0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      
      ,.v_i(valid_i[i])
      ,.ready_o(fifo_ready_lo[i])
      ,.data_i(data_i[i])
    
      ,.v_o(fifo_v_lo[i])
      ,.data_o(fifo_data_lo[i])
      ,.yumi_i(fifo_yumi_li[i])
    );
  end

  // credit or ready interface
  for (genvar i = 0; i < i_els_p; i++) begin: intf
    if (i_use_credits_p[i]) begin: cr
      bsg_dff_reset #(
        .width_p(1)
        ,.reset_val_p(0)
      ) dff0 (
        .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.data_i(fifo_yumi_li[i])
        ,.data_o(credit_ready_and_o[i])
      );

      // synopsys translate_off
      always_ff @ (negedge clk_i) begin
        if (~reset_i & valid_i[i]) begin
          assert(fifo_ready_lo[i]) else $error("Trying to enque when there is no space in FIFO, while using credit interface. i =%d", i);
        end
      end
      // synopsys translate_on

    end
    else begin: rd
      assign credit_ready_and_o[i] = fifo_ready_lo[i];
    end
  end


  // crossbar ctrl
  logic [i_els_p-1:0][lg_o_els_lp-1:0] ctrl_sel_io_li;
  logic [i_els_p-1:0] ctrl_yumi_lo;
  logic [o_els_p-1:0][i_els_p-1:0] grants_lo;

  bsg_crossbar_control_basic_o_by_i #(
    .i_els_p(i_els_p)
    ,.o_els_p(o_els_p)
  ) ctrl0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.valid_i(fifo_v_lo)
    ,.sel_io_i(ctrl_sel_io_li)
    ,.yumi_o(fifo_yumi_li)

    ,.ready_and_i(ready_and_i)
    ,.valid_o(valid_o)
    ,.grants_oi_one_hot_o(grants_lo)
  );


  // lower bits encode the dest id.
  for (genvar i = 0; i < i_els_p; i++) begin
    assign ctrl_sel_io_li[i] = fifo_data_lo[i][0+:lg_o_els_lp];
  end


  // output mux
  logic [i_els_p-1:0][o_width_lp-1:0] odata;

  for (genvar i = 0; i < i_els_p; i++) begin
    if (drop_header_p) begin
      assign odata[i] = fifo_data_lo[i][i_width_p-1:lg_o_els_lp];
    end
    else begin
      assign odata[i] = fifo_data_lo[i];
    end
  end


  for (genvar i = 0; i < o_els_p; i++) begin: mux
    bsg_mux_one_hot #(
      .width_p(o_width_lp)
      ,.els_p(i_els_p)
    ) mux0 (
      .data_i(odata)
      ,.sel_one_hot_i(grants_lo[i])
      ,.data_o(data_o[i])
    );
  end


endmodule
