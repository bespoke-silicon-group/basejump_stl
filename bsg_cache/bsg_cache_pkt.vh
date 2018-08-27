/**
 *  bsg_cache_pkt.vh
 */

`ifndef BSG_CACHE_PKT_VH
`define BSG_CACHE_PKT_VH

import bsg_cache_pkg::*;

`define declare_bsg_cache_pkt_s(addr_width_p, data_width_p)   \
  typedef struct packed {                                     \
    logic sigext;                                             \
    logic [(data_width_p>>3)-1:0] mask;                       \
    bsg_cache_opcode_e opcode;                                \
    logic [addr_width_p-1:0] addr;                            \
    logic [data_width_p-1:0] data;                            \
  } bsg_cache_pkt_s

`define bsg_cache_pkt_width(addr_width_p, data_width_p) \
  (1+(data_width_p>>3)+5+addr_width_p+data_width_p)

`endif
