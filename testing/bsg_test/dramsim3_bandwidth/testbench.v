`include "bsg_nonsynth_dramsim3.svh"


`define dram_pkg bsg_dramsim3_hbm2_8gb_x128_pkg

module testbench();

  bit clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg0 (
    .o(clk)
  );


  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(10)
  ) rg0 (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );


  import `dram_pkg::*;

  // trace replay
  localparam write_data_width_lp = 32; // we only write 32-bit data to save space.
  localparam payload_width_p = `dram_pkg::channel_addr_width_p + 1 + write_data_width_lp;
  localparam rom_addr_width_p = 20;

  typedef struct packed {
    logic write_not_read;
    logic [`dram_pkg::channel_addr_width_p-1:0] ch_addr;
    logic [write_data_width_lp-1:0] data;
  } trace_s;

  trace_s tr_data_lo;
  logic tr_v_lo;
  logic tr_yumi_li;

  logic [rom_addr_width_p-1:0] rom_addr;
  logic [payload_width_p+4-1:0] rom_data; 

  logic tr_done_lo;

  bsg_trace_replay #(
    .payload_width_p(payload_width_p)
    ,.rom_addr_width_p(rom_addr_width_p)
  ) tr0 (
    .clk_i(clk)
    ,.reset_i(reset)
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

  bsg_nonsynth_test_rom #(
    .filename_p("trace.tr")
    ,.data_width_p(payload_width_p+4)
    ,.addr_width_p(rom_addr_width_p)
  ) trom0 (
    .addr_i(rom_addr)
    ,.data_o(rom_data)
  );


  // dramsim3
  //
  logic [num_channels_p-1:0] dramsim3_v_li;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] dramsim3_ch_addr_li;
  logic [num_channels_p-1:0] dramsim3_yumi_lo;
  logic [num_channels_p-1:0] dramsim3_write_not_read_li;

  logic [num_channels_p-1:0] dramsim3_data_v_li;
  logic [num_channels_p-1:0] dramsim3_data_yumi_lo;
  logic [num_channels_p-1:0][data_width_p-1:0] dramsim3_data_li;

  logic [num_channels_p-1:0] dramsim3_data_v_lo;
  logic [num_channels_p-1:0][data_width_p-1:0] dramsim3_data_lo;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] dramsim3_read_done_ch_addr_lo;
  logic [num_channels_p-1:0] dramsim3_write_done_lo;

  bsg_nonsynth_dramsim3 #(
    .channel_addr_width_p(`dram_pkg::channel_addr_width_p)
    ,.data_width_p(`dram_pkg::data_width_p)
    ,.num_channels_p(`dram_pkg::num_channels_p)
    ,.num_columns_p(`dram_pkg::num_columns_p)
    ,.num_rows_p(`dram_pkg::num_rows_p)
    ,.num_ba_p(`dram_pkg::num_ba_p)
    ,.num_bg_p(`dram_pkg::num_bg_p)
    ,.num_ranks_p(`dram_pkg::num_ranks_p)
    ,.size_in_bits_p(`dram_pkg::size_in_bits_p)
    ,.address_mapping_p(`dram_pkg::address_mapping_p)
    ,.config_p(`dram_pkg::config_p)
    ,.masked_p(0)
    ,.debug_p(1)
    ,.init_mem_p(1)
  ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.v_i(dramsim3_v_li)
    ,.write_not_read_i(dramsim3_write_not_read_li)
    ,.ch_addr_i(dramsim3_ch_addr_li)
    ,.yumi_o(dramsim3_yumi_lo)

    ,.data_v_i(dramsim3_data_v_li)
    ,.data_i(dramsim3_data_li)
    ,.mask_i('0)
    ,.data_yumi_o(dramsim3_data_yumi_lo)

    ,.data_v_o(dramsim3_data_v_lo)
    ,.data_o(dramsim3_data_lo)
    ,.read_done_ch_addr_o(dramsim3_read_done_ch_addr_lo)

    ,.write_done_o(dramsim3_write_done_lo)
    ,.write_done_ch_addr_o()
  ); 

  assign dramsim3_v_li[0] = tr_v_lo;
  assign dramsim3_write_not_read_li[0] = tr_data_lo.write_not_read;
  assign dramsim3_ch_addr_li[0] = tr_data_lo.ch_addr;
  assign tr_yumi_li = dramsim3_yumi_lo[0];
  assign dramsim3_data_v_li[0] = tr_v_lo & tr_data_lo.write_not_read;
  assign dramsim3_data_li[0] = {{(`dram_pkg::data_width_p-write_data_width_lp){1'b0}}, tr_data_lo.data};

  for (genvar i = 1; i < `dram_pkg::num_channels_p; i++) begin
    assign dramsim3_v_li[i] = 1'b0;
    assign dramsim3_ch_addr_li[i] = '0;
    assign dramsim3_write_not_read_li[i] = 1'b0;
    assign dramsim3_data_v_li[i] = 1'b0;
    assign dramsim3_data_li[i] = '0;
  end

  // request tracker
  integer sent_r;
  integer recv_r;

  always_ff @ (posedge clk) begin
    if (reset) begin
      sent_r <= 0;
      recv_r <= 0;
    end
    else begin
      if (tr_v_lo & tr_yumi_li) sent_r <= sent_r + 1;
      recv_r <= recv_r + dramsim3_data_v_lo[0] + dramsim3_write_done_lo[0];
    end
  end

  initial begin
    wait(tr_done_lo & (sent_r == recv_r));
    #30000;
    $display("[BSG_FINISH] test successful.");
    $finish();
  end


  // consistency checker
  // num_cols_p = columns_per_row * num_banks * ba_per_bg * num_rows
  localparam num_cols_p = 64*4*4*(2**15);
  logic [31:0] shadow_mem [num_cols_p-1:0];

  logic [`dram_pkg::channel_addr_width_p-5-1:0] col_addr;
  logic [`dram_pkg::channel_addr_width_p-5-1:0] read_done_col_addr;

  assign col_addr = dramsim3_ch_addr_li[0][`dram_pkg::channel_addr_width_p-1:5];
  assign read_done_col_addr = dramsim3_read_done_ch_addr_lo[0][`dram_pkg::channel_addr_width_p-1:5];
  

  always_ff @ (posedge clk) begin
    if (reset) begin
      for (integer i = 0; i < num_cols_p; i++)
        shadow_mem[i] = '0;
      
    end
    else begin

      // input record
      if (dramsim3_v_li[0] & dramsim3_yumi_lo[0]) begin
        if (dramsim3_write_not_read_li[0]) begin
          shadow_mem[col_addr] <= dramsim3_data_li[0][0+:32];
          $display("[BSG_DEBUG] t=%t writing 0x%08x to   0x%08x\n", $time, dramsim3_data_li[0][0+:32], dramsim3_ch_addr_li[0]);          
        end
      end

      // output checker
      if (dramsim3_data_v_lo[0]) begin
        $display("[BSG_DEBUG] t=%t read 0x%08x from 0x%08x\n",$time, dramsim3_data_lo[0][0+:32], dramsim3_read_done_ch_addr_lo[0]);

        assert(shadow_mem[read_done_col_addr] == dramsim3_data_lo[0][0+:32])
          //$display("[BSG_INFO] output matched. Id=%d, Expected=%x, Actual=%x", recv_id, result[recv_id], dramsim3_data_lo[0][0+:32]);
          else $fatal("[BSG_FATAL] output does not match expected result for 0x%x. Expected=%x, Actual=%x",
                      dramsim3_read_done_ch_addr_lo[0], shadow_mem[read_done_col_addr], dramsim3_data_lo[0][0+:32]);
      end

    end
  end

endmodule
