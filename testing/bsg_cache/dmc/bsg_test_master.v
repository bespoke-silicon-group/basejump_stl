module bsg_test_master
  import bsg_cache_pkg::*;
  #(parameter num_cache_p="inv"
    , parameter data_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter sets_p="inv"
    , parameter ways_p="inv"
  
    , localparam dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
    , localparam ring_width_lp=`bsg_cache_pkt_width(addr_width_p, data_width_p)
    , localparam rom_addr_width_lp=32
  )
  (
    input clk_i
    , input reset_i

    , output logic [num_cache_p-1:0][dma_pkt_width_lp-1:0] dma_pkt_o
    , output logic [num_cache_p-1:0] dma_pkt_v_o
    , input [num_cache_p-1:0] dma_pkt_yumi_i

    , input [num_cache_p-1:0][data_width_p-1:0] dma_data_i
    , input [num_cache_p-1:0] dma_data_v_i
    , output logic [num_cache_p-1:0] dma_data_ready_o

    , output logic [num_cache_p-1:0][data_width_p-1:0] dma_data_o
    , output logic [num_cache_p-1:0] dma_data_v_o
    , input [num_cache_p-1:0] dma_data_yumi_i

    , output logic done_o
  );


  //  trace replay
  //
  //  send trace: {opcode(5), addr, data}
  //  recv trace: {filler(5+32), data}
  //
  logic [num_cache_p-1:0] tr_v_li;
  logic [num_cache_p-1:0][ring_width_lp-1:0] tr_data_li;
  logic [num_cache_p-1:0] tr_ready_lo;

  logic [num_cache_p-1:0] tr_v_lo;
  logic [num_cache_p-1:0][ring_width_lp-1:0] tr_data_lo;
  logic [num_cache_p-1:0] tr_yumi_li;

  logic [num_cache_p-1:0][rom_addr_width_lp-1:0] rom_addr;
  logic [num_cache_p-1:0][ring_width_lp+4-1:0] rom_data;
  
  logic [num_cache_p-1:0] tr_done_lo;


  for (genvar i = 0; i < num_cache_p; i++) begin

    bsg_fsb_node_trace_replay #(
      .ring_width_p(ring_width_lp)
      ,.rom_addr_width_p(rom_addr_width_lp)
    ) tr (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i(1'b1)

      ,.v_i(tr_v_li[i])
      ,.data_i(tr_data_li[i])
      ,.ready_o(tr_ready_lo[i])

      ,.v_o(tr_v_lo[i])
      ,.data_o(tr_data_lo[i])
      ,.yumi_i(tr_yumi_li[i])
      
      ,.rom_addr_o(rom_addr[i])
      ,.rom_data_i(rom_data[i])
    
      ,.done_o(tr_done_lo[i])
      ,.error_o()
    );

    bsg_trace_rom #(
      .rom_addr_width_p(rom_addr_width_lp)
      ,.rom_data_width_p(ring_width_lp+4)
      ,.id_p(i)
    ) trace_rom (
      .rom_addr_i(rom_addr[i])
      ,.rom_data_o(rom_data[i])
    );

  end  

  assign done_o = &tr_done_lo;

  // cache
  //
  `declare_bsg_cache_pkt_s(addr_width_p,data_width_p);
  
  bsg_cache_pkt_s [num_cache_p-1:0] cache_pkt;
  logic [num_cache_p-1:0] cache_v_li;
  logic [num_cache_p-1:0] cache_ready_lo;

  logic [num_cache_p-1:0][data_width_p-1:0] cache_data_lo;
  logic [num_cache_p-1:0] cache_v_lo;
  logic [num_cache_p-1:0] cache_yumi_li;

  for (genvar i = 0; i < num_cache_p; i++) begin
  
    bsg_cache #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.block_size_in_words_p(block_size_in_words_p)
      ,.sets_p(sets_p)
      ,.ways_p(ways_p)
    ) cache (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.cache_pkt_i(cache_pkt[i])
      ,.v_i(cache_v_li[i])
      ,.ready_o(cache_ready_lo[i])

      ,.data_o(cache_data_lo[i])
      ,.v_o(cache_v_lo[i])
      ,.yumi_i(cache_yumi_li[i])
  
      ,.dma_pkt_o(dma_pkt_o[i])
      ,.dma_pkt_v_o(dma_pkt_v_o[i])
      ,.dma_pkt_yumi_i(dma_pkt_yumi_i[i])

      ,.dma_data_i(dma_data_i[i])
      ,.dma_data_v_i(dma_data_v_i[i])
      ,.dma_data_ready_o(dma_data_ready_o[i])

      ,.dma_data_o(dma_data_o[i])
      ,.dma_data_v_o(dma_data_v_o[i])
      ,.dma_data_yumi_i(dma_data_yumi_i[i])

      ,.v_we_o()
    );

    assign cache_pkt[i] = tr_data_lo[i];
    
    assign cache_v_li[i] = tr_v_lo[i];
    assign tr_yumi_li[i] = tr_v_lo[i] & cache_ready_lo[i];

    assign tr_data_li[i] = {{(ring_width_lp-data_width_p){1'b0}}, cache_data_lo[i]};
    assign tr_v_li[i] = cache_v_lo[i];
    assign cache_yumi_li[i] = cache_v_lo[i] & tr_ready_lo[i];

  end


endmodule
