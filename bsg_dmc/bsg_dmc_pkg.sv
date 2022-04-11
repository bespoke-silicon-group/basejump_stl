
package bsg_dmc_pkg;
  import bsg_tag_pkg::*;

  typedef struct packed {
    logic [15:0] trefi;
    logic  [3:0] tmrd;
    logic  [3:0] trfc;
    logic  [3:0] trc;
    logic  [3:0] trp;
    logic  [3:0] tras;
    logic  [3:0] trrd;
    logic  [3:0] trcd;
    logic  [3:0] twr;
    logic  [3:0] twtr;
    logic  [3:0] trtp;
    logic  [3:0] tcas;
    logic  [3:0] col_width;
    logic  [3:0] row_width;
    logic  [1:0] bank_width;
    logic  [5:0] bank_pos;
    logic  [2:0] dqs_sel_cal;
    logic [15:0] init_cycles;
    logic [15:0] tcalr;
    // Init calib read timing should not exceed refresh timing
    // Ideally, we would set this to ticks.
    logic [15:0] init_calib_reads;
    logic  [7:0] calib_num_reads;
  } bsg_dmc_s;

  typedef enum logic [3:0]
    {RP = 4'b0011 // read with auto precharge
    ,WP = 4'b0010 // write with auto precharge
    ,RD = 4'b0001 // read
    ,WR = 4'b0000 // write

    // Only used in trace debug module
    ,TEX = 4'b1000 // execute commands in trace fifo
    ,TWD = 4'b1001 // write data, non-terminating
    ,TWT = 4'b1010 // write data, terminating
    ,TNP = 4'b1111 // NOP, do nothing
  } app_cmd_e;

  typedef enum logic [3:0]
    {LMR      = 4'b0000
    ,REF      = 4'b0001
    ,PRE      = 4'b0010
    ,ACT      = 4'b0011
    ,WRITE    = 4'b0100
    ,READ     = 4'b0101
    ,BST      = 4'b0110
    ,NOP      = 4'b0111
    ,DESELECT = 4'b1xxx
  } dfi_cmd_e;

  typedef struct packed {
    dfi_cmd_e cmd;
    logic rsv_19;
    logic [2:0] ba;
    logic [15:0] addr;
  } dfi_cmd_sfifo_entry_s;

  localparam bsg_dmc_tag_client_width_gp = 8;

  typedef struct packed {
    bsg_tag_s         ds;
    bsg_tag_s [3:0]   dly_trigger;
    bsg_tag_s [3:0]   dly;
    bsg_tag_s         async_reset;
  } bsg_dmc_dly_tag_lines_s;
  localparam tag_dmc_dly_local_els_gp = $bits(bsg_dmc_dly_tag_lines_s)/$bits(bsg_tag_s);

  typedef struct packed {
    bsg_tag_s calib_num_reads;
    bsg_tag_s [1:0] init_calib_reads;
    bsg_tag_s [1:0] tcalr;
    bsg_tag_s [1:0] init_cycles;
    bsg_tag_s bank_pos_bank_width;
    bsg_tag_s row_width_col_width;
    bsg_tag_s dqs_sel_cal_tcas;
    bsg_tag_s trtp_twtr;
    bsg_tag_s twr_trcd;
    bsg_tag_s trrd_tras;
    bsg_tag_s trp_trc;
    bsg_tag_s trfc_tmrd;
    bsg_tag_s [1:0] trefi;
  } bsg_dmc_cfg_tag_lines_s;
  localparam tag_dmc_cfg_local_els_gp = $bits(bsg_dmc_cfg_tag_lines_s)/$bits(bsg_tag_s);

  typedef struct packed {
    bsg_tag_s test_mode;
    bsg_tag_s stall_transactions;
    bsg_tag_s async_reset;
  } bsg_dmc_sys_tag_lines_s;
  localparam tag_dmc_sys_local_els_gp = $bits(bsg_dmc_sys_tag_lines_s)/$bits(bsg_tag_s);

  // TODO: Align with clk gen lines
  typedef struct packed {
    bsg_tag_s sel;
    bsg_tag_s ds;
    bsg_tag_s osc_trigger;
    bsg_tag_s osc;
    bsg_tag_s async_reset;
  } bsg_dmc_osc_tag_lines_s;
  localparam tag_dmc_osc_local_els_gp = $bits(bsg_dmc_osc_tag_lines_s)/$bits(bsg_tag_s);

endpackage // bsg_dmc_pkg
