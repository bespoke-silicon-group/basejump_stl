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
  ,parameter  ui_addr_width_p    = "inv"
  ,parameter  ui_data_width_p    = "inv" // data width of UI interface, can be 2^n while n = [3, log2(burst_data_width_p)]
  ,parameter  burst_data_width_p = "inv" // data width of an outstanding read/write transaction, typically data width of a cache line
  ,parameter  dq_data_width_p    = "inv" // data width of DDR interface, consistent with packaging
  ,parameter  cmd_afifo_depth_p  = "inv" // maximum number of outstanding read/write transactions can be queued when the controller is busy
  ,parameter  cmd_sfifo_depth_p  = "inv" // maximum number of DRAM commands can be queued when the DDR interface is busy, no less than cmd_afifo_depth_p
  ,localparam ui_mask_width_lp   = ui_data_width_p >> 3
  ,localparam dfi_data_width_lp  = dq_data_width_p << 1
  ,localparam dfi_mask_width_lp  = (dq_data_width_p >> 3) << 1
  ,localparam dq_group_lp        = dq_data_width_p >> 3
  ,localparam ui_burst_length_lp = burst_data_width_p / ui_data_width_p
  ,localparam dq_burst_length_lp = burst_data_width_p / dq_data_width_p)
  // Tag lines
  (output bsg_tag_s                   async_reset_tag_o
  ,output bsg_tag_s [dq_group_lp-1:0] bsg_dly_tag_o
  ,output bsg_tag_s [dq_group_lp-1:0] bsg_dly_trigger_tag_o
  ,output bsg_tag_s                   bsg_ds_tag_o
  //
  ,output bsg_dmc_s                   dmc_p_o
  // Global asynchronous reset input, will be synchronized to each clock domain
  // Consistent with the reset signal defined in Xilinx UI interface
  ,output                             sys_reset_o
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
  ,input                              dfi_clk_1x_i
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

  logic [tag_trace_rom_addr_width_lp-1:0] tag_rom_addr_li;
  logic [tag_trace_rom_data_width_lp-1:0] tag_rom_data_lo;

  logic tag_trace_en_r_lo;
  logic tag_trace_done_lo;

  // TAG TRACE ROM
  bsg_tag_boot_rom #(.width_p( tag_trace_rom_data_width_lp )
                    ,.addr_width_p( tag_trace_rom_addr_width_lp )
                    )
    tag_trace_rom
      (.addr_i( tag_rom_addr_li )
      ,.data_o( tag_rom_data_lo )
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

      ,.rom_addr_o( tag_rom_addr_li )
      ,.rom_data_i( tag_rom_data_lo )

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
  bsg_tag_s [22:0] tag_lines_lo;

  assign async_reset_tag_o     = tag_lines_lo[0];
  assign bsg_dly_tag_o         = tag_lines_lo[1+:dq_group_lp];
  assign bsg_dly_trigger_tag_o = tag_lines_lo[1+dq_group_lp+:4];
  assign bsg_ds_tag_o          = tag_lines_lo[1+2*dq_group_lp];

  wire bsg_tag_s [12:0] dmc_cfg_tag_lines_lo = tag_lines_lo[2+2*dq_group_lp+:13];

  // BSG tag master instance
  bsg_tag_master #(.els_p( 23 )
                  ,.lg_width_p( tag_lg_max_payload_width_gp )
                  )
    btm
      (.clk_i      ( tag_clk )
      ,.data_i     ( tag_trace_valid_lo? bsg_tag_data: 1'b0 )
      ,.en_i       ( 1'b1 )
      ,.clients_r_o( tag_lines_lo )
      );

  // Tag payload for bsg_dmc control signals
  logic [12:0][7:0] dmc_cfg_tag_data_lo;
  logic [12:0]      dmc_cfg_tag_new_data_lo;

  genvar idx;
  generate
    for(idx=0;idx<13;idx++) begin: dmc_cfg
      bsg_tag_client #(.width_p( 8 ), .default_p( 0 ))
        btc
          (.bsg_tag_i     ( dmc_cfg_tag_lines_lo[idx] )
          ,.recv_clk_i    ( dfi_clk_1x_i )
          ,.recv_reset_i  ( 1'b0 )
          ,.recv_new_r_o  ( dmc_cfg_tag_new_data_lo[idx] )
          ,.recv_data_r_o ( dmc_cfg_tag_data_lo[idx] )
          );
    end
  endgenerate

  assign dmc_p_o.trefi        = {dmc_cfg_tag_data_lo[1], dmc_cfg_tag_data_lo[0]};
  assign dmc_p_o.tmrd         = dmc_cfg_tag_data_lo[2][3:0];
  assign dmc_p_o.trfc         = dmc_cfg_tag_data_lo[2][7:4];
  assign dmc_p_o.trc          = dmc_cfg_tag_data_lo[3][3:0];
  assign dmc_p_o.trp          = dmc_cfg_tag_data_lo[3][7:4];
  assign dmc_p_o.tras         = dmc_cfg_tag_data_lo[4][3:0];
  assign dmc_p_o.trrd         = dmc_cfg_tag_data_lo[4][7:4];
  assign dmc_p_o.trcd         = dmc_cfg_tag_data_lo[5][3:0];
  assign dmc_p_o.twr          = dmc_cfg_tag_data_lo[5][7:4];
  assign dmc_p_o.twtr         = dmc_cfg_tag_data_lo[6][3:0];
  assign dmc_p_o.trtp         = dmc_cfg_tag_data_lo[6][7:4];
  assign dmc_p_o.tcas         = dmc_cfg_tag_data_lo[7][3:0];
  assign dmc_p_o.col_width    = dmc_cfg_tag_data_lo[8][3:0];
  assign dmc_p_o.row_width    = dmc_cfg_tag_data_lo[8][7:4];
  assign dmc_p_o.bank_width   = dmc_cfg_tag_data_lo[9][1:0];
  assign dmc_p_o.bank_pos     = dmc_cfg_tag_data_lo[9][7:2];
  assign dmc_p_o.dqs_sel_cal  = dmc_cfg_tag_data_lo[7][6:4];
  assign dmc_p_o.init_cycles  = {dmc_cfg_tag_data_lo[11], dmc_cfg_tag_data_lo[10]};
  assign sys_reset_o          = dmc_cfg_tag_data_lo[12][0];

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

  //initial begin
  //  $display("\n#### Regression test started ####");
  //  @(posedge tag_trace_done_lo);
  //  repeat(100) @(posedge ui_clk);
  //  for(k=0;k<256;k++) begin
  //    waddr = k*dq_burst_length_lp;
  //    wdata = 0;
  //    for(j=0;j<ui_burst_length_lp;j++)
  //      wdata = (wdata << ui_data_width_p) + waddr + j;
  //    wdata_array[waddr] = wdata;
  //    $display("Time: %8d ns, Write %x to %x", $time(), wdata, waddr);
  //    fork
  //      ui_cmd(`WRITE, waddr);
  //      ui_write(0, wdata);
  //    join
  //  end
  //  for(k=0;k<256;k++) begin
  //    raddr = k*dq_burst_length_lp;
  //    raddr_queue.push_front(raddr);
  //    ui_cmd(`READ, raddr);
  //  end
  //  repeat(1000) @(posedge ui_clk);
  //  $display("\nRegression test passed!");
  //  $display("\n#### Regression test ended ####");
  //  $finish();
  //end

  localparam cmd_trace_rom_addr_width_lp = 32;
  localparam cmd_trace_rom_data_width_lp = ui_addr_width_p + ui_data_width_p;

  logic [cmd_trace_rom_addr_width_lp-1:0] cmd_rom_addr;
  logic [cmd_trace_rom_data_width_lp-1:0] cmd_rom_data;

    bsg_fsb_node_trace_replay #(
      .ring_width_p(ring_width_lp)
      ,.rom_addr_width_p(rom_addr_width_lp)
    ) cmd_trace (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i(tag_trace_done_lo)

	  //not used
      ,.v_i()
      ,.data_i()
      ,.ready_o()

      ,.v_o(tr_v_lo)
      ,.data_o(tr_data_lo)
      ,.yumi_i(tr_yumi_li)

      ,.rom_addr_o(rom_addr)
      ,.rom_data_i(rom_data)

      ,.done_o(tr_done_lo)
      ,.error_o()
    );

    bsg_cmd_trace_rom #(
      .rom_addr_width_p(rom_addr_width_lp)
      ,.rom_data_width_p(+4)
      ,.id_p(i)
    ) cmd_trace_rom (
      .rom_addr_i(rom_addr)
      ,.rom_data_o(rom_data)
    );

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
