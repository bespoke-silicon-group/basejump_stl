  wire bsg_tag_s        dmc_reset_tag_lines_lo;
  wire bsg_tag_s  [3:0] dmc_dly_tag_lines_lo;
  wire bsg_tag_s  [3:0] dmc_dly_trigger_tag_lines_lo;
  wire bsg_tag_s        dmc_ds_tag_lines_lo;

  bsg_dmc_s                        dmc_p;

  logic                            sys_reset;
  // User Data interface signals
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

  logic                            app_ref_req;
  wire                             app_ref_ack;
  logic                            app_zq_req;
  wire                             app_zq_ack;
  logic                            app_sr_req;
  wire                             app_sr_active;
  // Status signal
  wire                             init_calib_complete;

  logic                            ui_clk;
  logic                            dfi_clk_2x;
  wire                             dfi_clk_1x;
  wire                             ui_clk_sync_rst;

  wire                      [11:0] device_temp;

 //DDR signals
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

