/**
 *  testbench.v
 *
 */

`include "bsg_cache_pkt.vh"

module testbench();

  parameter num_instr_p = `NUM_INSTR_P;
  parameter addr_width_p = 32;
  parameter data_width_p = 32;
  parameter block_size_in_words_p = 8;
  parameter sets_p = 16;
  parameter ways_p = 2;

  parameter ring_width_p = addr_width_p + data_width_p + 5;
  parameter rom_addr_width_p = 32;

  localparam mem_els_lp = 2*ways_p*sets_p*block_size_in_words_p;
  localparam mask_width_lp = (data_width_p>>3);
  localparam byte_offset_width_lp = `BSG_SAFE_CLOG2(data_width_p>>3);
  localparam word_offset_width_lp = `BSG_SAFE_CLOG2(block_size_in_words_p);
  localparam block_offset_width_lp = (byte_offset_width_lp+word_offset_width_lp);
  localparam index_width_lp = `BSG_SAFE_CLOG2(sets_p);

  logic clk;
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(10)
  ) clockgen (
    .o(clk)
  );

  logic reset;
  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(8)
    ,.reset_cycles_hi_p(8)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);

  bsg_cache_pkt_s cache_pkt;
  logic v_li;
  logic ready_lo;

  logic [data_width_p-1:0] data_lo;
  logic v_lo;
  logic yumi_li;

  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo;
  logic dma_pkt_yumi_li;

  logic [data_width_p-1:0] dma_data_li;
  logic dma_data_v_li;
  logic dma_data_ready_lo;

  logic [data_width_p-1:0] dma_data_lo;
  logic dma_data_v_lo;
  logic dma_data_yumi_li;

  bsg_cache #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p) 
    ,.axe_trace_p(1)
  ) cache (
    .clk_i(clk)
    ,.reset_i(reset)
    
    ,.cache_pkt_i(cache_pkt)
    ,.v_i(v_li)
    ,.ready_o(ready_lo)

    ,.data_o(data_lo)
    ,.v_o(v_lo)
    ,.yumi_i(yumi_li)

    ,.dma_pkt_o(dma_pkt)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)
  
    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_o(dma_data_ready_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)

    ,.v_we_o()
  );

  assign yumi_li = v_lo;

  // mock_dma
  //
  bsg_nonsynth_dma_model #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.els_p(mem_els_lp)
  ) dma (
    .clk_i(clk)
    ,.reset_i(reset)
    
    ,.dma_pkt_i(dma_pkt)
    ,.dma_pkt_v_i(dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

    ,.dma_data_o(dma_data_li)
    ,.dma_data_v_o(dma_data_v_li)
    ,.dma_data_ready_i(dma_data_ready_lo)

    ,.dma_data_i(dma_data_lo)
    ,.dma_data_v_i(dma_data_v_lo)
    ,.dma_data_yumi_o(dma_data_yumi_li)
  );

  // trace replay
  //
  logic [ring_width_p-1:0] tr_data_lo;
  logic tr_yumi_li;
  logic [rom_addr_width_p-1:0] rom_addr;
  logic [ring_width_p+4-1:0] rom_data;

  bsg_fsb_node_trace_replay #(
    .ring_width_p(ring_width_p)
    ,.rom_addr_width_p(rom_addr_width_p)
  ) trace_replay (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.en_i(1'b1)

    ,.v_i(1'b0)
    ,.data_i('0)
    ,.ready_o()

    ,.v_o(v_li)
    ,.data_o(tr_data_lo)
    ,.yumi_i(tr_yumi_li)

    ,.rom_addr_o(rom_addr)
    ,.rom_data_i(rom_data)

    ,.done_o()
    ,.error_o()
  ); 

  assign tr_yumi_li = v_li & ready_lo;

  assign cache_pkt.sigext = 1'b0;
  assign cache_pkt.mask = {mask_width_lp{1'b1}};
  assign cache_pkt.opcode = bsg_cache_opcode_e'(tr_data_lo[data_width_p+addr_width_p+:5]);
  assign cache_pkt.addr = tr_data_lo[data_width_p+:addr_width_p];
  assign cache_pkt.data = tr_data_lo[0+:data_width_p];


  bsg_trace_rom #(
    .width_p(ring_width_p+4)
    ,.addr_width_p(rom_addr_width_p)
  ) trace_rom (
    .addr_i(rom_addr)
    ,.data_o(rom_data)
  );

  logic [31:0] count_r;
  always_ff @ (posedge clk) begin
    if (reset) begin
      count_r <= '0;
    end
    else begin
      if (v_lo) begin
        count_r <= count_r + 1;
      end
    end
  end

  initial begin
    wait((num_instr_p + ways_p*sets_p)== count_r);
    $finish;
  end

endmodule
