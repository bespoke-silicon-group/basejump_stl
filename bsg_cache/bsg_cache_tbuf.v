/**
 *  bsg_cache_tbuf.v
 *
 *  track (write) buffer.
 *
 *  input interface is valid-only.
 *  output interface is valid-yumi;
 *  
 *  el1 is head of the queue.
 *  el0 is the tail.
 *
 *  @author tommy
 */

`include "bsg_defines.v"
`include "bsg_cache.vh"

module bsg_cache_tbuf
  import bsg_cache_pkg::*;
  #(parameter `BSG_INV_PARAM(data_width_p)
    ,parameter `BSG_INV_PARAM(addr_width_p)
    ,parameter `BSG_INV_PARAM(ways_p)

    ,localparam way_id_width_lp=`BSG_SAFE_CLOG2(ways_p)
  )
  (
    input clk_i
    ,input reset_i

    ,input [addr_width_p-1:0] addr_i
    ,input [way_id_width_lp-1:0] way_i
    ,input v_i
  
    ,output logic [addr_width_p-1:0] addr_o
    ,output logic [way_id_width_lp-1:0] way_o
    ,output logic v_o
    ,input logic yumi_i

    ,output logic empty_o
    ,output logic full_o

    ,input [addr_width_p-1:0] bypass_addr_i
    ,input bypass_v_i
    ,output logic bypass_track_o
  );

  // localparam
  //
  localparam lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3);

  logic [addr_width_p-1:0] el0_addr, el1_addr;
  logic [way_id_width_lp-1:0] el0_way, el1_way;

  logic [1:0] num_els_r;

  logic el0_valid;
  logic el1_valid;
  logic mux1_sel;
  logic mux0_sel;
  logic el0_enable;
  logic el1_enable;

  always_comb begin
    case (num_els_r) 
      0: begin
        v_o = v_i;
        empty_o = 1;
        full_o = 0;
        el0_valid = 0;
        el1_valid = 0;
        el0_enable = 0;
        el1_enable = v_i & ~yumi_i;
        mux0_sel = 0;
        mux1_sel = 0;
      end
      
      1: begin
        v_o = 1;
        empty_o = 0;
        full_o = 0;
        el0_valid = 0;
        el1_valid = 1;
        el0_enable = v_i & ~yumi_i;
        el1_enable = v_i & yumi_i;
        mux0_sel = 0;
        mux1_sel = 1;
      end

      2: begin
        v_o = 1;
        empty_o = 0;
        full_o = 1;
        el0_valid = 1;
        el1_valid = 1;
        el0_enable = v_i & yumi_i;
        el1_enable = yumi_i;
        mux0_sel = 1;
        mux1_sel = 1;
      end
      default: begin
        // this would never happen.
        v_o = 0;
        empty_o = 0;
        full_o = 0;
        el0_valid = 0;
        el1_valid = 0;
        el0_enable = 0;
        el1_enable = 0;
        mux0_sel = 0;
        mux1_sel = 0;
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

  // tbuf queues 
  // 
  bsg_cache_sbuf_queue #(
    .width_p(addr_width_p+way_id_width_lp)
  ) sbq (
    .clk_i(clk_i)
    ,.data_i({way_i, addr_i})
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o({el0_way, el0_addr})
    ,.el1_snoop_o({el1_way, el1_addr})
    ,.data_o({way_o, addr_o})
  );



  // bypassing
  //
  logic tag_hit0, tag_hit0_n;
  logic tag_hit1, tag_hit1_n;
  logic tag_hit2, tag_hit2_n;
  logic bypass_track_n;
  logic [addr_width_p-lg_data_mask_width_lp-1:0] bypass_word_addr;

  assign bypass_word_addr = bypass_addr_i[addr_width_p-1:lg_data_mask_width_lp];
  assign tag_hit0_n = bypass_word_addr == el0_addr[addr_width_p-1:lg_data_mask_width_lp]; 
  assign tag_hit1_n = bypass_word_addr == el1_addr[addr_width_p-1:lg_data_mask_width_lp]; 
  assign tag_hit2_n = bypass_word_addr == addr_i[addr_width_p-1:lg_data_mask_width_lp]; 

  assign tag_hit0 = tag_hit0_n & el0_valid;
  assign tag_hit1 = tag_hit1_n & el1_valid;
  assign tag_hit2 = tag_hit2_n & v_i;

  assign bypass_track_n = (tag_hit0 | tag_hit1 | tag_hit2);

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      bypass_track_o <= '0;
    end
    else if (bypass_v_i) begin
      bypass_track_o <= bypass_track_n;
    end
  end

  // synopsys translate_off
  always_ff @ (negedge clk_i) begin
    if (~reset_i & num_els_r !== 2'bx) 
      assert(num_els_r != 3) else $error("track buffer cannot hold more than 2 entries.");

  end
  // synopsys translate_on

endmodule

`BSG_ABSTRACT_MODULE(bsg_cache_tbuf)
