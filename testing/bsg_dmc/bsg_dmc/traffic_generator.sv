`include "bsg_defines.sv"
`include "bsg_dmc.svh"

`ifndef UI_CLK_PERIOD
  `define UI_CLK_PERIOD 2500.0
`endif

`ifndef DFI_CLK_PERIOD
  `define DFI_CLK_PERIOD 2500.0
`endif

`ifndef TAG_CLK_PERIOD
  `define TAG_CLK_PERIOD 10000.0
`endif

`ifndef LINK_IO_CLK_PERIOD
  `define LINK_IO_CLK_PERIOD 1000.0
`endif

`ifndef FPGA_CLK_PERIOD
  `define FPGA_CLK_PERIOD 2500.0
`endif

module traffic_generator
  import bsg_tag_pkg::*;
  import bsg_dmc_pkg::*;
 #(parameter `BSG_INV_PARAM(ui_addr_width_p)
  ,parameter `BSG_INV_PARAM(ui_data_width_p) // data width of UI interface, can be 2^n while n = [3, log2(burst_data_width_p)]
  ,parameter `BSG_INV_PARAM(burst_data_width_p) // data width of an outstanding read/write transaction, typically data width of a cache line
  ,parameter `BSG_INV_PARAM( dq_data_width_p) // data width of DDR interface, consistent with packaging
  ,parameter `BSG_INV_PARAM(cmd_afifo_depth_p) // maximum number of outstanding read/write transactions can be queued when the controller is busy
  ,parameter `BSG_INV_PARAM(cmd_sfifo_depth_p) // maximum number of DRAM commands can be queued when the DDR interface is busy, no less than cmd_afifo_depth_p
  , parameter ui_cmd_width_p	 = 4
  ,localparam ui_mask_width_lp   = ui_data_width_p >> 3
  ,localparam dfi_data_width_lp  = dq_data_width_p << 1
  ,localparam dfi_mask_width_lp  = (dq_data_width_p >> 3) << 1
  ,localparam dq_group_lp        = dq_data_width_p >> 3
  ,localparam ui_burst_length_lp = burst_data_width_p / ui_data_width_p
  ,localparam dq_burst_length_lp = burst_data_width_p / dq_data_width_p
  ,localparam payload_width_lp 	 = `bsg_dmc_trace_entry_width(ui_data_width_p, ui_addr_width_p)
  ,localparam tag_dmc_local_els_lp = tag_dmc_dly_local_els_gp+tag_dmc_cfg_local_els_gp+tag_dmc_sys_local_els_gp+tag_dmc_osc_local_els_gp
  )
  // Tag lines
  (output  bsg_tag_s [tag_dmc_local_els_lp-1:0]	tag_lines_o
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
  ,input                              dfi_init_calib_complete_i
  ,input							  stall_trace_reading_i
  //
  ,output                             ui_clk_o
  //
  ,input                              ui_clk_sync_rst_i
  ,output                             dfi_clk_o
  ,input							  irritate_clock_i
  ,input							  dfi_refresh_in_progress_i
  ,input							  clock_monitor_clk_i
  ,output							  frequency_mismatch_o
  ,output							  clock_correction_done_o
  );

  // Total number of clients the master will be driving.
  localparam tag_num_clients_gp = tag_dmc_local_els_lp;
  // The number of bits required to represent the max payload width
  localparam tag_max_payload_width_gp = 8;
  localparam tag_lg_max_payload_width_gp = `BSG_SAFE_CLOG2(tag_max_payload_width_gp + 1);

  logic ui_clk;

  logic refresh_in_progress_tag_clk_synced;

  assign ui_clk_o = ui_clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`UI_CLK_PERIOD)) ui_clk_gen (.o(ui_clk));
	
  logic dfi_clk;

  assign dfi_clk_o = dfi_clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`DFI_CLK_PERIOD)) dfi_clk_gen (.o(dfi_clk));

  logic fpga_link_clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`FPGA_CLK_PERIOD)) fpga_link_clk_gen (.o(fpga_link_clk));

  logic fpga_link_io_clk_li;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`LINK_IO_CLK_PERIOD)) fpga_link_io_clk_gen (.o(fpga_link_io_clk_li));

  logic asic_link_io_clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`LINK_IO_CLK_PERIOD)) asic_link_io_clk_gen (.o(asic_link_io_clk));

  logic tag_clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`TAG_CLK_PERIOD)) tag_clk_gen (.o(tag_clk));

  //////////////////////////////////////////////////
  //
  // BSG Tag Trace Replay
  //
  localparam tag_trace_rom_addr_width_lp = 32;
  localparam tag_trace_rom_data_width_lp = 24;

  logic [tag_trace_rom_addr_width_lp-1:0] rom_addr_li;
  logic [tag_trace_rom_data_width_lp-1:0] rom_data_lo;

  logic tag_trace_en_r_lo;
  logic tag_trace_done_lo;

  logic en_trace_reading_li;
  logic en_trace_reading_fpga_clk_synced_li;

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
	

  assign en_trace_reading_li = dfi_init_calib_complete_i & tag_trace_done_lo & (~stall_trace_reading_i);

  bsg_sync_sync #(.width_p(1)) en_trace_fpga_clk_sync_inst
    (.oclk_i      ( fpga_link_clk      )
    ,.iclk_data_i ( en_trace_reading_li )
    ,.oclk_data_o ( en_trace_reading_fpga_clk_synced_li    ));
   
  bsg_sync_sync #(.width_p(1)) refresh_in_progress_tag_clk_inst
    (.oclk_i      ( tag_clk      )
    ,.iclk_data_i ( dfi_refresh_in_progress_i )
    ,.oclk_data_o ( refresh_in_progress_tag_clk_synced   ));

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

  logic tag_master_data_li;
  logic [6:0] clock_update_tag_index, wrong_clock_tag_index;
  logic [4:0] stall_transmission_tag_index, re_enable_transmission_tag_index;

  logic update_clock_freq;
  assign update_clock_freq = stall_trace_reading_i & ~(refresh_in_progress_tag_clk_synced);

  logic [20:0] stall_dmc_tag_reg;
  logic [20:0] no_stall_dmc_tag_reg;

  logic [20:0] clock_period_tag_reg;
  logic [20:0] clock_period_change_set_tag_reg;
  logic [20:0] clock_period_change_reset_tag_reg;  
  logic [62:0] tag_data_clock_period_and_trigger;

  logic [20:0] wrong_clock_period_tag_reg;
  logic [62:0] tag_data_wrong_clk_period_and_trigger;

  logic clock_correction_done;
  assign clock_correction_done_o = (re_enable_transmission_tag_index > 20);

  //Tag format: {2'b0, 8'1 (tag data), 5'<client_id>, 1'<data_or_reset>, 4'<payload_length>, 1'b1}
  assign stall_dmc_tag_reg = 21'b00_00000001_10111_1_1000_1;
  assign no_stall_dmc_tag_reg = 21'b00_00000000_10111_1_1000_1;

  assign clock_period_tag_reg = 21'b00_00011011_11001_1_0101_1;
  assign clock_period_change_set_tag_reg = 21'b00_00000001_11010_1_0001_1;
  assign clock_period_change_reset_tag_reg = 21'b00_00000000_11010_1_0001_1;
  
  assign tag_data_clock_period_and_trigger = {clock_period_change_reset_tag_reg, clock_period_change_set_tag_reg, clock_period_tag_reg};

  assign wrong_clock_period_tag_reg = 21'b00_00011000_11001_1_0101_1;
  assign tag_data_wrong_clk_period_and_trigger = {clock_period_change_reset_tag_reg, clock_period_change_set_tag_reg, wrong_clock_period_tag_reg};

  always_comb begin
	 if(tag_trace_done_lo && irritate_clock_i &&  (wrong_clock_tag_index <=61 )) begin
		 tag_master_data_li = tag_data_wrong_clk_period_and_trigger[wrong_clock_tag_index];
	 end
     else if(tag_trace_done_lo && stall_trace_reading_i && (stall_transmission_tag_index <=19)) begin
   	  	tag_master_data_li = stall_dmc_tag_reg[stall_transmission_tag_index];
     end
	 else if(tag_trace_done_lo && update_clock_freq && (clock_update_tag_index <= 61 )) begin
		 tag_master_data_li = tag_data_clock_period_and_trigger[clock_update_tag_index];
	 end
	 else if(stall_trace_reading_i && (re_enable_transmission_tag_index <= 20)) begin
		 tag_master_data_li = no_stall_dmc_tag_reg[re_enable_transmission_tag_index];		
	 end
     else if(tag_trace_valid_lo) begin
   	  	tag_master_data_li = bsg_tag_data;
     end
     else begin
     	tag_master_data_li = 0;
     end
  end

  always @(posedge tag_clk) begin
      if(tag_reset) begin
		  stall_transmission_tag_index <= 0;
		  clock_update_tag_index <= 0;
		  wrong_clock_tag_index <= 0;
		  re_enable_transmission_tag_index <= 0;
      end
      else if (stall_trace_reading_i && (stall_transmission_tag_index <= 19)) begin
    	  stall_transmission_tag_index <= stall_transmission_tag_index + 1;
      end
	  else if (update_clock_freq && (clock_update_tag_index <= 61)) begin
    	 clock_update_tag_index  <= clock_update_tag_index + 1;
      end
	  else if (stall_trace_reading_i && (re_enable_transmission_tag_index <= 20)) begin
		re_enable_transmission_tag_index <= re_enable_transmission_tag_index + 1;
	  end
	  else if (irritate_clock_i && (wrong_clock_tag_index <= 61)) begin
    	 wrong_clock_tag_index  <= wrong_clock_tag_index + 1;
      end
  end

  bsg_nonsynth_dmc_clock_monitor
	#(.max_fpga_count(10)
	  ,.expected_ddr_period_ns_p(10)
	  ,.fpga_clk_period_ns_p(10)
	)	
	ddr_clock_mon
	(	.fpga_clk(tag_clk)
		,.fpga_reset(ui_clk_sync_rst_i)
		,.ddr_clk_i(clock_monitor_clk_i)
		,.frequency_mismatch_o(frequency_mismatch_o)
	);

  // BSG tag master instance
  bsg_tag_master #(.els_p( tag_dmc_local_els_lp )
                  ,.lg_width_p( tag_lg_max_payload_width_gp )
                  )
    btm
      (.clk_i      ( tag_clk )
      ,.data_i     ( tag_master_data_li )
      ,.en_i       ( 1'b1 )
      ,.clients_r_o( tag_lines_o )
      );

  logic     [ui_addr_width_p-1:0]  app_addr;
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

`ifdef NONSYNTH_TB
	// non-synthesisable testing
	`include "tasks.sv"

  	  initial begin
  	      //$vcdplusmemon();
  	      app_en = 0;
  	      app_wdf_wren = 0;
  	      app_wdf_end = 0;
  	  end

	  initial begin
	    $display("\n#### Regression test started ####");
	    @(posedge dfi_init_calib_complete_i);
	    repeat(1000) @(posedge ui_clk);
	    for(k=0;k<512;k++) begin
	      waddr = k*dq_burst_length_lp;
	      wdata = 0;
	      for(j=0;j<ui_burst_length_lp;j++)
	        wdata = (wdata << ui_data_width_p) + waddr + j;
	      wdata_array[waddr] = wdata;
	      $display("Time: %8d ns, Write %x to %x", $time(), wdata, waddr);
	      fork
	        ui_cmd(WR, waddr);
	        ui_write(0, wdata);
	      join
	    end
        #1;
	    for(k=0;k<512;k++) begin
	      raddr = k*dq_burst_length_lp;
	      raddr_queue.push_front(raddr);
	      ui_cmd(RD, raddr);
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
	    ,.ready_and_o(                   )
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
`else
	
	// Synthesisable testing below:
	// Topology:
	// * BSG TRACE ROM contains command, address, write data and write mask
	// * BSG TRACE REPLAY used to 
	// 		** read TRACE ROM and transmit cmd, addr, write data mask forward
	// 		** receive read data from DMC and compare with data that was already written to that address
	// * FPGA SIDE DDR LINKS:
	// 		** BSG DDR UPSTREAM LINK to tranmsit command, address, write data and write mask to ASIC
	// 		** BSG DDR DOWNSTREAM LINK to get read data from ASIC
	// * ASIC SIDE DDR LINKS:
	// 		** BSG DDR DOWNSTREAM LINK to tranmsit command, address, write data and write mask to DMC
	// 		** BSG DDR UPSTREAM LINK to pass read data from DMC to FPGA
	// * STORE FORWARD FIFO to collect command, address, write data and write mask from DDR LINK and forward
	// * TRACE TO DMC UI ADAPTER to convert :
	// 		** trace packet to XILINX UI command and write interfaces
	// 		** XILINX UI interface read interface signals to trace packet
	// * BSG DRAM CONTROLLER
	//
	logic fpga_link_upstream_edge_clk_lo;
	logic [payload_width_lp/2-1:0] fpga_link_upstream_edge_data_lo;
	logic fpga_link_upstream_edge_valid_lo;

	logic fpga_link_reset_li, asic_link_reset_li;
  	logic fpga_link_upstream_io_reset_li, asic_link_downstream_io_reset;
	logic fpga_link_downstream_io_reset_li, asic_link_upstream_io_reset;

	logic fpga_link_token_reset_li, asic_link_token_reset_li;

    // ASIC SIDE LINK SIGNALS
  	logic [payload_width_lp/2-1:0] asic_link_downstream_edge_data;
  	logic asic_link_downstream_edge_valid;
  	logic asic_link_downstream_edge_token_li;
  	logic asic_link_downstream_edge_clk;
  	logic asic_link_downstream_core_ready_li;
	logic asic_link_upstream_core_ready_lo;


  	logic [payload_width_lp-1:0] asic_link_downstream_core_data_lo;
  	logic asic_link_downstream_core_valid_lo;
  	logic asic_link_downstream_core_yumi_lo;

	logic [payload_width_lp-1:0] asic_link_upstream_core_data_li;
  	logic asic_link_upstream_core_valid_li;
  	logic asic_link_upstream_core_yumi_lo;

	logic [payload_width_lp/2 - 1:0] asic_link_upstream_edge_data_li;
	logic asic_link_upstream_edge_clk_li;
	logic asic_link_upstream_edge_valid_li;
	logic fpga_link_downstream_edge_token_li;

  	// DMC input FIFO related signals
  	logic [payload_width_lp - 1:0] dmc_adapter_input_data_lo;
  	logic dmc_adapter_input_valid_lo;
  	logic dmc_adapter_yumi_lo;
  	logic dmc_input_fifo_ready_lo;	
  	
  	logic dmc_adapter_ready_lo;

    logic trace_reading_done_lo;
	// Whatever testing environment that goes into the FPGA: trace ROM, trace replay, FPGA side DDR upstream and downstream links
	bsg_dmc_tester
				#(	.data_width_p(ui_data_width_p),
					.addr_width_p(ui_addr_width_p),
					.burst_width_p(ui_burst_length_lp)
				) dmc_tester
				(	.fpga_link_clk_i(fpga_link_clk),
					.fpga_link_io_clk_i(fpga_link_io_clk_li),
					.fpga_link_reset_i(fpga_link_reset_li),
					.fpga_link_upstream_io_reset_i(fpga_link_upstream_io_reset_li),
					.fpga_link_downstream_io_reset_i(fpga_link_downstream_io_reset_li),
					.fpga_link_token_reset_i(fpga_link_token_reset_li),
					.fpga_link_upstream_edge_clk_o(fpga_link_upstream_edge_clk_lo),
					.asic_link_downstream_edge_token_i(asic_link_downstream_edge_token_li),
					.fpga_link_upstream_edge_data_o(fpga_link_upstream_edge_data_lo),
					.fpga_link_upstream_edge_valid_o(fpga_link_upstream_edge_valid_lo),

					.asic_link_upstream_edge_clk_i(asic_link_upstream_edge_clk_li),
					.asic_link_upstream_edge_data_i(asic_link_upstream_edge_data_li),
					.asic_link_upstream_edge_valid_i(asic_link_upstream_edge_valid_li),
					.fpga_link_downstream_edge_token_o(fpga_link_downstream_edge_token_li),

					.en_trace_reading_i(en_trace_reading_fpga_clk_synced_li),
                    .trace_reading_done_o(trace_reading_done_lo)
				);

  	assign asic_link_downstream_core_yumi_lo = asic_link_downstream_core_valid_lo & dmc_input_fifo_ready_lo ;

  	  // ASIC SIDE LINKS START
  	bsg_link_ddr_downstream
  					#(.width_p        (payload_width_lp)
  					 ,.channel_width_p(payload_width_lp/2)
  					 ,.num_channels_p (1)
  					 ) asic_link_downstream
  					 (.core_clk_i       (ui_clk)
  					 ,.core_link_reset_i(asic_link_reset_li)
  					 ,.io_link_reset_i  (asic_link_downstream_io_reset)
  					 
  					 ,.core_data_o   (asic_link_downstream_core_data_lo)
  					 ,.core_valid_o  (asic_link_downstream_core_valid_lo)
  					 ,.core_yumi_i   (asic_link_downstream_core_yumi_lo)
  					
  					 ,.io_clk_i      (fpga_link_upstream_edge_clk_lo)
  					 ,.io_data_i     (fpga_link_upstream_edge_data_lo)
  					 ,.io_valid_i    (fpga_link_upstream_edge_valid_lo)
  					 ,.core_token_r_o(asic_link_downstream_edge_token_li)
  					 );

    logic read_data_to_consumer_valid_lo;
    logic read_data_to_consumer_ready_li;
	logic [payload_width_lp-1:0] read_data_to_consumer_lo;
    logic [ui_data_width_p-1:0] rdata_from_adapter_lo;

    assign read_data_to_consumer_lo = {{ui_mask_width_lp{1'b0}}, rdata_from_adapter_lo};

  	bsg_two_fifo
  						#(.width_p(payload_width_lp)
  						) dmc_output_fifo
  						(.clk_i  (ui_clk)
  						,.reset_i(asic_link_reset_li)
  						
  						,.ready_param_o(read_data_to_consumer_ready_li)
  						,.data_i (read_data_to_consumer_lo)
  						,.v_i    (read_data_to_consumer_valid_lo)
  						
  						,.v_o    (asic_link_upstream_core_valid_li)
  						,.data_o (asic_link_upstream_core_data_li)
  						,.yumi_i (asic_link_upstream_core_valid_li & asic_link_upstream_core_ready_lo)
  						);

	bsg_link_ddr_upstream
 					#(.width_p        (payload_width_lp)
 					 ,.channel_width_p(payload_width_lp/2)
 					 ,.num_channels_p (1)
 					 ) asic_link_upstream
 					 (.core_clk_i         (ui_clk)
 					 ,.io_clk_i           (asic_link_io_clk)
 					 ,.core_link_reset_i  (asic_link_reset_li)
 					 ,.io_link_reset_i    (asic_link_upstream_io_reset)
 					 ,.async_token_reset_i(asic_link_token_reset_li)
 					 
 					 ,.core_data_i (asic_link_upstream_core_data_li)
 					 ,.core_valid_i(asic_link_upstream_core_valid_li)
 					 ,.core_ready_o(asic_link_upstream_core_ready_lo)

 					 ,.io_clk_r_o  (asic_link_upstream_edge_clk_li)
 					 ,.io_data_r_o (asic_link_upstream_edge_data_li)
 					 ,.io_valid_r_o(asic_link_upstream_edge_valid_li)
 					 ,.token_clk_i (fpga_link_downstream_edge_token_li)
 					 );

  	// ASIC SIDE LINKS END
	assign dmc_adapter_yumi_lo = dmc_adapter_ready_lo & dmc_adapter_input_valid_lo;
  	
	// Trace packets going towards DMC
  	bsg_fifo_1r1w_small 
  						#(.width_p(payload_width_lp)
  						,.els_p(10)
  						) dmc_input_fifo
  						(.clk_i  (ui_clk)
  						,.reset_i(asic_link_reset_li)
  						
  						,.ready_param_o(dmc_input_fifo_ready_lo)
  						,.data_i (asic_link_downstream_core_data_lo)
  						,.v_i    (asic_link_downstream_core_valid_lo)
  						
  						,.v_o    (dmc_adapter_input_valid_lo)
  						,.data_o (dmc_adapter_input_data_lo)
  						,.yumi_i (dmc_adapter_yumi_lo)
  						);

	// Receive trace packet - convert it to XILINX UI command and write interface signals
	// Receive read signals in XILINX UI interface and convert it to trace packet
  	bsg_dmc_xilinx_ui_trace_replay
  						#(	.data_width_p(ui_data_width_p),
  							.addr_width_p(ui_addr_width_p),
  							.burst_len_p(ui_burst_length_lp),
                            // Arbitrary for now, just make sure the trace correlates
                            .tfifo_depth_p(3*ui_burst_length_lp),
                            .rfifo_depth_p(2*ui_burst_length_lp)
  						) trace_to_dmc_ui
  						(	.clk_i(ui_clk),
  							.reset_i(ui_clk_sync_rst_i),
							//.ui_clk_sync_rst_i(ui_clk_sync_rst_i),
  							.data_i(dmc_adapter_input_data_lo),
  						 	.v_i(dmc_adapter_input_valid_lo),

							.v_o(read_data_to_consumer_valid_lo),
							.data_o(rdata_from_adapter_lo),
                            .yumi_i(read_data_to_consumer_ready_li & read_data_to_consumer_valid_lo),

  						 	.ready_and_o(dmc_adapter_ready_lo),
  	
  						    // XILINX UI signals	
  							.app_addr_o(app_addr),
  							.app_cmd_o(app_cmd),
  							.app_en_o(app_en),
  							.app_rdy_i(app_rdy),
  							.app_wdf_wren_o(app_wdf_wren),
  							.app_wdf_data_o(app_wdf_data),
  							.app_wdf_mask_o(app_wdf_mask),
  							.app_wdf_end_o(app_wdf_end),
  							.app_wdf_rdy_i(app_wdf_rdy),
  							.app_rd_data_valid_i(app_rd_data_valid),
  							.app_rd_data_i(app_rd_data),
  							.app_rd_data_end_i(app_rd_data_end)
  						 );

    localparam rstdly_lp = `BSG_MAX(`BSG_MAX(`FPGA_CLK_PERIOD, `LINK_IO_CLK_PERIOD), `UI_CLK_PERIOD) * 10;

	initial begin

		fpga_link_reset_li = 1;
		asic_link_reset_li = 1;

		fpga_link_upstream_io_reset_li = 1;
		asic_link_upstream_io_reset = 1;

		fpga_link_downstream_io_reset_li = 1;
		asic_link_downstream_io_reset = 1;

		fpga_link_token_reset_li = 0;
		asic_link_token_reset_li = 0;

        do #(rstdly_lp); while(ui_clk_sync_rst_i !== 1'b1);

		fpga_link_token_reset_li = 1;
		asic_link_token_reset_li = 1;

		#(rstdly_lp);

		fpga_link_token_reset_li = 0;
		asic_link_token_reset_li = 0;

		#(rstdly_lp);

		@(posedge fpga_link_io_clk_li); #1;
  		  	fpga_link_upstream_io_reset_li = 0;

		@(posedge asic_link_io_clk); #1;
  		  	asic_link_upstream_io_reset = 0;

		#(rstdly_lp);
  	  	@(posedge fpga_link_upstream_edge_clk_lo); #1;
  		  	asic_link_downstream_io_reset = 0;

		@(posedge asic_link_upstream_edge_clk_li); #1;
			fpga_link_downstream_io_reset_li = 0;

		#(rstdly_lp);
  	  	// core link reset
  	  	@(posedge fpga_link_clk); #1;
  	  		fpga_link_reset_li = 0;
		@(posedge ui_clk); #1;
			asic_link_reset_li = 0;

		@(posedge trace_reading_done_lo); #(rstdly_lp);
		$finish();
	end

`endif

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
