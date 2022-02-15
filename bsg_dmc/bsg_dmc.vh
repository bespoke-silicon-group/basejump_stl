`ifndef BSG_DMC_VH
`define BSG_DMC_VH

  `include "bsg_defines.v"

  `define declare_dmc_trace_entry_s(addr_width_mp, burst_width_mp, data_width_mp) \
  	typedef struct packed { \
  		app_cmd_e cmd; \
  		logic [addr_width_mp - 1:0] addr; \
  		logic [burst_width_mp*data_width_mp -1 :0] data; \
  		logic [(burst_width_mp*data_width_mp>>3) - 1 :0] mask;} dmc_trace_entry_s; 

  `define declare_app_cmd_afifo_entry_s(addr_width_mp) \
    typedef struct packed {           \
      app_cmd_e cmd;                  \
      logic [addr_width_mp-1:0] addr; \
    } app_cmd_afifo_entry_s;

`endif

