/**
 *    bsg_cache_non_blocking_tag_mem.v
 *
 *    @author tommy
 *
 */



module bsg_cache_non_blocking_tag_mem 
  import bsg_cache_non_blocking_pkg::*;
  #(parameter sets_p="inv"
    , parameter ways_p="inv"
    , parameter tag_width_p="inv"
    , parameter data_width_p="inv"

    , parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    , parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [lg_ways_lp-1:0] way_i
    , input [lg_sets_lp-1:0] addr_i
    , input [data_width_p-1:0] data_i
    , input [tag_width_p-1:0] tag_i
    , input bsg_cache_non_blocking_tag_op_e tag_op_i

    , output logic [ways_p-1:0] valid_o
    , output logic [ways_p-1:0] lock_o
    , output logic [ways_p-1:0][tag_width_p-1:0] tag_o
  );


  // localparam
  //
  localparam tag_info_width_lp = `bsg_cache_non_blocking_tag_info_width(tag_width_p);


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

    ,.addr_i(addr_i)
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
    .i(way_i)
    ,.o(way_decode)
  );


  always_comb begin

    w_li = 1'b0;
    data_li = '0;
    mask_li = '0;

    case (tag_op_i)

      e_tag_read: begin
        w_li = 1'b0;
        data_li = '0;
        mask_li = '0;
      end
      
      // TAGST
      e_tag_store: begin 
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = data_i[0+:tag_width_p];
          data_li[i].valid = data_i[data_width_p-1];
          data_li[i].lock = data_i[tag_width_p-2];
          mask_li[i].tag = {tag_width_p{way_decode[i]}};
          mask_li[i].valid = way_decode[i];
          mask_li[i].lock = way_decode[i];
        end
      end

      e_tag_set_tag: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_i;
          data_li[i].valid = 1'b1;
          data_li[i].lock = 1'b0;
          mask_li[i].tag = {tag_width_p{way_decode[i]}};
          mask_li[i].valid = way_decode[i];
          mask_li[i].lock = 1'b0;
        end
      end

      e_tag_set_tag_and_lock: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_i;
          data_li[i].valid = 1'b1;
          data_li[i].lock = 1'b1;
          mask_li[i].tag = {tag_width_p{way_decode[i]}};
          mask_li[i].valid = way_decode[i];
          mask_li[i].lock = way_decode[i];
        end
      end

      e_tag_invalidate: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_i;
          data_li[i].valid = 1'b0;
          data_li[i].lock = 1'b0;
          mask_li[i].tag = {tag_width_p{1'b0}};
          mask_li[i].valid = way_decode[i];
          mask_li[i].lock = way_decode[i];
        end
      end
    
      e_tag_lock: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_i;
          data_li[i].valid = 1'b0;
          data_li[i].lock = 1'b1;
          mask_li[i].tag = {tag_width_p{1'b0}};
          mask_li[i].valid = 1'b0;
          mask_li[i].lock = way_decode[i];
        end
      end

      e_tag_unlock: begin
        w_li = 1'b1;
        for (integer i = 0 ; i < ways_p; i++) begin
          data_li[i].tag = tag_i;
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


endmodule
