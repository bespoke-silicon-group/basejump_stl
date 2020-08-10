`define WRITE 3'b000
`define READ  3'b001

module testbench
  import bsg_tag_pkg::*;
  import bsg_dmc_pkg::*;
  ();
  parameter clk_gen_num_adgs_p = 1;
  parameter ui_addr_width_p    = 28;
  parameter ui_data_width_p    = 64;
  parameter ui_burst_length_p  = 8;
  parameter dq_data_width_p    = 32;
  parameter cmd_afifo_depth_p  = 4;
  parameter cmd_sfifo_depth_p  = 4;
  parameter debug_p            = 1'b1;

  localparam burst_data_width_lp = ui_data_width_p * ui_burst_length_p;
  localparam ui_mask_width_lp    = ui_data_width_p >> 3;
  localparam dq_group_lp         = dq_data_width_p >> 3;
  localparam dq_burst_length_lp  = burst_data_width_lp / dq_data_width_p;

  genvar i;

  integer j,k;

  wire bsg_tag_s        dmc_reset_tag_lines_lo;
  wire bsg_tag_s  [3:0] dmc_dly_tag_lines_lo;
  wire bsg_tag_s  [3:0] dmc_dly_trigger_tag_lines_lo;
  wire bsg_tag_s        dmc_ds_tag_lines_lo;

  bsg_dmc_s                        dmc_p;

  logic                            sys_reset;
  // User interface signals
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

  wire                             app_ref_req;
  wire                             app_ref_ack;
  wire                             app_zq_req;
  wire                             app_zq_ack;
  wire                             app_sr_req;
  wire                             app_sr_active;
  // Status signal
  wire                             init_calib_complete;

  logic                            ui_clk;
  logic                            dfi_clk_2x;
  wire                             dfi_clk_1x;
  wire                             ui_clk_sync_rst;

  wire                      [11:0] device_temp;

  wire                             ddr_ck_p, ddr_ck_n;
  wire                             ddr_cke;
  wire                             ddr_cs_n;
  wire                             ddr_ras_n;
  wire                             ddr_cas_n;
  wire                             ddr_we_n;
  wire                       [2:0] ddr_ba;
  wire                      [15:0] ddr_addr;

  wire                             ddr_reset_n;
  wire                             ddr_odt;

  wire  [(dq_data_width_p>>3)-1:0] ddr_dm_oen_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dm_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_oen_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_ien_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_li;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_oen_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_ien_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_li;
  wire       [dq_data_width_p-1:0] ddr_dq_oen_lo;
  wire       [dq_data_width_p-1:0] ddr_dq_lo;
  wire       [dq_data_width_p-1:0] ddr_dq_li;
  
  wire  [(dq_data_width_p>>3)-1:0] ddr_dm;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n;
  wire       [dq_data_width_p-1:0] ddr_dq;

  logic [burst_data_width_lp-1] wdata_array[integer];
  logic [ui_addr_width_p] waddr_queue, raddr_queue[$];
  logic [ui_addr_width_p] waddr, raddr;
  logic [burst_data_width_lp-1] wdata, rdata;

  wire [ui_burst_length_p-1:0] sipo_valid_lo;
  wire [ui_burst_length_p-1:0][ui_data_width_p-1:0] sipo_data_lo;
  wire [$clog2(ui_burst_length_p):0] sipo_yumi_cnt_li;
  wire [burst_data_width_lp-1:0] sipo_data;

  logic [ui_addr_width_p] rx_addr;
  logic [burst_data_width_lp-1:0] tx_data, rx_data;

  integer read_transactions;

`include "tasks.v"

  initial begin
    dmc_p.trefi = 1023;
    dmc_p.tmrd = 1;
    dmc_p.trfc = 15;
    dmc_p.trc = 10;
    dmc_p.trp = 2;
    dmc_p.tras = 7;
    dmc_p.trrd = 1;
    dmc_p.trcd = 2;
    dmc_p.twr = 10;
    dmc_p.twtr = 7;
    dmc_p.trtp = 10;
    dmc_p.tcas = 3;
    dmc_p.col_width = 11;
    dmc_p.row_width = 14;
    dmc_p.bank_width = 2;
    dmc_p.dqs_sel_cal = 3;
    dmc_p.init_cycles = 40010;
    dmc_p.bank_pos = 25;
    force dmc_inst.dmc_clk_rst_gen.btc_async_reset.tag_data_reg.data_r = 0;
    force dmc_inst.dmc_clk_rst_gen.dly_lines[0].dly_line_inst.ctrl_rrr = 31;
    force dmc_inst.dmc_clk_rst_gen.dly_lines[1].dly_line_inst.ctrl_rrr = 31;
    force dmc_inst.dmc_clk_rst_gen.dly_lines[2].dly_line_inst.ctrl_rrr = 31;
    force dmc_inst.dmc_clk_rst_gen.dly_lines[3].dly_line_inst.ctrl_rrr = 31;
    force dmc_inst.dmc_clk_rst_gen.clk_gen_ds_inst.reset_i = 1'b1;
    force dmc_inst.dmc_clk_rst_gen.clk_gen_ds_inst.strobe_r = 1'b0;
    #100;
    force dmc_inst.dmc_clk_rst_gen.clk_gen_ds_inst.reset_i = 1'b0;
    force dmc_inst.dmc_clk_rst_gen.clk_gen_ds_inst.strobe_r = 1'b1;
  end

  bsg_dmc #
    (.num_adgs_p            ( clk_gen_num_adgs_p  )
    ,.ui_addr_width_p       ( ui_addr_width_p     )
    ,.ui_data_width_p       ( ui_data_width_p     )
    ,.burst_data_width_p    ( burst_data_width_lp )
    ,.dq_data_width_p       ( dq_data_width_p     )
    ,.cmd_afifo_depth_p     ( cmd_afifo_depth_p   )
    ,.cmd_sfifo_depth_p     ( cmd_sfifo_depth_p   ))
  dmc_inst
    (.async_reset_tag_i     ( dmc_reset_tag_lines_lo       )
    ,.bsg_dly_tag_i         ( dmc_dly_tag_lines_lo         )
    ,.bsg_dly_trigger_tag_i ( dmc_dly_trigger_tag_lines_lo )
    ,.bsg_ds_tag_i          ( dmc_ds_tag_lines_lo          )

    ,.dmc_p_i               ( dmc_p               )

    ,.sys_reset_i           ( sys_reset           )

    ,.app_addr_i            ( app_addr            )
    ,.app_cmd_i             ( app_cmd             )
    ,.app_en_i              ( app_en              )
    ,.app_rdy_o             ( app_rdy             )
    ,.app_wdf_wren_i        ( app_wdf_wren        )
    ,.app_wdf_data_i        ( app_wdf_data        )
    ,.app_wdf_mask_i        ( app_wdf_mask        )
    ,.app_wdf_end_i         ( app_wdf_end         )
    ,.app_wdf_rdy_o         ( app_wdf_rdy         )
    ,.app_rd_data_valid_o   ( app_rd_data_valid   )
    ,.app_rd_data_o         ( app_rd_data         )
    ,.app_rd_data_end_o     ( app_rd_data_end     )
    ,.app_ref_req_i         ( 1'b0                )
    ,.app_ref_ack_o         ( app_ref_ack         )
    ,.app_zq_req_i          ( 1'b0                )
    ,.app_zq_ack_o          ( app_zq_ack          )
    ,.app_sr_req_i          ( 1'b0                )
    ,.app_sr_active_o       ( app_sr_active       )

    ,.init_calib_complete_o ( init_calib_complete )

    ,.ddr_ck_p_o            ( ddr_ck_p            )
    ,.ddr_ck_n_o            ( ddr_ck_n            )
    ,.ddr_cke_o             ( ddr_cke             )
    ,.ddr_ba_o              ( ddr_ba              )
    ,.ddr_addr_o            ( ddr_addr            )
    ,.ddr_cs_n_o            ( ddr_cs_n            )
    ,.ddr_ras_n_o           ( ddr_ras_n           )
    ,.ddr_cas_n_o           ( ddr_cas_n           )
    ,.ddr_we_n_o            ( ddr_we_n            )
    ,.ddr_reset_n_o         ( ddr_reset_n         )
    ,.ddr_odt_o             ( ddr_odt             )

    ,.ddr_dm_oen_o          ( ddr_dm_oen_lo       )
    ,.ddr_dm_o              ( ddr_dm_lo           )
    ,.ddr_dqs_p_oen_o       ( ddr_dqs_p_oen_lo    )
    ,.ddr_dqs_p_ien_o       ( ddr_dqs_p_ien_lo    )
    ,.ddr_dqs_p_o           ( ddr_dqs_p_lo        )
    ,.ddr_dqs_p_i           ( ddr_dqs_p_li        )
    ,.ddr_dqs_n_oen_o       ( ddr_dqs_n_oen_lo    )
    ,.ddr_dqs_n_ien_o       ( ddr_dqs_n_ien_lo    )
    ,.ddr_dqs_n_o           ( ddr_dqs_n_lo        )
    ,.ddr_dqs_n_i           ( ddr_dqs_n_li        )
    ,.ddr_dq_oen_o          ( ddr_dq_oen_lo       )
    ,.ddr_dq_o              ( ddr_dq_lo           )
    ,.ddr_dq_i              ( ddr_dq_li           )

    ,.ui_clk_i              ( ui_clk              )
    ,.dfi_clk_2x_i          ( dfi_clk_2x          )
    ,.dfi_clk_1x_o          ( dfi_clk_1x          )
    ,.ui_clk_sync_rst_o     ( ui_clk_sync_rst     )
    ,.device_temp_o         ( device_temp         ));

  generate
    for(i=0;i<dq_group_lp;i++) begin: dm_io
      assign ddr_dm[i]       = !ddr_dm_oen_lo[i]? ddr_dm_lo[i]: 1'bz;
    end
    for(i=0;i<dq_group_lp;i++) begin: dqs_io
      assign ddr_dqs_p[i]    = !ddr_dqs_p_oen_lo[i]? ddr_dqs_p_lo[i]: 1'bz;
      assign ddr_dqs_p_li[i] = !ddr_dqs_p_ien_lo[i]? ddr_dqs_p[i]: 1'b0;
      assign ddr_dqs_n[i]    = !ddr_dqs_n_oen_lo[i]? ddr_dqs_n_lo[i]: 1'bz;
      assign ddr_dqs_n_li[i] = !ddr_dqs_n_ien_lo[i]? ddr_dqs_n[i]: 1'b1;
    end
    for(i=0;i<dq_data_width_p;i++) begin: dq_io
      assign ddr_dq[i]    = !ddr_dq_oen_lo[i]? ddr_dq_lo[i]: 1'bz;
      assign ddr_dq_li[i] = ddr_dq[i];
    end
  endgenerate

  generate
    for(i=0;i<2;i++) begin: lpddr
      mobile_ddr mobile_ddr_inst
        (.Dq    (ddr_dq[16*i+15:16*i])
        ,.Dqs   (ddr_dqs_p[2*i+1:2*i])
        ,.Addr  (ddr_addr[13:0])
        ,.Ba    (ddr_ba[1:0])
        ,.Clk   (ddr_ck_p)
        ,.Clk_n (ddr_ck_n)
        ,.Cke   (ddr_cke)
        ,.Cs_n  (ddr_cs_n)
        ,.Ras_n (ddr_ras_n)
        ,.Cas_n (ddr_cas_n)
        ,.We_n  (ddr_we_n)
        ,.Dm    (ddr_dm[2*i+1:2*i]));
    end
  endgenerate

  always #1.25 dfi_clk_2x = ~dfi_clk_2x;
  //always #0.625 ui_clk = ~ui_clk;
  always #2.5 ui_clk = ~ui_clk;

  initial begin
    //$vcdplusmemon();
    app_en = 0;
    app_wdf_wren = 0;
    app_wdf_end = 0;
  end

  initial begin
    $display("\n#### Regression test started ####");
    sys_reset = 1'b1;
    ui_clk = 1'b0;
    dfi_clk_2x = 1'b0;
    #1000 sys_reset=1'b0;
    repeat(100) @(posedge ui_clk);
    for(k=0;k<256;k++) begin
      waddr = k*dq_burst_length_lp;
      wdata = 0;
      for(j=0;j<ui_burst_length_p;j++)
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

  for(i=0;i<ui_burst_length_p;i++) begin
    assign sipo_data[ui_data_width_p*i+:ui_data_width_p] = sipo_data_lo[i];
  end

  bsg_serial_in_parallel_out #
    (.width_p    ( ui_data_width_p   )
    ,.els_p      ( ui_burst_length_p ))
  sipo
    (.clk_i      ( ui_clk            )
    ,.reset_i    ( ui_clk_sync_rst   )
    ,.valid_i    ( app_rd_data_valid )
    ,.data_i     ( app_rd_data       )
    ,.ready_o    (                   ) 
    ,.valid_o    ( sipo_valid_lo     )
    ,.data_o     ( sipo_data_lo      )
    ,.yumi_cnt_i ( sipo_yumi_cnt_li  ));

  assign sipo_yumi_cnt_li = ($clog2(ui_burst_length_p)+1)'(&sipo_valid_lo? ui_burst_length_p: 0);

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

endmodule
