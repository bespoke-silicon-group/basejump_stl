`ifndef BSG_DMC_VH
`define BSG_DMC_VH

  `include "bsg_defines.v"

  // cmd_wdata_n is the tag data DMC UI command or wdata? 1: wdata, 0: cmd
  // cmd + addr width <= data+mask width. these zeros are padded for cmd trace payloads.
 `define declare_dmc_cmd_trace_entry_s(addr_width_mp, cmd_trace_zero_padding_width_mp) \
  	typedef struct packed { \
      bit [3:0] cmd_wdata_n; \
      bit [cmd_trace_zero_padding_width_mp - 1:0] zeros; \
  	  app_cmd_e cmd; \
  	  logic [addr_width_mp - 1:0] addr; } dmc_cmd_trace_entry_s;    

 `define declare_dmc_wdata_trace_entry_s(data_width_mp, mask_width_mp) \
  	typedef struct packed { \
      logic [data_width_mp - 1:0] data; \
  	  logic [mask_width_mp - 1:0] mask; } dmc_data_trace_entry_s;

  `define declare_app_cmd_afifo_entry_s(addr_width_mp) \
    typedef struct packed {           \
      app_cmd_e cmd;                  \
      logic [addr_width_mp-1:0] addr; \
    } app_cmd_afifo_entry_s;

`endif
