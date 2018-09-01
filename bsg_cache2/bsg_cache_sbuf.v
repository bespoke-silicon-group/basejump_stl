/**
 *  bsg_cache_sbuf.v
 *
 *  el1 is head of the queue.
 *  el0 is the tail.
 *
 *  @author tommy
 */

module bsg_cache_sbuf
  #(parameter data_width_p="inv"
    ,parameter addr_width_p="inv"
  )
  (
    input clk_i
    ,input reset_i

    ,input [addr_width_p-1:0] addr_i
    ,input [data_width_p-1:0] data_i 
    ,input [(data_width_p>>3)-1:0] mask_i
    ,input set_i
    ,input v_i
  
    ,output logic [data_width_p-1:0] data_o
    ,output logic [addr_width_p-1:0] addr_o
    ,output logic set_o
    ,output logic v_o
    ,input logic yumi_i

    ,output logic empty_o

    ,input [addr_width_p-1:0] bypass_addr_i
    ,input bypass_v_i
    ,output logic [data_width_p-1:0] bypass_data_o
    ,output logic [(data_width_p>>3)-1:0] bypass_mask_o
  );

  logic [addr_width_p-1:0] el0_addr;
  logic [addr_width_p-1:0] el1_addr;
  logic [data_width_p-1:0] el0_data;
  logic [data_width_p-1:0] el1_data;
  logic [(data_width_p>>3)-1:0] el0_mask;
  logic [(data_width_p>>3)-1:0] el1_mask;

  logic [1:0] num_els_r;
  logic [addr_width_p-1:0] storebuf_addr;

  logic el0_valid;
  logic el1_valid;
  logic mux1_sel;
  logic mux0_sel;
  logic el0_enable;
  logic el1_enable;

  assign mux0_sel = el0_valid;
  assign mux1_sel = el1_valid;
  assign el0_enable = (v_o & yumi_i) | ~el0_valid;
  assign el1_enable = (v_o & yumi_i) | ~el1_valid;

  always_comb begin
    case (num_els_r) 
      0: begin
        v_o = v_i;
        empty_o = 1;
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
        el0_valid = 1;
        el1_valid = 1;
        el0_enable = v_i & yumi_i;
        el1_enable = yumi_i;
        mux0_sel = 1;
        mux1_sel = 1;
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

  // synopsys translate_off
  always_ff @ (negedge clk_i) begin
    assert(num_els_r != 3)
      else $error("DANGER !!! ABORT !!! num_els_r should NEVER be 3 !!!");
  end
  // sysnopsys translate_on

  // sbuf queues 
  // 
  bsg_cache_sbuf_queue #(.width_p(data_width_p>>3)) wbq_mask (
    .clk_i(clk_i)
    ,.data_i(mask_i)
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o(el0_mask)
    ,.el1_snoop_o(el1_mask)
    ,.data_o(mask_o)
  );

  bsg_cache_sbuf_queue #(.width_p(data_width_p)) wbq_data (
    .clk_i(clk_i)
    ,.data_i(data_i)
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o(el0_data)
    ,.el1_snoop_o(el1_data)
    ,.data_o(data_o)
  );

  bsg_cache_sbuf_queue #(.width_p(addr_width_p)) wbq_addr (
    .clk_i(clk_i)
    ,.data_i(addr_i)
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o(el0_addr)
    ,.el1_snoop_o(el1_addr)
    ,.data_o(addr_o)
  );

  bsg_cache_sbuf_queue #(.width_p(1)) wbq_set (
    .clk_i(clk_i)
    ,.data_i(set_i)
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o()
    ,.el1_snoop_o()
    ,.data_o(set_o)
  );


  // bypassing
  //
  logic tag_hit0, tag_hit0_n;
  logic tag_hit1, tag_hit1_n;
  logic tag_hit2, tag_hit2_n;
  logic [addr_width_p-`BSG_SAFE_CLOG2(data_width_p>>3)-1:0] bypass_word_addr;

  assign bypass_word_addr = bypass_addr_i[addr_width_p-1:`BSG_SAFE_CLOG2(data_width_p>>3)];
  assign tag_hit0_n = (bypass_word_addr == el0_addr[addr_width_p-1:`BSG_SAFE_CLOG2(data_width_p>>3)]); 
  assign tag_hit1_n = (bypass_word_addr == el1_addr[addr_width_p-1:`BSG_SAFE_CLOG2(data_width_p>>3)]); 
  assign tag_hit2_n = (bypass_word_addr == addr_i[addr_width_p-1:`BSG_SAFE_CLOG2(data_width_p>>3)]); 

  assign tag_hit0 = tag_hit0_n & el0_valid;
  assign tag_hit1 = tag_hit1_n & el1_valid;
  assign tag_hit2 = tag_hit2_n & v_i;

  logic [(data_width_p>>3)-1:0] tag_hit0x4;
  logic [(data_width_p>>3)-1:0] tag_hit1x4;
  logic [(data_width_p>>3)-1:0] tag_hit2x4;
  
  assign tag_hit0x4 = {(data_width_p>>3)'{tag_hit0}};
  assign tag_hit1x4 = {(data_width_p>>3)'{tag_hit1}};
  assign tag_hit2x4 = {(data_width_p>>3)'{tag_hit2}};
   
  logic [data_width_p-1:0] el0or1_data;
  logic [data-width_p-1:0] bypass_data_n;
  logic [(data_width_p>>3)-1:0] bypass_mask_n;

  assign storebuf_bypass_valid_n = (tag_hit0x4 & el0_mask)
    | (tag_hit1x4 & el1_mask)
    | (tag_hit2x4 & mask_i);

  bsg_mux_segmented #(
    .segments_p(data_width_p>>3)
    ,.segment_width_p(8) 
  ) mux_segmented_merge0 (
    .data0_i(el1_data)
    ,.data1_i(el0_data)
    ,.sel_i(tag_hit0x4 & el0_mask)
    ,.data_o(el0or1_data)
  );

  bsg_mux_segmented #(
    .segments_p(data_width_p>>3)
    ,.segment_width_p(8) 
  ) mux_segmented_merge1 (
    .data0_i(el0or1_data)
    ,.data1_i(data_i)
    ,.sel_i(tag_hit2x4 & mask_i)
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

endmodule
