/**
 *  bsg_cache_non_blocking_pkg.v
 *  
 *  @author tommy
 */

package bsg_cache_non_blocking_pkg;


  // cache opcode
  //
  typedef enum logic [4:0] {
    LB  = 5'b00000        // load byte
    ,LH = 5'b00001        // load half
    ,LW = 5'b00010        // load word
    ,LD = 5'b00011        // load double

    ,LBU = 5'b00100       // load byte   (unsigned)
    ,LHU = 5'b00101       // load half   (unsigned)
    ,LWU = 5'b00110       // load word   (unsigned)
    ,LDU = 5'b00111       // load double (unsigned)

    ,SB  = 5'b01000       // store byte
    ,SH  = 5'b01001       // store half
    ,SW  = 5'b01010       // store word
    ,SD  = 5'b01011       // store double

    ,LM  = 5'b01100       // load mask
    ,SM  = 5'b01101       // store mask

    ,TAGST   = 5'b10000   // tag store
    ,TAGFL   = 5'b10001   // tag flush
    ,TAGLV   = 5'b10010   // tag load valid
    ,TAGLA   = 5'b10011   // tag load address

    ,AFL     = 5'b11000   // address flush
    ,AFLINV  = 5'b11001   // address flush invalidate
    ,AINV    = 5'b11010   // address invalidate

    ,ALOCK   = 5'b11011   // address lock
    ,AUNLOCK = 5'b11100   // address unlock
  } bsg_cache_non_blocking_opcode_e;


  // bsg_cache_pkt_s
  //
  `define declare_bsg_cache_non_blocking_pkt_s(id_width_mp,addr_width_mp,data_width_mp) \
    typedef struct packed {                                     \
      logic [id_width_mp-1:0] id;                               \
      bsg_cache_non_blocking_opcode_e opcode;                   \
      logic [addr_width_mp-1:0] addr;                           \
      logic [data_width_mp-1:0] data;                           \
      logic [(data_width_mp>>3)-1:0] mask;                      \
    } bsg_cache_pkt_s

  `define bsg_cache_non_blocking_pkt_width(addr_width_mp,data_width_mp) \
    (5+id_width_mp+addr_width_mp+data_width_mp+(data_width_mp>>3))


  // cache pkt decode
  //
  typedef struct packed {
    // 00 - byte
    // 01 - half
    // 10 - word
    // 11 - double
    logic [1:0] data_size_op;
    logic sigext_op;
    logic mask_op;
    logic ld_op;
    logic st_op;
    logic tagst_op;
    logic tagfl_op;
    logic taglv_op;
    logic tagla_op;
    logic afl_op;
    logic aflinv_op;
    logic ainv_op;
    logic alock_op;
    logic aunlock_op;
    logic tag_read_op;
  } bsg_cache_non_blocking_decode_s;


  // bsg_cache_dma_pkt_s
  //
  `define declare_bsg_cache_non_blocking__dma_pkt_s(addr_width_mp) \
    typedef struct packed {               \
      logic write_not_read;               \
      logic [addr_width_mp-1:0] addr;     \
    } bsg_cache_dma_pkt_s

  `define bsg_cache_non_blocking_dma_pkt_width(addr_width_mp)    \
    (1+addr_width_mp)


  // tag info s
  //
  `define declare_bsg_cache_non_blocking_tag_info_s(tag_width_mp) \
    typedef struct packed {                   \
      logic valid;                            \
      logic lock;                             \
      logic [tag_width_mp-1:0] tag;           \
    } bsg_cache_tag_info_s

  `define bsg_cache_non_blocking_tag_info_width(tag_width_mp) (tag_width_mp+2)


  // stat info s
  //
  `define declare_bsg_cache_non_blocking_stat_info_s(ways_mp)    \
    typedef struct packed {                         \
      logic [ways_mp-1:0] dirty;                    \
      logic [ways_mp-2:0] lru_bits;                 \
    } bsg_cache_non_blocking_stat_info_s

  `define bsg_cache_non_blocking_stat_info_width(ways_mp) \
    (ways_mp+ways_mp-1)


endpackage
