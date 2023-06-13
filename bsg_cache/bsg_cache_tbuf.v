/**
 *  bsg_cache_tbuf.sv
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

`include "bsg_defines.sv"
`include "bsg_cache.svh"

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
  logic el0_valid, el1_valid;

  // buffer queue
  bsg_cache_buffer_queue #(
    .width_p(addr_width_p+way_id_width_lp)
  ) q0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(v_i)
    ,.data_i({addr_i, way_i})

    ,.v_o(v_o)
    ,.data_o({addr_o, way_o})
    ,.yumi_i(yumi_i)

    ,.el0_valid_o(el0_valid)
    ,.el1_valid_o(el1_valid)
    ,.el0_snoop_o({el0_addr, el0_way})
    ,.el1_snoop_o({el1_addr, el1_way})

    ,.empty_o(empty_o)
    ,.full_o(full_o)
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


endmodule

`BSG_ABSTRACT_MODULE(bsg_cache_tbuf)
