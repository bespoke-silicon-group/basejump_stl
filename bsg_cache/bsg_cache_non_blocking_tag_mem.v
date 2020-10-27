/**
 *    bsg_cache_non_blocking_tag_mem.v
 *
 *    @author tommy
 *
 */



`include "bsg_defines.v"

module bsg_cache_non_blocking_tag_mem 
  import bsg_cache_non_blocking_pkg::*;
  #(parameter sets_p="inv"
    , parameter ways_p="inv"
    , parameter tag_width_p="inv"
    , parameter data_width_p="inv"

    , parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    , parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)

    , parameter debug_p=0

    , parameter tag_mem_pkt_width_lp=
      `bsg_cache_non_blocking_tag_mem_pkt_width(ways_p,sets_p,data_width_p,tag_width_p)
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [tag_mem_pkt_width_lp-1:0] tag_mem_pkt_i

    , output logic [ways_p-1:0] valid_o
    , output logic [ways_p-1:0] lock_o
    , output logic [ways_p-1:0][tag_width_p-1:0] tag_o
  );


  // localparam
  //
  localparam tag_info_width_lp = `bsg_cache_non_blocking_tag_info_width(tag_width_p);


  // tag_mem pkt
  //
  `declare_bsg_cache_non_blocking_tag_mem_pkt_s(ways_p,sets_p,data_width_p,tag_width_p);
  
  bsg_cache_non_blocking_tag_mem_pkt_s tag_mem_pkt;
  
  assign tag_mem_pkt = tag_mem_pkt_i;

  // tag_mem
  //
  `declare_bsg_cache_non_blocking_tag_info_s(tag_width_p);

  logic w_li;
  bsg_cache_non_blocking_tag_info_s [ways_p-1:0] mask_li, data_li, data_lo;

  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p(tag_info_width_lp*ways_p)
    ,.els_p(sets_p)
    ,.latch_last_read_p(1)
  ) tag_mem0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.v_i(v_i)
    ,.w_i(w_li)

    ,.addr_i(tag_mem_pkt.index)
    ,.w_mask_i(mask_li)
    ,.data_i(data_li)
    ,.data_o(data_lo)
  );

  
  // input logic
  //
  logic [ways_p-1:0] way_decode;

  bsg_decode #(
    .num_out_p(ways_p)
  ) way_demux (
    .i(tag_mem_pkt.way_id)
    ,.o(way_decode)
  );


  always_comb begin

    w_li = 1'b0;
    data_li = '0;
    mask_li = '0;

    case (tag_mem_pkt.opcode)

      // read tags for given index.
      e_tag_read: begin
        w_li = 1'b0;
        data_li = '0;
        mask_li = '0;
      end
      
      // TAGST
      e_tag_store: begin 
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_mem_pkt.data[0+:tag_width_p];
          data_li[i].valid = tag_mem_pkt.data[data_width_p-1];
          data_li[i].lock = tag_mem_pkt.data[data_width_p-2];
          mask_li[i].tag = {tag_width_p{way_decode[i]}};
          mask_li[i].valid = way_decode[i];
          mask_li[i].lock = way_decode[i];
        end
      end

      // set tag and valid bit for the cache line, chosen by index and way_id.
      e_tag_set_tag: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_mem_pkt.tag;
          data_li[i].valid = 1'b1;
          data_li[i].lock = 1'b0;
          mask_li[i].tag = {tag_width_p{way_decode[i]}};
          mask_li[i].valid = way_decode[i];
          mask_li[i].lock = 1'b0;
        end
      end

      // set tag, valid bit, and lock bit for the chosen cache line.
      e_tag_set_tag_and_lock: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_mem_pkt.tag;
          data_li[i].valid = 1'b1;
          data_li[i].lock = 1'b1;
          mask_li[i].tag = {tag_width_p{way_decode[i]}};
          mask_li[i].valid = way_decode[i];
          mask_li[i].lock = way_decode[i];
        end
      end

      // set valid bit to zero for the chosen line.
      // also unlocks the line.
      e_tag_invalidate: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_mem_pkt.tag;
          data_li[i].valid = 1'b0;
          data_li[i].lock = 1'b0;
          mask_li[i].tag = {tag_width_p{1'b0}};
          mask_li[i].valid = way_decode[i];
          mask_li[i].lock = way_decode[i];
        end
      end
   
      // lock the chosen line. 
      e_tag_lock: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_mem_pkt.tag;
          data_li[i].valid = 1'b0;
          data_li[i].lock = 1'b1;
          mask_li[i].tag = {tag_width_p{1'b0}};
          mask_li[i].valid = 1'b0;
          mask_li[i].lock = way_decode[i];
        end
      end

      // unlock the chosen line.
      e_tag_unlock: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_mem_pkt.tag;
          data_li[i].valid = 1'b0;
          data_li[i].lock = 1'b0;
          mask_li[i].tag = {tag_width_p{1'b0}};
          mask_li[i].valid = 1'b0;
          mask_li[i].lock = way_decode[i];
        end
      end

      default: begin
        // this should never be used.
      end

    endcase
  end 



  // output logic
  //
  for (genvar i = 0; i < ways_p; i++) begin
    assign valid_o[i] = data_lo[i].valid;
    assign lock_o[i] = data_lo[i].lock;
    assign tag_o[i] = data_lo[i].tag;
  end


  // synopsys translate_off
  always_ff @ (negedge clk_i) begin

    if (v_i & debug_p)
      $display("[tag_mem] way=%x, index=%x, opcode=%0s, t=%t", tag_mem_pkt.way_id, tag_mem_pkt.index, tag_mem_pkt.opcode.name, $time);
    
  end


  // synopsys translate_on

endmodule
