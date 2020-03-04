module vcache_blocking
  import bsg_cache_pkg::*;
  #(parameter id_p="inv"
    , parameter addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter sets_p="inv"
    , parameter ways_p="inv"
    , parameter dma_data_width_p="inv"

    //, parameter string rom_filename_lp = 
    , parameter dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
  )
  (
    input clk_i
    , input reset_i

    , output logic cache_v_o // cache request processed

    , output logic [dma_pkt_width_lp-1:0] dma_pkt_o
    , output logic dma_pkt_v_o
    , input dma_pkt_yumi_i

    , input [dma_data_width_p-1:0] dma_data_i
    , input dma_data_v_i
    , output logic dma_data_ready_o
  
    , output logic [dma_data_width_p-1:0] dma_data_o
    , output logic dma_data_v_o
    , input dma_data_yumi_i 

    , output time first_access_time_o
    , output integer load_count_o
    , output integer store_count_o
    , output logic done_o
  );


  // trace replay
  typedef struct packed {
    logic[1:0] op;
    logic [addr_width_p-1:0] addr;
    logic [data_width_p-1:0] data;
  } payload_s;
  

  localparam payload_width_lp = $bits(payload_s);
  localparam rom_addr_width_lp = 20;

  logic tr_v_lo;
  payload_s tr_data_lo;
  logic tr_yumi_li;

  logic [rom_addr_width_lp-1:0] rom_addr;
  logic [payload_width_lp+4-1:0] rom_data; 

  logic tr_done_lo;

  bsg_trace_replay #(
    .payload_width_p(payload_width_lp)
    ,.rom_addr_width_p(rom_addr_width_lp)
  ) tr0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.en_i(1'b1)

    ,.v_i(1'b0)
    ,.data_i('0)
    ,.ready_o()
    
    ,.v_o(tr_v_lo)
    ,.data_o(tr_data_lo)
    ,.yumi_i(tr_yumi_li)

    ,.rom_addr_o(rom_addr)
    ,.rom_data_i(rom_data)
 
    ,.done_o(tr_done_lo)
    ,.error_o()
  ); 

  // test rom
  bsg_nonsynth_test_rom #(
    .filename_p(`BSG_STRINGIFY(`TRACE))
    ,.data_width_p(payload_width_lp+4)
    ,.addr_width_p(rom_addr_width_lp)
  ) trom0 (
    .addr_i(rom_addr)
    ,.data_o(rom_data)
  );


  // the vcache
  `declare_bsg_cache_pkt_s(addr_width_p,data_width_p);
  bsg_cache_pkt_s cache_pkt;
  logic cache_pkt_v_li;
  logic cache_pkt_ready_lo;

  bsg_cache #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
    ,.dma_data_width_p(dma_data_width_p)
  ) vcache (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.cache_pkt_i(cache_pkt)
    ,.v_i(cache_pkt_v_li)
    ,.ready_o(cache_pkt_ready_lo)
    
    ,.data_o()
    ,.v_o(cache_v_o)
    ,.yumi_i(cache_v_o) // accept right away

    ,.dma_pkt_o(dma_pkt_o)
    ,.dma_pkt_v_o(dma_pkt_v_o)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_i)

    ,.dma_data_i(dma_data_i)
    ,.dma_data_v_i(dma_data_v_i)
    ,.dma_data_ready_o(dma_data_ready_o)

    ,.dma_data_o(dma_data_o)
    ,.dma_data_v_o(dma_data_v_o)
    ,.dma_data_yumi_i(dma_data_yumi_i)

    ,.v_we_o()
  );

  assign cache_pkt_v_li = tr_v_lo;
  assign tr_yumi_li = cache_pkt_ready_lo & tr_v_lo;

  always_comb begin
    case (tr_data_lo.op)
      2'b00: cache_pkt.opcode = LW;
      2'b01: cache_pkt.opcode = SW;
      2'b10: cache_pkt.opcode = TAGST;
      default: cache_pkt.opcode = LW;
    endcase
  end

  assign cache_pkt.mask = 4'b1111;
  assign cache_pkt.data = tr_data_lo.data;
  assign cache_pkt.addr = tr_data_lo.addr;

  // tracker
  integer sent_r;
  integer recv_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      sent_r <= 0;
      recv_r <= 0;
    end
    else begin
      if (tr_yumi_li) sent_r++;
      if (cache_v_o) recv_r++;
    end
  end

  assign done_o = (sent_r == recv_r) & tr_done_lo;

  logic first_access_sent_r;
  

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      first_access_sent_r <= 1'b0;
      load_count_o <= 0;
      store_count_o <= 0;
    end
    else begin
      if (cache_pkt_v_li & cache_pkt_ready_lo & (cache_pkt.opcode == LW | cache_pkt.opcode == SW)) begin
        if (cache_pkt.opcode == LW) load_count_o <= load_count_o + 1;
        if (cache_pkt.opcode == SW) store_count_o <= store_count_o + 1;
        if (~first_access_sent_r) begin
          first_access_sent_r <= 1'b1;
          first_access_time_o <= $time;
          $display("t=%0t, first access sent.", $time);
        end
      end

    end
  end
  

endmodule
