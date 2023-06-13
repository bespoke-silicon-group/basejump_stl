`ifndef BSG_CACHE_NON_BLOCKING_VH
`define BSG_CACHE_NON_BLOCKING_VH

  `include "bsg_defines.sv"

  // bsg_cache_pkt_s
  //
  `define declare_bsg_cache_non_blocking_pkt_s(id_width_mp,addr_width_mp,data_width_mp) \
    typedef struct packed {                                     \
      logic [id_width_mp-1:0] id;                               \
      bsg_cache_non_blocking_opcode_e opcode;                   \
      logic [addr_width_mp-1:0] addr;                           \
      logic [data_width_mp-1:0] data;                           \
      logic [(data_width_mp>>3)-1:0] mask;                      \
    } bsg_cache_non_blocking_pkt_s


  `define bsg_cache_non_blocking_pkt_width(id_width_mp,addr_width_mp,data_width_mp) \
    ($bits(bsg_cache_non_blocking_opcode_e)+id_width_mp+addr_width_mp+data_width_mp+(data_width_mp>>3))


  // DMA command
  //
  `define declare_bsg_cache_non_blocking_dma_cmd_s(ways_mp,sets_mp,tag_width_mp) \
    typedef struct packed {                         \
      logic [`BSG_SAFE_CLOG2(ways_mp)-1:0] way_id;  \
      logic [`BSG_SAFE_CLOG2(sets_mp)-1:0] index;   \
      logic refill;                                 \
      logic evict;                                  \
      logic [tag_width_mp-1:0] refill_tag;          \
      logic [tag_width_mp-1:0] evict_tag;           \
    } bsg_cache_non_blocking_dma_cmd_s


  `define bsg_cache_non_blocking_dma_cmd_width(ways_mp,sets_mp,tag_width_mp) \
    (`BSG_SAFE_CLOG2(ways_mp)+`BSG_SAFE_CLOG2(sets_mp)+((1+tag_width_mp)*2))


  // DMA packet
  //
  `define declare_bsg_cache_non_blocking_dma_pkt_s(addr_width_mp) \
    typedef struct packed {               \
      logic write_not_read;               \
      logic [addr_width_mp-1:0] addr;     \
    } bsg_cache_non_blocking_dma_pkt_s


  `define bsg_cache_non_blocking_dma_pkt_width(addr_width_mp)    \
    (1+addr_width_mp)


  // data_mem pkt s
  //
  `define declare_bsg_cache_non_blocking_data_mem_pkt_s(ways_mp,sets_mp,block_size_in_words_mp,data_width_mp) \
    typedef struct packed {                                                                \
      logic write_not_read;                                                                \
      logic sigext_op;                                                                     \
      logic mask_op;                                                                       \
      logic [1:0] size_op;                                                                 \
      logic [`BSG_SAFE_CLOG2(data_width_mp>>3)-1:0] byte_sel;                               \
      logic [`BSG_SAFE_CLOG2(ways_mp)-1:0] way_id;                                          \
      logic [`BSG_SAFE_CLOG2(sets_mp)+`BSG_SAFE_CLOG2(block_size_in_words_mp)-1:0] addr;    \
      logic [data_width_mp-1:0] data;                                                       \
      logic [(data_width_mp>>3)-1:0] mask;                                                  \
    } bsg_cache_non_blocking_data_mem_pkt_s

  `define bsg_cache_non_blocking_data_mem_pkt_width(ways_mp,sets_mp,block_size_in_words_mp,data_width_mp) \
    (1+1+1+2+`BSG_SAFE_CLOG2(data_width_mp>>3)+`BSG_SAFE_CLOG2(ways_mp)+        \
      `BSG_SAFE_CLOG2(sets_mp)+`BSG_SAFE_CLOG2(block_size_in_words_mp)+data_width_mp+(data_width_mp>>3))


  // tag info s
  //
  `define declare_bsg_cache_non_blocking_tag_info_s(tag_width_mp) \
    typedef struct packed {                   \
      logic valid;                            \
      logic lock;                             \
      logic [tag_width_mp-1:0] tag;           \
    } bsg_cache_non_blocking_tag_info_s


  `define bsg_cache_non_blocking_tag_info_width(tag_width_mp) \
    (tag_width_mp+2)

  
  // tag_mem_pkt
  //
  `define declare_bsg_cache_non_blocking_tag_mem_pkt_s(ways_mp,sets_mp,data_width_mp,tag_width_mp) \
    typedef struct packed {                               \
      logic [`BSG_SAFE_CLOG2(ways_mp)-1:0] way_id;        \
      logic [`BSG_SAFE_CLOG2(sets_mp)-1:0] index;         \
      logic [data_width_mp-1:0] data;                     \
      logic [tag_width_mp-1:0] tag;                       \
      bsg_cache_non_blocking_tag_op_e opcode;             \
    } bsg_cache_non_blocking_tag_mem_pkt_s


  `define bsg_cache_non_blocking_tag_mem_pkt_width(ways_mp,sets_mp,data_width_mp,tag_width_mp) \
    (`BSG_SAFE_CLOG2(ways_mp)+`BSG_SAFE_CLOG2(sets_mp)+data_width_mp+tag_width_mp+$bits(bsg_cache_non_blocking_tag_op_e)) 


  // stat info s
  //
  `define declare_bsg_cache_non_blocking_stat_info_s(ways_mp)    \
    typedef struct packed {                         \
      logic [ways_mp-1:0] dirty;                    \
      logic [ways_mp-2:0] lru_bits;                 \
    } bsg_cache_non_blocking_stat_info_s


  `define bsg_cache_non_blocking_stat_info_width(ways_mp) \
    (ways_mp+ways_mp-1)


  // stat_mem pkt
  //
  `define declare_bsg_cache_non_blocking_stat_mem_pkt_s(ways_mp,sets_mp) \
    typedef struct packed {                               \
      bsg_cache_non_blocking_stat_op_e opcode;            \
      logic [`BSG_SAFE_CLOG2(ways_mp)-1:0] way_id;         \
      logic [`BSG_SAFE_CLOG2(sets_mp)-1:0] index;          \
    } bsg_cache_non_blocking_stat_mem_pkt_s
 
  `define bsg_cache_non_blocking_stat_mem_pkt_width(ways_mp,sets_mp) \
    ($bits(bsg_cache_non_blocking_stat_op_e)+`BSG_SAFE_CLOG2(ways_mp)+`BSG_SAFE_CLOG2(sets_mp)) 


  // miss FIFO entry
  //
  `define declare_bsg_cache_non_blocking_miss_fifo_entry_s(id_width_mp,addr_width_mp,data_width_mp) \
    typedef struct packed {                   \
      logic write_not_read;                   \
      logic block_load;                       \
      logic [1:0] size_op;                    \
      logic sigext_op;                        \
      logic mask_op;                          \
      logic [id_width_mp-1:0] id;             \
      logic [addr_width_mp-1:0] addr;         \
      logic [data_width_mp-1:0] data;         \
      logic [(data_width_mp>>3)-1:0] mask;    \
    } bsg_cache_non_blocking_miss_fifo_entry_s;  

  `define bsg_cache_non_blocking_miss_fifo_entry_width(id_width_mp,addr_width_mp,data_width_mp) \
    (1+1+2+1+1+id_width_mp+addr_width_mp+data_width_mp+(data_width_mp>>3)) 


  // MHU dff
  //
  `define declare_bsg_cache_non_blocking_mhu_dff_s(id_width_mp,addr_width_mp,tag_width_mp,ways_mp) \
    typedef struct packed {                                                                 \
      bsg_cache_non_blocking_decode_s decode;                                               \
      logic [ways_mp-1:0] valid;                                                           \
      logic [ways_mp-1:0] lock;                                                            \
      logic [ways_mp-1:0][tag_width_mp-1:0] tag;                                           \
      logic [`BSG_SAFE_CLOG2(ways_mp)-1:0] tag_hit_way;                                  \
      logic tag_hit_found;                                                                \
      logic [id_width_mp-1:0] id;                                                          \
      logic [addr_width_mp-1:0] addr;                                                      \
    } bsg_cache_non_blocking_mhu_dff_s


  `define bsg_cache_non_blocking_mhu_dff_width(id_width_mp,addr_width_mp,tag_width_mp,ways_mp) \
    ($bits(bsg_cache_non_blocking_decode_s)+ways_mp+ways_mp+(ways_mp*tag_width_mp)+`BSG_SAFE_CLOG2(ways_mp)+1+id_width_mp+addr_width_mp)

`endif

