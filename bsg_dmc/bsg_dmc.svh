`ifndef BSG_DMC_VH
`define BSG_DMC_VH

  `include "bsg_defines.sv"

  // app_cmd_e for each command or data
  // payload can be write data or additional commands
  // addr width <= data+mask width. these zeros are padded for cmd trace payloads.
 `define declare_bsg_dmc_trace_entry_s(data_width_mp, addr_width_mp) \
  	typedef struct packed { \
      app_cmd_e app_cmd; \
  	  union packed { \
        struct packed { \
          logic [data_width_mp+(data_width_mp>>3)-addr_width_mp-1:0] pad; \
  	      logic [addr_width_mp - 1:0] addr; \
        } cmd; \
        struct packed { \
          logic [(data_width_mp>>3) - 1:0] mask; \
          logic [data_width_mp - 1:0] data; \
        } wdata; \
      } payload; \
    } bsg_dmc_trace_entry_s

  `define declare_app_cmd_afifo_entry_s(addr_width_mp) \
    typedef struct packed {           \
      app_cmd_e cmd;                  \
      logic [addr_width_mp-1:0] addr; \
    } app_cmd_afifo_entry_s

  `define bsg_dmc_trace_entry_width(data_width_mp, addr_width_mp) \
    ($bits(app_cmd_e)+data_width_mp+(data_width_mp>>3))

  `define app_cmd_afifo_entry_width(addr_width_mp) \
    ($bits(app_cmd_e)+addr_width_mp)

`endif
