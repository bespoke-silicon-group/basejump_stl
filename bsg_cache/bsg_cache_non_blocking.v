/**
 *    bsg_cache_non_blocking.v
 *
 *    Non-blocking cache
 *
 *    @author tommy
 *
 *
 */




module bsg_cache_non_blocking 
  import bsg_cache_non_blocking_pkg::*;
  #(parameter id_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter sets_p="inv"
    , parameter ways_p="inv"
    , parameter block_size_in_words_p="inv"
    
    , parameter cache_pkt_width_lp=`bsg_cache_non_blocking_pkt_width(id_width_p,addr_width_p,data_width_p)
    , parameter dma_pkt_width_lp=`bsg_cache_non_blocking_dma_pkt_width(addr_width_p)
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [cache_pkt_width_lp-1:0] cache_pkt_i
    , output logic ready_o 

    , output logic [data_width_p-1:0] data_o
    , output logic v_o
    , input yumi_i

    , output logic [dma_pkt_width_lp-1:0] dma_pkt_o
    , output logic dma_pkt_v_o
    , input dma_pkt_yumi_i

    , input [data_width_p-1:0] dma_data_i
    , input dma_data_v_i
    , output logic dma_data_ready_o

    , output logic [data_width_p-1:0] dma_data_o
    , output logic dma_data_v_o
    , input dma_data_yumi_i
  );


  // localparam
  //
  localparam lg_ways_lp = `BSG_SAFE_CLOG2(ways_p);
  localparam lg_sets_lp = `BSG_SAFE_CLOG2(sets_p);
  localparam lg_block_size_in_words_lp = `BSG_SAFE_CLOG2(block_size_in_words_p);
  localparam data_mask_width_lp = (data_width_p>>3);
  localparam lg_data_mask_width_lp = `BSG_SAFE_CLOG2(data_mask_width_lp);
  localparam tag_width_lp = (addr_width_p-lg_data_mask_width_lp-lg_block_size_in_words_lp-lg_sets_lp);


  // packet decoding
  //
  logic [lg_ways_lp-1:0] addr_way;
  logic [lg_sets_lp-1:0] addr_index;

  `declare_bsg_cache_non_blocking_pkt_s(id_width_p, addr_width_p, data_width_p);
  bsg_cache_non_blocking_pkt_s cache_pkt;
  assign cache_pkt = cache_pkt_i;

  bsg_cache_non_blocking_decode_s decode;
  bsg_cache_non_blocking_decode op_decode
  (
    .opcode_i(cache_pkt.opcode)
    ,.decode_o(decode)
  );

  assign addr_way
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp+:lg_ways_lp];
  assign addr_index
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];


  // tl_stage
  //
  `declare_bsg_cache_non_blocking_tl_stage_s(id_width_p,addr_width_p,data_width_p); 

  bsg_cache_non_blocking_tl_stage_s tl_n, tl_r;  

  bsg_dff_reset #(
    .width_p($bits(bsg_cache_non_blocking_tl_stage_s))
  ) tl_stage (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(tl_n)
    ,.data_o(tl_r)
  );



endmodule
