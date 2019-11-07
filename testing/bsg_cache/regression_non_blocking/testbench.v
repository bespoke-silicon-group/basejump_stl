/**
 *  testbench.v
 */


module testbench();
  import bsg_cache_non_blocking_pkg::*;

  // parameters
  //
  parameter id_width_p = 30;
  parameter addr_width_p = 32;
  parameter data_width_p = 32;
  parameter block_size_in_words_p = 8;
  parameter sets_p = 128;
  parameter ways_p = 8;
  parameter miss_fifo_els_p = `MISS_FIFO_ELS_P;
  parameter data_mask_width_lp=(data_width_p>>3);
  parameter mem_size_p = 2**15;

  parameter dma_read_delay_p  = `DMA_READ_DELAY_P;
  parameter dma_write_delay_p = `DMA_WRITE_DELAY_P;
  parameter dma_data_delay_p  = `DMA_DATA_DELAY_P;
  parameter dma_req_delay_p   = `DMA_REQ_DELAY_P;
  parameter yumi_max_delay_p  = `YUMI_MAX_DELAY_P;
  parameter yumi_min_delay_p  = `YUMI_MIN_DELAY_P;


  integer status;
  integer wave;

  initial begin
    status = $value$plusargs("wave=%d",wave);
    if (wave) $vcdpluson;
  end

  // clock and reset
  //
  logic clk;
  logic reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(100)
  ) clock_gen (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(8)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  // non-blocking cache
  //
  `declare_bsg_cache_non_blocking_pkt_s(id_width_p,addr_width_p,data_width_p);
  bsg_cache_non_blocking_pkt_s cache_pkt;

  logic cache_v_li;
  logic cache_ready_lo;

  logic [id_width_p-1:0] cache_id_lo;
  logic [data_width_p-1:0] cache_data_lo;
  logic cache_v_lo;
  logic cache_yumi_li;

  `declare_bsg_cache_non_blocking_dma_pkt_s(addr_width_p);
  bsg_cache_non_blocking_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo;
  logic dma_pkt_yumi_li;

  logic [data_width_p-1:0] dma_data_li;
  logic dma_data_v_li;
  logic dma_data_ready_lo;

  logic [data_width_p-1:0] dma_data_lo;
  logic dma_data_v_lo;
  logic dma_data_yumi_li;

  bsg_cache_non_blocking #(
    .id_width_p(id_width_p)
    ,.addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
    ,.miss_fifo_els_p(miss_fifo_els_p)
  ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.cache_pkt_i(cache_pkt)
    ,.v_i(cache_v_li)
    ,.ready_o(cache_ready_lo)

    ,.data_o(cache_data_lo)
    ,.id_o(cache_id_lo)
    ,.v_o(cache_v_lo)
    ,.yumi_i(cache_yumi_li)

    ,.dma_pkt_o(dma_pkt)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)
  
    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_o(dma_data_ready_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)
  );


  // random yumi generator
  //
  integer counter_r;
 
  
  always_ff @ (posedge clk) begin
    if (reset) begin
      counter_r <= 0;
    end
    else begin
      if (cache_v_lo) begin
        if (counter_r == 0)
          counter_r <= $urandom_range(yumi_max_delay_p,yumi_min_delay_p);
        else
          counter_r <= counter_r - 1;
      end
    end
  end

  assign cache_yumi_li = cache_v_lo & (counter_r == 0);
   

  // dma model
  //
  bsg_nonsynth_non_blocking_dma_model #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.els_p(4*ways_p*sets_p*block_size_in_words_p)
    ,.read_delay_p(dma_read_delay_p)
    ,.write_delay_p(dma_write_delay_p)
    ,.dma_data_delay_p(dma_data_delay_p)
    ,.dma_req_delay_p(dma_req_delay_p)
  ) dma_model (
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
  localparam rom_addr_width_lp = 26; 
  localparam ring_width_lp =
    `bsg_cache_non_blocking_pkt_width(id_width_p,addr_width_p,data_width_p);

  logic [rom_addr_width_lp-1:0] trace_rom_addr;
  logic [ring_width_lp+4-1:0] trace_rom_data;
  
  logic tr_v_lo;
  logic [ring_width_lp-1:0] tr_data_lo;
  logic tr_yumi_li;
  logic done;

  bsg_fsb_node_trace_replay #(
    .ring_width_p(ring_width_lp)
    ,.rom_addr_width_p(rom_addr_width_lp)
  ) trace_replay (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.en_i(1'b1)

    ,.v_i(1'b0)
    ,.data_i('0)
    ,.ready_o()

    ,.v_o(tr_v_lo)
    ,.data_o(tr_data_lo)
    ,.yumi_i(tr_yumi_li)

    ,.rom_addr_o(trace_rom_addr)
    ,.rom_data_i(trace_rom_data)

    ,.done_o(done)
    ,.error_o()
  );

  bsg_nonsynth_test_rom #(
    .filename_p("trace.tr")
    ,.data_width_p(ring_width_lp+4)
    ,.addr_width_p(rom_addr_width_lp)
  ) test_rom (
    .addr_i(trace_rom_addr)
    ,.data_o(trace_rom_data)
  );

  assign cache_pkt = tr_data_lo;
  assign cache_v_li = tr_v_lo;
  assign tr_yumi_li = tr_v_lo & cache_ready_lo;

  // consistency checking
  logic [data_width_p-1:0] shadow_mem [mem_size_p-1:0];    // indexed by addr.
  logic [data_width_p-1:0] result [*]; // indexed by id.

  logic [addr_width_p-1:0] cache_pkt_word_addr;
  assign cache_pkt_word_addr = cache_pkt.addr[addr_width_p-1:2];

  // store logic
  logic [data_width_p-1:0] store_data;
  logic [data_mask_width_lp-1:0] store_mask;

  always_comb begin
    case (cache_pkt.opcode)
      SW: begin
        store_data = cache_pkt.data;
        store_mask = 4'b1111;
      end
      SH: begin
        store_data = {2{cache_pkt.data[15:0]}};
        store_mask = {
          {2{ cache_pkt.addr[1]}},
          {2{~cache_pkt.addr[1]}}
        };
      end
      SB: begin
        store_data = {4{cache_pkt.data[7:0]}};
        store_mask = {
           cache_pkt.addr[1] &  cache_pkt.addr[0],
           cache_pkt.addr[1] & ~cache_pkt.addr[0],
          ~cache_pkt.addr[1] &  cache_pkt.addr[0],
          ~cache_pkt.addr[1] & ~cache_pkt.addr[0]
        };
      end
      SM: begin
        store_data = cache_pkt.data;
        store_mask = cache_pkt.mask;
      end
      default: begin
        store_data = '0;
        store_mask = '0;
      end
    endcase
  end

  // load logic
  logic [data_width_p-1:0] load_data, load_data_final;
  logic [7:0] byte_sel;
  logic [15:0] half_sel;

  assign load_data = shadow_mem[cache_pkt_word_addr];

  bsg_mux #(
    .els_p(4)
    ,.width_p(8)
  ) byte_mux (
    .data_i(load_data)
    ,.sel_i(cache_pkt.addr[1:0])
    ,.data_o(byte_sel)
  );

  bsg_mux #(
    .els_p(2)
    ,.width_p(16)
  ) half_mux (
    .data_i(load_data)
    ,.sel_i(cache_pkt.addr[1])
    ,.data_o(half_sel)
  );

  always_comb begin
    case (cache_pkt.opcode)
      LW: load_data_final = load_data;
      LH: load_data_final = {{16{half_sel[15]}}, half_sel};
      LB: load_data_final = {{24{byte_sel[7]}}, byte_sel};
      LHU: load_data_final = {{16{1'b0}}, half_sel};
      LBU: load_data_final = {{24{1'b0}}, byte_sel};
      default: load_data_final = '0;
    endcase
  end


  always_ff @ (posedge clk) begin
    if (reset) begin
      for (integer i = 0; i < mem_size_p; i++)
        shadow_mem[i] <= '0;
    end
    else begin 
      if (cache_v_li & cache_ready_lo) begin
        case (cache_pkt.opcode)
          TAGST, TAGFL, AFL, AFLINV: begin
            result[cache_pkt.id] = '0;
          end

          SB, SH, SW, SM: begin
            result[cache_pkt.id] = '0;
            for (integer i = 0; i < data_mask_width_lp; i++)
              if (store_mask[i])
                shadow_mem[cache_pkt_word_addr][8*i+:8] <= store_data[8*i+:8];
          end
      
          LW, LH, LB, LHU, LBU: begin
            result[cache_pkt.id] = load_data_final;
          end
        endcase
      end
    end


    if (~reset & cache_v_lo & cache_yumi_li) begin
      $display("id=%d, data=%x", cache_id_lo, cache_data_lo);
      assert(result[cache_id_lo] == cache_data_lo)
        else $fatal("[BSG_FATAL] Output does not match expected result. Id= %d, Expected: %x. Actual: %x",
              cache_id_lo, result[cache_id_lo], cache_data_lo);
    end

  end


  // waiting for all responses to be received.
  //
  integer sent_r, recv_r;

  always_ff @ (posedge clk) begin
    if (reset) begin
      sent_r <= '0;
      recv_r <= '0;
    end
    else begin

      if (cache_v_li & cache_ready_lo)
        sent_r <= sent_r + 1;

      if (cache_v_lo & cache_yumi_li)
        recv_r <= recv_r + 1;

    end
  end



  initial begin
    wait(done & (sent_r == recv_r));
    $display("[BSG_FINISH] Test Successful.");
    //for (integer i = 0; i < 1000000; i++)
    //  @(posedge clk);
    #500;
    $finish;
  end

endmodule
