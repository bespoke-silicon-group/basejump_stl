`include "bsg_defines.v"

>>>>>>> 8345b2827b2e9911794567f412039076df65da8a
`define WRITE 3'b000
`define READ  3'b001

`ifndef UI_CLK_PERIOD
  `define UI_CLK_PERIOD 2500.0
`endif

`ifndef DFI_CLK_PERIOD
  `define DFI_CLK_PERIOD 5000.0
`endif

`ifndef TAG_CLK_PERIOD
  `define TAG_CLK_PERIOD 10000.0
`endif

module traffic_generator
  import bsg_tag_pkg::*;
  import bsg_dmc_pkg::*;
 #(parameter  num_adgs_p         = 1
  ,parameter `BSG_INV_PARAM(ui_addr_width_p)
  ,parameter `BSG_INV_PARAM(ui_data_width_p) // data width of UI interface, can be 2^n while n = [3, log2(burst_data_width_p)]
  ,parameter `BSG_INV_PARAM(burst_data_width_p) // data width of an outstanding read/write transaction, typically data width of a cache line
  ,parameter `BSG_INV_PARAM( dq_data_width_p) // data width of DDR interface, consistent with packaging
  ,parameter `BSG_INV_PARAM(cmd_afifo_depth_p) // maximum number of outstanding read/write transactions can be queued when the controller is busy
  ,parameter `BSG_INV_PARAM(cmd_sfifo_depth_p) // maximum number of DRAM commands can be queued when the DDR interface is busy, no less than cmd_afifo_depth_p
  ,localparam ui_mask_width_lp   = ui_data_width_p >> 3
  ,localparam dfi_data_width_lp  = dq_data_width_p << 1
  ,localparam dfi_mask_width_lp  = (dq_data_width_p >> 3) << 1
  ,localparam dq_group_lp        = dq_data_width_p >> 3
  ,localparam ui_burst_length_lp = burst_data_width_p / ui_data_width_p
  ,localparam dq_burst_length_lp = burst_data_width_p / dq_data_width_p)
  // Tag lines
  (output bsg_tag_s [22:0] 			  tag_lines_o
  //
  // Global asynchronous reset input, will be synchronized to each clock domain
  // Consistent with the reset signal defined in Xilinx UI interface
  // User interface signals
  ,output       [ui_addr_width_p-1:0] app_addr_o
  ,output app_cmd_e                   app_cmd_o
  ,output                             app_en_o
  ,input                              app_rdy_i
  ,output                             app_wdf_wren_o
  ,output       [ui_data_width_p-1:0] app_wdf_data_o
  ,output      [ui_mask_width_lp-1:0] app_wdf_mask_o
  ,output                             app_wdf_end_o
  ,input                              app_wdf_rdy_i
  ,input                              app_rd_data_valid_i
  ,input        [ui_data_width_p-1:0] app_rd_data_i
  ,input                              app_rd_data_end_i
  // Reserved to be compatible with Xilinx IPs
  ,output                             app_ref_req_o
  ,input                              app_ref_ack_i
  ,output                             app_zq_req_o
  ,input                              app_zq_ack_i
  ,output                             app_sr_req_o
  ,input                              app_sr_active_i
  // Status signal
  ,input                              init_calib_complete_i
  //
  ,output                             ui_clk_o
  ,output                             dfi_clk_2x_o
  //
  ,input                              ui_clk_sync_rst_i);

  // Total number of clients the master will be driving.
  localparam tag_num_clients_gp = 23;
  // The number of bits required to represent the max payload width
  localparam tag_max_payload_width_gp = 8;
  localparam tag_lg_max_payload_width_gp = `BSG_SAFE_CLOG2(tag_max_payload_width_gp + 1);

  logic ui_clk;
  assign ui_clk_o = ui_clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`UI_CLK_PERIOD)) ui_clk_gen (.o(ui_clk));

  logic dfi_clk_2x;
  assign dfi_clk_2x_o = dfi_clk_2x;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`DFI_CLK_PERIOD/2)) dfi_clk_2x_gen (.o(dfi_clk_2x));

  logic tag_clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`TAG_CLK_PERIOD)) tag_clk_gen (.o(tag_clk));

  //////////////////////////////////////////////////
  //
  // BSG Tag Trace Replay
  //

  localparam tag_trace_rom_addr_width_lp = 32;
  localparam tag_trace_rom_data_width_lp = 23;

  logic [tag_trace_rom_addr_width_lp-1:0] rom_addr_li;
  logic [tag_trace_rom_data_width_lp-1:0] rom_data_lo;

  logic tag_trace_en_r_lo;
  logic tag_trace_done_lo;

  // TAG TRACE ROM
  bsg_tag_boot_rom #(.width_p( tag_trace_rom_data_width_lp )
                    ,.addr_width_p( tag_trace_rom_addr_width_lp )
                    )
    tag_trace_rom
      (.addr_i( rom_addr_li )
      ,.data_o( rom_data_lo )
      );

  logic tag_reset;
  bsg_nonsynth_reset_gen #(.num_clocks_p(1),.reset_cycles_lo_p(10),.reset_cycles_hi_p(5))
    tag_reset_gen
      (.clk_i(tag_clk)
      ,.async_reset_o(tag_reset)
      );

  wire tag_trace_valid_lo;
  // TAG TRACE REPLAY
  bsg_tag_trace_replay #(.rom_addr_width_p( tag_trace_rom_addr_width_lp )
                        ,.rom_data_width_p( tag_trace_rom_data_width_lp )
                        ,.num_masters_p( 1 )
                        ,.num_clients_p( tag_num_clients_gp )
                        ,.max_payload_width_p( tag_max_payload_width_gp )
                        )
    tag_trace_replay
      (.clk_i   ( tag_clk )
      ,.reset_i ( tag_reset    )
      ,.en_i    ( 1'b1            )
      ,.rom_addr_o( rom_addr_li )
      ,.rom_data_i( rom_data_lo )

      ,.valid_i ( 1'b0 )
      ,.data_i  ( '0 )
      ,.ready_o ()

      ,.valid_o    ( tag_trace_valid_lo )
      ,.en_r_o     ( tag_trace_en_r_lo )
      ,.tag_data_o ( bsg_tag_data )
      ,.yumi_i     ( tag_trace_valid_lo )

      ,.done_o  ( tag_trace_done_lo )
      ,.error_o ()
      ) ;

  //////////////////////////////////////////////////
  //
  // BSG Tag Master Instance (Copied from ASIC)
  //

  // All tag lines from the btm


  // BSG tag master instance
  bsg_tag_master #(.els_p( 23 )
                  ,.lg_width_p( tag_lg_max_payload_width_gp )
                  )
    btm
      (.clk_i      ( tag_clk )
      ,.data_i     ( tag_trace_valid_lo? bsg_tag_data: 1'b0 )
      ,.en_i       ( 1'b1 )
      ,.clients_r_o( tag_lines_o )
      );

   logic      [ui_addr_width_p-1:0] app_addr;
  app_cmd_e                        app_cmd;
  logic                            app_en;
  wire                             app_rdy;
  logic                            app_wdf_wren;
  logic      [ui_data_width_p-1:0] app_wdf_data;
  logic [(ui_data_width_p>>3)-1:0] app_wdf_mask;
  logic                            app_wdf_end;
  wire                             app_wdf_rdy;

  wire                             app_rd_data_valid;
  wire       [ui_data_width_p-1:0] app_rd_data;
  wire                             app_rd_data_end;

  logic [burst_data_width_p-1] wdata_array[integer];
  logic [ui_addr_width_p] waddr_queue, raddr_queue[$];
  logic [ui_addr_width_p] waddr, raddr;
  logic [burst_data_width_p-1] wdata, rdata;

  wire [ui_burst_length_lp-1:0] sipo_valid_lo;
  wire [ui_burst_length_lp-1:0][ui_data_width_p-1:0] sipo_data_lo;
  wire [$clog2(ui_burst_length_lp):0] sipo_yumi_cnt_li;
  wire [burst_data_width_p-1:0] sipo_data;

  logic [ui_addr_width_p] rx_addr;
  logic [burst_data_width_p-1:0] tx_data, rx_data;

  genvar i;
  int read_transactions;
  int j,k;

`include "tasks.v"

  initial begin
    //$vcdplusmemon();
    app_en = 0;
    app_wdf_wren = 0;
    app_wdf_end = 0;
  end

  initial begin
    $display("\n#### Regression test started ####");
    @(posedge tag_trace_done_lo);
    repeat(100) @(posedge ui_clk);
    for(k=0;k<256;k++) begin
      waddr = k*dq_burst_length_lp;
      wdata = 0;
      for(j=0;j<ui_burst_length_lp;j++)
        wdata = (wdata << ui_data_width_p) + waddr + j;
      wdata_array[waddr] = wdata;
      $display("Time: %8d ns, Write %x to %x", $time(), wdata, waddr);
      fork
        ui_cmd(`WRITE, waddr);
        ui_write(0, wdata);
      join
    end
    for(k=0;k<256;k++) begin
      raddr = k*dq_burst_length_lp;
      raddr_queue.push_front(raddr);
      ui_cmd(`READ, raddr);
    end
    repeat(1000) @(posedge ui_clk);
    $display("\nRegression test passed!");
    $display("\n#### Regression test ended ####");
    $finish();
  end

  for(i=0;i<ui_burst_length_lp;i++) begin
    assign sipo_data[ui_data_width_p*i+:ui_data_width_p] = sipo_data_lo[i];
  end

  bsg_serial_in_parallel_out #
    (.width_p    ( ui_data_width_p    )
    ,.els_p      ( ui_burst_length_lp ))
  sipo
    (.clk_i      ( ui_clk            )
    ,.reset_i    ( ui_clk_sync_rst_i )
    ,.valid_i    ( app_rd_data_valid )
    ,.data_i     ( app_rd_data       )
    ,.ready_o    (                   )
    ,.valid_o    ( sipo_valid_lo     )
    ,.data_o     ( sipo_data_lo      )
    ,.yumi_cnt_i ( sipo_yumi_cnt_li  ));

  assign sipo_yumi_cnt_li = ($clog2(ui_burst_length_lp)+1)'(&sipo_valid_lo? ui_burst_length_lp: 0);

  always @(posedge ui_clk) begin
    if(&sipo_valid_lo) begin
      read_transactions = read_transactions + 1;
      rx_addr = raddr_queue.pop_back();
      tx_data = wdata_array[rx_addr];
      rx_data = sipo_data;
      $display("Time: %8d ns, Read %x from %x", $time(), rx_data, rx_addr);
      if(tx_data != rx_data) begin
        $display("Error: Data expected to be %x, but %x received", tx_data, rx_data);
        $display("\nRegression test failed!");
        $finish();
      end
    end
  end

  assign app_addr_o          = app_addr;
  assign app_cmd_o           = app_cmd;
  assign app_en_o            = app_en;
  assign app_rdy             = app_rdy_i;
  assign app_wdf_wren_o      = app_wdf_wren;
  assign app_wdf_data_o      = app_wdf_data;
  assign app_wdf_mask_o      = app_wdf_mask;
  assign app_wdf_end_o       = app_wdf_end;
  assign app_wdf_rdy         = app_wdf_rdy_i;
  assign app_rd_data_valid   = app_rd_data_valid_i;
  assign app_rd_data         = app_rd_data_i;
  assign app_rd_data_end     = app_rd_data_end_i;
endmodule
