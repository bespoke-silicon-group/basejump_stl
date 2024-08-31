/**
 *  bsg_cache_buffer_queue.sv
 *
 *  Two element buffer queue.
 *
 *  input interface is valid-only.
 *  output interface is valid-yumi;
 *  
 *  el1 is head of the queue.
 *  el0 is the tail.
 *
 */

`include "bsg_defines.sv"

module bsg_cache_buffer_queue
  #(parameter `BSG_INV_PARAM(width_p))
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [width_p-1:0] data_i

    , output logic v_o
    , output logic [width_p-1:0] data_o
    , input yumi_i

    , output logic el0_valid_o
    , output logic el1_valid_o
    , output logic [width_p-1:0] el0_snoop_o
    , output logic [width_p-1:0] el1_snoop_o

    , output logic empty_o
    , output logic full_o
  );

  // CTRL logic
  logic [1:0] num_els_r;

  logic mux1_sel;
  logic mux0_sel;
  logic el0_enable;
  logic el1_enable;

  always_comb begin
    case (num_els_r) 
      2'b00: begin
        v_o = v_i;
        empty_o = 1'b1;
        full_o = 1'b0;
        el0_valid_o = 1'b0;
        el1_valid_o = 1'b0;
        el0_enable = 1'b0;
        el1_enable = v_i & ~yumi_i;
        mux0_sel = 1'b0;
        mux1_sel = 1'b0;
      end
      
      2'b01: begin
        v_o = 1'b1;
        empty_o = 1'b0;
        full_o = 1'b0;
        el0_valid_o = 1'b0;
        el1_valid_o = 1'b1;
        el0_enable = v_i & ~yumi_i;
        el1_enable = v_i & yumi_i;
        mux0_sel = 1'b0;
        mux1_sel = 1'b1;
      end

      2'b10: begin
        v_o = 1'b1;
        empty_o = 1'b0;
        full_o = 1'b1;
        el0_valid_o = 1'b1;
        el1_valid_o = 1'b1;
        el0_enable = v_i & yumi_i;
        el1_enable = yumi_i;
        mux0_sel = 1'b1;
        mux1_sel = 1'b1;
      end

      default: begin
        // this would never happen.
        v_o = 1'b0;
        empty_o = 1'b0;
        full_o = 1'b0;
        el0_valid_o = 1'b0;
        el1_valid_o = 1'b0;
        el0_enable = 1'b0;
        el1_enable = 1'b0;
        mux0_sel = 1'b0;
        mux1_sel = 1'b0;
      end
    endcase
  end

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      num_els_r <= 2'b0;
    end
    else begin
      num_els_r <= num_els_r + v_i - (v_o & yumi_i);
    end
  end


  // Data Flops
  logic [width_p-1:0] el0_r, el1_r;

  always_ff @ (posedge clk_i) begin
    if (el0_enable) begin
      el0_r <= data_i;
    end

    if (el1_enable) begin
      el1_r <= mux0_sel ? el0_r : data_i;
    end
  end

  assign data_o = mux1_sel ? el1_r : data_i;
  assign el0_snoop_o = el0_r;
  assign el1_snoop_o = el1_r;



`ifndef BSG_HIDE_FROM_SYNTHESIS
  always_ff @ (negedge clk_i) begin
    if (~reset_i & num_els_r !== 2'bx) 
      assert(num_els_r != 3) else $error("bsg_cache_buffer_queue cannot hold more than 2 entries.");

  end
`endif


endmodule


`BSG_ABSTRACT_MODULE(bsg_cache_buffer_queue)
