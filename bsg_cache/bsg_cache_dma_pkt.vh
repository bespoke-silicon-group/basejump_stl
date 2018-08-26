/**
 *  bsg_cache_dma_pkt.vh
 */

`ifndef BSG_CACHE_DMA_PKT_VH
`define BSG_CACHE_DMA_PKT_VH

`define declare_bsg_cache_dma_pkt_s(addr_width_p) \
  typedef struct packed {                         \
    logic write_not_read;                         \
    logic [addr_width_p-1:0] addr;                \
  } bsg_cache_dma_pkt_s

 `define bsg_cache_dma_pkt_width(addr_width_p)    \
  (1+addr_width_p)

`endif
