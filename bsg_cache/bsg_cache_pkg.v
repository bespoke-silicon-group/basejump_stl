/**
 *  bsg_cache_pkg.v
 *  
 *  @author tommy
 */

package bsg_cache_pkg;

  // cache opcode
  //
  typedef enum logic [4:0] {
    LB = 5'b00000         // load byte
    ,LH = 5'b00001        // load half
    ,LW = 5'b00010        // load word
    ,LD = 5'b00011        // load double (reserved)
    ,LM = 5'b00100        // load mask
    ,SB = 5'b01000        // store byte
    ,SH = 5'b01001        // store half
    ,SW = 5'b01010        // store word
    ,SD = 5'b01011        // store double (reserved)
    ,SM = 5'b01100        // store mask
    ,TAGST = 5'b10000     // tag store
    ,TAGFL = 5'b10001     // tag flush
    ,TAGLV = 5'b10010     // tag load valid
    ,TAGLA = 5'b10011     // tag load address
    ,AFL = 5'b11000       // address flush
    ,AFLINV = 5'b11001    // address flush invalidate
    ,AINV = 5'b11010      // address invalidate
  } bsg_cache_opcode_e;

  // bsg_cache_pkt_s
  //
  `define declare_bsg_cache_pkt_s(addr_width_mp, data_width_mp)   \
    typedef struct packed {                                     \
      logic sigext;                                             \
      logic [(data_width_mp>>3)-1:0] mask;                       \
      bsg_cache_opcode_e opcode;                                \
      logic [addr_width_mp-1:0] addr;                            \
      logic [data_width_mp-1:0] data;                            \
    } bsg_cache_pkt_s

  `define bsg_cache_pkt_width(addr_width_mp, data_width_mp) \
    (1+(data_width_mp>>3)+5+addr_width_mp+data_width_mp)

  // bsg_cache_dma_pkt_s
  //
  `define declare_bsg_cache_dma_pkt_s(addr_width_mp) \
    typedef struct packed {                         \
      logic write_not_read;                         \
      logic [addr_width_mp-1:0] addr;                \
    } bsg_cache_dma_pkt_s

  `define bsg_cache_dma_pkt_width(addr_width_mp)    \
    (1+addr_width_mp)

  // dma opcode (one-hot)
  //
  typedef enum logic [3:0] {
    e_dma_nop               = 4'b0000
    ,e_dma_send_fill_addr   = 4'b0001
    ,e_dma_send_evict_addr  = 4'b0010
    ,e_dma_get_fill_data    = 4'b0100
    ,e_dma_send_evict_data  = 4'b1000
  } bsg_cache_dma_cmd_e;

  // tag info s
  //
  `define declare_bsg_cache_tag_info_s(tag_width_mp) \
    typedef struct packed {                   \
      logic valid;                            \
      logic [tag_width_mp-1:0] tag;           \
    } bsg_cache_tag_info_s

  `define bsg_cache_tag_info_width(tag_width_mp) (tag_width_mp+1)

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
      logic [`BSG_SAFE_CLOG2(ways_mp)-1:0] way_id;    \
    } bsg_cache_sbuf_entry_s 

  `define bsg_cache_sbuf_entry_width(addr_width_mp, data_width_mp, ways_mp) \
    (addr_width_mp+data_width_mp+(data_width_mp>>3)+`BSG_SAFE_CLOG2(ways_mp))

endpackage
