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
    logic  [1:0] dqs_sel_cal;
    logic  [3:0] init_cmd_cnt;
    logic  [5:0] bank_pos;
  } bsg_dmc_s;
endpackage // bsg_dmc_pkg
