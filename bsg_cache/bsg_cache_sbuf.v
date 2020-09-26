/**
 *  bsg_cache_sbuf.v
 *
 *  store (write) buffer.
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

module bsg_cache_sbuf
  import bsg_cache_pkg::*;
  #(parameter data_width_p="inv"
    ,parameter addr_width_p="inv"
    ,parameter ways_p="inv"

    ,localparam data_mask_width_lp=(data_width_p>>3)
    ,localparam sbuf_entry_width_lp=`bsg_cache_sbuf_entry_width(addr_width_p,data_width_p,ways_p)
  )
  (
    input clk_i
    ,input reset_i

    ,input [sbuf_entry_width_lp-1:0] sbuf_entry_i
    ,input v_i
  
    ,output logic [sbuf_entry_width_lp-1:0] sbuf_entry_o
    ,output logic v_o
    ,input logic yumi_i

    ,output logic empty_o
    ,output logic full_o

    ,input [addr_width_p-1:0] bypass_addr_i
    ,input bypass_v_i
    ,output logic [data_width_p-1:0] bypass_data_o
    ,output logic [data_mask_width_lp-1:0] bypass_mask_o
  );

  // localparam
  //
  localparam lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3);

  `declare_bsg_cache_sbuf_entry_s(addr_width_p, data_width_p, ways_p);
  bsg_cache_sbuf_entry_s el0, el1;


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

  // sbuf queues 
  // 
  bsg_cache_sbuf_entry_s sbuf_entry_in;
  assign sbuf_entry_in = sbuf_entry_i;
   
  bsg_cache_sbuf_queue #(
    .width_p(sbuf_entry_width_lp)
  ) sbq (
    .clk_i(clk_i)
    ,.data_i(sbuf_entry_in)
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o(el0)
    ,.el1_snoop_o(el1)
    ,.data_o(sbuf_entry_o)
  );



  // bypassing
  //
  logic tag_hit0, tag_hit0_n;
  logic tag_hit1, tag_hit1_n;
  logic tag_hit2, tag_hit2_n;
  logic [addr_width_p-lg_data_mask_width_lp-1:0] bypass_word_addr;

  assign bypass_word_addr = bypass_addr_i[addr_width_p-1:lg_data_mask_width_lp];
  assign tag_hit0_n = bypass_word_addr == el0.addr[addr_width_p-1:lg_data_mask_width_lp]; 
  assign tag_hit1_n = bypass_word_addr == el1.addr[addr_width_p-1:lg_data_mask_width_lp]; 
  assign tag_hit2_n = bypass_word_addr == sbuf_entry_in.addr[addr_width_p-1:lg_data_mask_width_lp]; 

  assign tag_hit0 = tag_hit0_n & el0_valid;
  assign tag_hit1 = tag_hit1_n & el1_valid;
  assign tag_hit2 = tag_hit2_n & v_i;

  logic [(data_width_p>>3)-1:0] tag_hit0x4;
  logic [(data_width_p>>3)-1:0] tag_hit1x4;
  logic [(data_width_p>>3)-1:0] tag_hit2x4;
  
  assign tag_hit0x4 = {(data_width_p>>3){tag_hit0}};
  assign tag_hit1x4 = {(data_width_p>>3){tag_hit1}};
  assign tag_hit2x4 = {(data_width_p>>3){tag_hit2}};
   
  logic [data_width_p-1:0] el0or1_data;
  logic [data_width_p-1:0] bypass_data_n;
  logic [(data_width_p>>3)-1:0] bypass_mask_n;

  assign bypass_mask_n = (tag_hit0x4 & el0.mask)
    | (tag_hit1x4 & el1.mask)
    | (tag_hit2x4 & sbuf_entry_in.mask);

  bsg_mux_segmented #(
    .segments_p(data_width_p>>3)
    ,.segment_width_p(8) 
  ) mux_segmented_merge0 (
    .data0_i(el1.data)
    ,.data1_i(el0.data)
    ,.sel_i(tag_hit0x4 & el0.mask)
    ,.data_o(el0or1_data)
  );

  bsg_mux_segmented #(
    .segments_p(data_width_p>>3)
    ,.segment_width_p(8) 
  ) mux_segmented_merge1 (
    .data0_i(el0or1_data)
    ,.data1_i(sbuf_entry_in.data)
    ,.sel_i(tag_hit2x4 & sbuf_entry_in.mask)
    ,.data_o(bypass_data_n)
  );

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      bypass_mask_o <= '0;
      bypass_data_o <= '0;
    end
    else begin
      if (bypass_v_i) begin
        bypass_mask_o <= bypass_mask_n;
        bypass_data_o <= bypass_data_n; 
      end
    end
  end

  // synopsys translate_off
  always_ff @ (negedge clk_i) begin
    if (~reset_i & num_els_r !== 2'bx) 
      assert(num_els_r != 3) else $error("store buffer cannot hold more than 2 entries.");

  end

  // synopsys translate_on

endmodule
