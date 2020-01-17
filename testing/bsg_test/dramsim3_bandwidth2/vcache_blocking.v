module vcache_blocking
  import bsg_cache_pkg::*;
  #(parameter id_p="inv"
    , parameter addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter sets_p="inv"
    , parameter ways_p="inv"
    , parameter dma_data_width_p="inv"
    , parameter num_subcache_p="inv"

    , parameter lg_num_subcache_lp=`BSG_SAFE_CLOG2(num_subcache_p)
    , parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_mask_width_lp)

    , parameter dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
  )
  (
    input clk_i
    , input reset_i

    , output logic [num_subcache_p-1:0][dma_pkt_width_lp-1:0] dma_pkt_o
    , output logic [num_subcache_p-1:0] dma_pkt_v_o
    , input [num_subcache_p-1:0] dma_pkt_yumi_i

    , input [num_subcache_p-1:0][dma_data_width_p-1:0] dma_data_i
    , input [num_subcache_p-1:0] dma_data_v_i
    , output logic [num_subcache_p-1:0] dma_data_ready_o
  
    , output logic [num_subcache_p-1:0][dma_data_width_p-1:0] dma_data_o
    , output logic [num_subcache_p-1:0] dma_data_v_o
    , input [num_subcache_p-1:0] dma_data_yumi_i 

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


  // sub-vcache request fifo
  `declare_bsg_cache_pkt_s(addr_width_p,data_width_p);
  bsg_cache_pkt_s fifo_data_li;
  assign fifo_data_li.mask = 4'b1111;
  assign fifo_data_li.data = tr_data_lo.data;

  always_comb begin
    case (tr_data_lo.op)
      2'b00: fifo_data_li.opcode = LW;
      2'b01: fifo_data_li.opcode = SW;
      2'b10: fifo_data_li.opcode = TAGST;
      default: fifo_data_li.opcode = TAGST;
    endcase
  end

  if (num_subcache_p == 1) begin
    assign fifo_data_li.addr = tr_data_lo.addr;
  end
  else begin
    assign fifo_data_li.addr = {
      {lg_num_subcache_lp{1'b0}},
      tr_data_lo.addr[addr_width_p-1:lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_num_subcache_lp],
      tr_data_lo.addr[0+:lg_data_mask_width_lp+lg_block_size_in_words_lp]
    };
  end

  logic [num_subcache_p-1:0] fifo_v_li;
  logic [num_subcache_p-1:0] fifo_ready_lo;

  logic [num_subcache_p-1:0] fifo_v_lo;
  bsg_cache_pkt_s [num_subcache_p-1:0] fifo_data_lo;
  logic [num_subcache_p-1:0] fifo_yumi_li;

  for (genvar i = 0; i < num_subcache_p; i++) begin
    bsg_fifo_1r1w_small #(
      .width_p($bits(bsg_cache_pkt_s))
      ,.els_p(block_size_in_words_p)
    ) fifo0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.v_i(fifo_v_li[i])
      ,.ready_o(fifo_ready_lo[i])
      ,.data_i(fifo_data_li)

      ,.v_o(fifo_v_lo[i])
      ,.data_o(fifo_data_lo[i])
      ,.yumi_i(fifo_yumi_li[i])
    );
  end

  logic [lg_num_subcache_lp-1:0] subcache_id;
  if (num_subcache_p == 1) begin
    assign subcache_id = 1'b0;
  end
  else begin
    assign subcache_id = tr_data_lo.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_num_subcache_lp];
  end

  bsg_decode_with_v #(
    .num_out_p(num_subcache_p)
  ) demux0 (
    .i(subcache_id)
    ,.v_i(tr_v_lo)
    ,.o(fifo_v_li)
  );

  assign tr_yumi_li = tr_v_lo & fifo_ready_lo[subcache_id];
  

  // the sub-vcache
  bsg_cache_pkt_s [num_subcache_p-1:0] cache_pkt;
  logic [num_subcache_p-1:0] cache_pkt_v_li;
  logic [num_subcache_p-1:0] cache_pkt_ready_lo;

  logic [num_subcache_p-1:0] cache_v_lo;
  logic [num_subcache_p-1:0] cache_yumi_li;

  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s [num_subcache_p-1:0] dma_pkt_lo;
  logic [num_subcache_p-1:0] dma_pkt_v_lo;
  logic [num_subcache_p-1:0] dma_pkt_yumi_li;

  for (genvar i = 0; i < num_subcache_p; i++) begin
    bsg_cache #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.block_size_in_words_p(block_size_in_words_p)
      ,.sets_p(sets_p)
      ,.ways_p(ways_p)
      ,.dma_data_width_p(dma_data_width_p)
    ) subvcache (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.cache_pkt_i(cache_pkt[i])
      ,.v_i(cache_pkt_v_li[i])
      ,.ready_o(cache_pkt_ready_lo[i])
    
      ,.data_o()
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
   
    assign cache_pkt_v_li[i] = fifo_v_lo[i];
    assign fifo_yumi_li[i] = cache_pkt_ready_lo[i] & fifo_v_lo[i];
    assign cache_pkt[i] = fifo_data_lo[i];

  end

  // output rr
  logic output_rr_v_lo;
  bsg_round_robin_n_to_1 #(
    .width_p(1)
    ,.num_in_p(num_subcache_p)
    ,.strict_p(0)
  ) output_rr0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.data_i('0)
    ,.v_i(cache_v_lo)
    ,.yumi_o(cache_yumi_li)

    ,.v_o(output_rr_v_lo)
    ,.data_o()
    ,.tag_o()
    ,.yumi_i(output_rr_v_lo)    // accept right away
  );


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
      if (output_rr_v_lo) recv_r++;
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
      if (tr_v_lo & tr_yumi_li & (fifo_data_li.opcode == LW | fifo_data_li.opcode == SW)) begin
        if (fifo_data_li.opcode == LW) load_count_o <= load_count_o + 1;
        if (fifo_data_li.opcode == SW) store_count_o <= store_count_o + 1;
        if (~first_access_sent_r) begin
          first_access_sent_r <= 1'b1;
          first_access_time_o <= $time;
          $display("t=%0t, first access sent.", $time);
        end
      end

    end
  end
  

endmodule
