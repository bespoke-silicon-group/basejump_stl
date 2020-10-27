`include "bsg_defines.v"

package bsg_dmc_pkg;
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
  } bsg_dmc_s;

  typedef enum logic [2:0]
    {RP = 3'b011 // read with auto precharge
    ,WP = 3'b010 // write with auto precharge
    ,RD = 3'b001 // read
    ,WR = 3'b000 // write
  } app_cmd_e;

  `define declare_app_cmd_afifo_entry_s(addr_width_mp) \
    typedef struct packed {           \
      app_cmd_e cmd;                  \
      logic [addr_width_mp-1:0] addr; \
    } app_cmd_afifo_entry_s;

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
endpackage // bsg_dmc_pkg
