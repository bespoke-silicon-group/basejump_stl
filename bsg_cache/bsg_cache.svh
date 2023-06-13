 // Enum values in the structs come from bsg_cache_pkg.sv

`ifndef BSG_CACHE_VH
`define BSG_CACHE_VH
  // bsg_cache_pkt_s
  //
  `define declare_bsg_cache_pkt_s(addr_width_mp, data_width_mp) \
    typedef struct packed {                                     \
      bsg_cache_opcode_e opcode;                                \
      logic [addr_width_mp-1:0] addr;                           \
      logic [data_width_mp-1:0] data;                           \
      logic [(data_width_mp>>3)-1:0] mask;                      \
    } bsg_cache_pkt_s

  `define bsg_cache_pkt_width(addr_width_mp, data_width_mp) \
    ($bits(bsg_cache_opcode_e)+addr_width_mp+data_width_mp+(data_width_mp>>3))

  // bsg_cache_dma_pkt_s
  //
  `define declare_bsg_cache_dma_pkt_s(addr_width_mp, mask_width_mp) \
    typedef struct packed {                                         \
      logic write_not_read;                                         \
      logic [addr_width_mp-1:0] addr;                               \
      logic [mask_width_mp-1:0] mask;                               \
    } bsg_cache_dma_pkt_s

  `define bsg_cache_dma_pkt_width(addr_width_mp, mask_width_mp)     \
    (1+addr_width_mp+mask_width_mp)

  // tag info s
  //
  `define declare_bsg_cache_tag_info_s(tag_width_mp) \
    typedef struct packed {                   \
      logic valid;                            \
      logic lock;                             \
      logic [tag_width_mp-1:0] tag;           \
    } bsg_cache_tag_info_s

  `define bsg_cache_tag_info_width(tag_width_mp) (tag_width_mp+2)

  // stat info s
  //
  `define declare_bsg_cache_stat_info_s(ways_mp)    \
    typedef struct packed {                         \
      logic [ways_mp-1:0] dirty;                    \
      logic [ways_mp-2:0] lru_bits;                 \
    } bsg_cache_stat_info_s

  `define bsg_cache_stat_info_width(ways_mp) \
    (ways_mp+ways_mp-1)

  // sbuf entry s
  //
  `define declare_bsg_cache_sbuf_entry_s(addr_width_mp, data_width_mp, ways_mp) \
    typedef struct packed {                       \
      logic [addr_width_mp-1:0] addr;             \
      logic [data_width_mp-1:0] data;             \
      logic [(data_width_mp>>3)-1:0] mask;        \
      logic [`BSG_SAFE_CLOG2(ways_mp)-1:0] way_id;\
    } bsg_cache_sbuf_entry_s

  `define bsg_cache_sbuf_entry_width(addr_width_mp, data_width_mp, ways_mp) \
    (addr_width_mp+data_width_mp+(data_width_mp>>3)+`BSG_SAFE_CLOG2(ways_mp))

  // wormhole
  //
  `define declare_bsg_cache_wh_header_flit_s(wh_flit_width_mp,wh_cord_width_mp,wh_len_width_mp,wh_cid_width_mp) \
    typedef struct packed { \
      logic [wh_flit_width_mp-(wh_cord_width_mp*2)-$bits(bsg_cache_wh_opcode_e)-wh_len_width_mp-(wh_cid_width_mp*2)-1:0] unused; \
      bsg_cache_wh_opcode_e opcode; \
      logic [wh_cid_width_mp-1:0] src_cid; \
      logic [wh_cord_width_mp-1:0] src_cord; \
      logic [wh_cid_width_mp-1:0] cid; \
      logic [wh_len_width_mp-1:0] len; \
      logic [wh_cord_width_mp-1:0] cord; \
    } bsg_cache_wh_header_flit_s

`endif //  `ifndef BSG_CACHE_VH
