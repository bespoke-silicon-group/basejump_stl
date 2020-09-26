/**
 *    bsg_cache_non_blocking_data_mem.v
 *
 *    data memory and peripheral circuits.
 *
 *    @author tommy
 *
 */


`include "bsg_defines.v"

module bsg_cache_non_blocking_data_mem
  import bsg_cache_non_blocking_pkg::*;
  #(parameter data_width_p="inv"
    , parameter ways_p="inv"
    , parameter sets_p="inv"
    , parameter block_size_in_words_p="inv"

    , parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    , parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    , parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p) 

    , parameter byte_sel_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)

    , parameter data_mem_pkt_width_lp=
      `bsg_cache_non_blocking_data_mem_pkt_width(ways_p,sets_p,block_size_in_words_p,data_width_p)
  ) 
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [data_mem_pkt_width_lp-1:0] data_mem_pkt_i

    , output logic [data_width_p-1:0] data_o
  );


  // localparam
  //
  localparam data_mask_width_lp = (data_width_p>>3);
  localparam data_bank_addr_width_lp = (lg_ways_lp+lg_sets_lp+lg_block_size_in_words_lp);
  localparam data_sel_mux_els_lp = `BSG_MIN(4,byte_sel_width_lp+1);
  localparam lg_data_sel_mux_els_lp = `BSG_SAFE_CLOG2(data_sel_mux_els_lp);


  // data_mem_pkt
  //
  `declare_bsg_cache_non_blocking_data_mem_pkt_s(ways_p,sets_p,block_size_in_words_p,data_width_p);

  bsg_cache_non_blocking_data_mem_pkt_s data_mem_pkt;

  assign data_mem_pkt = data_mem_pkt_i;


  // data_mem
  //
  logic [data_bank_addr_width_lp-1:0] addr_li;
  logic [data_width_p-1:0] data_li;
  logic [data_mask_width_lp-1:0] mask_li;
  logic [data_width_p-1:0] data_lo;

  assign addr_li = {data_mem_pkt.way_id, data_mem_pkt.addr};

  bsg_mem_1rw_sync_mask_write_byte #(
    .data_width_p(data_width_p)
    ,.els_p(block_size_in_words_p*sets_p*ways_p)
    ,.latch_last_read_p(1)
  ) data_mem (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i(v_i)
    ,.w_i(data_mem_pkt.write_not_read)
    ,.addr_i(addr_li)
    ,.data_i(data_li)
    ,.write_mask_i(mask_li)
    ,.data_o(data_lo)
  );


  // input logic (store)
  //
  logic [data_sel_mux_els_lp-1:0][data_width_p-1:0] input_mux_data_li;
  logic [data_sel_mux_els_lp-1:0][data_mask_width_lp-1:0] input_mux_mask_li;
  logic [data_width_p-1:0] input_mux_data_lo;
  logic [data_mask_width_lp-1:0] input_mux_mask_lo;

  bsg_mux #(
    .width_p(data_width_p)
    ,.els_p(data_sel_mux_els_lp)
  ) input_data_mux (
    .data_i(input_mux_data_li)
    ,.sel_i(data_mem_pkt.size_op[0+:lg_data_sel_mux_els_lp])
    ,.data_o(input_mux_data_lo)
  );

  bsg_mux #(
    .width_p(data_mask_width_lp)
    ,.els_p(data_sel_mux_els_lp)
  ) input_mask_mux (
    .data_i(input_mux_mask_li)
    ,.sel_i(data_mem_pkt.size_op[0+:lg_data_sel_mux_els_lp])
    ,.data_o(input_mux_mask_lo)
  );

  for (genvar i = 0; i < data_sel_mux_els_lp; i++) begin: input_sel

    // data
    assign input_mux_data_li[i] = {(data_width_p/(8*(2**i))){data_mem_pkt.data[0+:(8*(2**i))]}};

    // mask
    if (i == data_sel_mux_els_lp-1) begin: max_size

      assign input_mux_mask_li[i] = {data_mask_width_lp{1'b1}};

    end
    else begin: non_max_size

      logic [data_width_p/(8*(2**i))-1:0] decode_lo;

      bsg_decode #(
        .num_out_p(data_width_p/(8*(2**i)))
      ) dec (
        .i(data_mem_pkt.byte_sel[i+:`BSG_MAX(byte_sel_width_lp-i,1)])
        ,.o(decode_lo)
      );

      bsg_expand_bitmask #(
        .in_width_p(data_width_p/(8*(2**i)))
        ,.expand_p(2**i)
      ) exp (
        .i(decode_lo)
        ,.o(input_mux_mask_li[i])
      );

    end
  end

  assign data_li = data_mem_pkt.mask_op
    ? data_mem_pkt.data
    : input_mux_data_lo;

  assign mask_li =  data_mem_pkt.mask_op
    ? data_mem_pkt.mask
    : input_mux_mask_lo;


  // output logic (load)
  //
  wire load_en = v_i & ~data_mem_pkt.write_not_read;
  logic sigext_op_r;
  logic [1:0] size_op_r;
  logic [byte_sel_width_lp-1:0] byte_sel_r;

  bsg_dff_en #(
    .width_p(1+2+byte_sel_width_lp)
  ) op_dff (
    .clk_i(clk_i)
    ,.en_i(load_en)
    ,.data_i({data_mem_pkt.sigext_op, data_mem_pkt.size_op, data_mem_pkt.byte_sel})
    ,.data_o({sigext_op_r, size_op_r, byte_sel_r})
  );

  logic [data_sel_mux_els_lp-1:0][data_width_p-1:0] output_mux_data_li;

  bsg_mux #(
    .width_p(data_width_p)
    ,.els_p(data_sel_mux_els_lp)
  ) output_mux (
    .data_i(output_mux_data_li)
    ,.sel_i(size_op_r[0+:lg_data_sel_mux_els_lp])
    ,.data_o(data_o)
  ); 


  for (genvar i = 0; i < data_sel_mux_els_lp; i++) begin: output_sel
    if (i == data_sel_mux_els_lp-1) begin: max_size

      assign output_mux_data_li[i] = data_lo;

    end
    else begin: non_max_size
  
      logic [(8*(2**i))-1:0] selected_bytes;

      bsg_mux #(
        .width_p(8*(2**i))
        ,.els_p(data_width_p/(8*(2**i)))
      ) byte_mux (
        .data_i(data_lo)
        ,.sel_i(byte_sel_r[i+:`BSG_MAX(byte_sel_width_lp-i,1)])
        ,.data_o(selected_bytes)
      );

      assign output_mux_data_li[i] = 
        {{(data_width_p-(8*(2**i))){sigext_op_r & selected_bytes[(8*(2**i))-1]}}, selected_bytes};   
 
    end
  end  

endmodule
  
