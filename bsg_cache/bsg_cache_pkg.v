/**
 *  bsg_cache_pkg.v
 *  
 *  @author tommy
 */

`include "bsg_defines.v"

package bsg_cache_pkg;

  // These subopcodes are intended to match the low 4 bits of the
  //   corresponding bsg_cache_pkt opcode, to simplify decoding
  typedef enum logic [3:0] {
    e_cache_amo_swap        = 4'b0000
    ,e_cache_amo_add        = 4'b0001
    ,e_cache_amo_xor        = 4'b0010
    ,e_cache_amo_and        = 4'b0011
    ,e_cache_amo_or         = 4'b0100
    ,e_cache_amo_min        = 4'b0101
    ,e_cache_amo_max        = 4'b0110
    ,e_cache_amo_minu       = 4'b0111
    ,e_cache_amo_maxu       = 4'b1000
  } bsg_cache_amo_subop_e;

  localparam amo_support_level_none_lp       = '0;
  localparam amo_support_level_swap_lp       = amo_support_level_none_lp
    | (1 << e_cache_amo_swap);
  localparam amo_support_level_logical_lp    = amo_support_level_swap_lp
    | (1 << e_cache_amo_xor)
    | (1 << e_cache_amo_and)
    | (1 << e_cache_amo_or);
  localparam amo_support_level_arithmetic_lp = amo_support_level_logical_lp
    | (1 << e_cache_amo_add)
    | (1 << e_cache_amo_min)
    | (1 << e_cache_amo_max)
    | (1 << e_cache_amo_minu)
    | (1 << e_cache_amo_maxu);

  // cache opcode
  //
  typedef enum logic [5:0] {
    LB      = 6'b000000        // load byte
    ,LH     = 6'b000001        // load half
    ,LW     = 6'b000010        // load word
    ,LD     = 6'b000011        // load double

    ,LBU    = 6'b000100       // load byte   (unsigned)
    ,LHU    = 6'b000101       // load half   (unsigned)
    ,LWU    = 6'b000110       // load word   (unsigned)
    ,LDU    = 6'b000111       // load double (unsigned)

    ,SB     = 6'b001000       // store byte
    ,SH     = 6'b001001       // store half
    ,SW     = 6'b001010       // store word
    ,SD     = 6'b001011       // store double

    ,LM     = 6'b001100       // load mask
    ,SM     = 6'b001101       // store mask

    ,TAGST   = 6'b010000      // tag store
    ,TAGFL   = 6'b010001      // tag flush
    ,TAGLV   = 6'b010010      // tag load valid
    ,TAGLA   = 6'b010011      // tag load address

    ,AFL     = 6'b011000      // address flush
    ,AFLINV  = 6'b011001      // address flush invalidate
    ,AINV    = 6'b011010      // address invalidate

    ,ALOCK   = 6'b011011      // address lock
    ,AUNLOCK = 6'b011100      // address unlock
   
    // 32-bit atomic
    ,AMOSWAP_W = 6'b100000    // atomic swap
    ,AMOADD_W  = 6'b100001    // atomic add
    ,AMOXOR_W  = 6'b100010    // atomic xor 
    ,AMOAND_W  = 6'b100011    // atomic and
    ,AMOOR_W   = 6'b100100    // atomic or
    ,AMOMIN_W  = 6'b100101    // atomic min
    ,AMOMAX_W  = 6'b100110    // atomic max
    ,AMOMINU_W = 6'b100111    // atomic min unsigned
    ,AMOMAXU_W = 6'b101000    // atomic max unsigned

    // 64-bit atomic
    ,AMOSWAP_D = 6'b110000    // atomic swap
    ,AMOADD_D  = 6'b110001    // atomic add
    ,AMOXOR_D  = 6'b110010    // atomic xor 
    ,AMOAND_D  = 6'b110011    // atomic and
    ,AMOOR_D   = 6'b110100    // atomic or
    ,AMOMIN_D  = 6'b110101    // atomic min
    ,AMOMAX_D  = 6'b110110    // atomic max
    ,AMOMINU_D = 6'b110111    // atomic min unsigned
    ,AMOMAXU_D = 6'b111000    // atomic max unsigned
  } bsg_cache_opcode_e;

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
   
    logic atomic_op;
    bsg_cache_amo_subop_e amo_subop;
  } bsg_cache_decode_s;


  // bsg_cache_dma_pkt_s
  //
  `define declare_bsg_cache_dma_pkt_s(addr_width_mp) \
    typedef struct packed {               \
      logic write_not_read;               \
      logic [addr_width_mp-1:0] addr;     \
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
      logic lock;                           \
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
      logic [`BSG_SAFE_CLOG2(ways_mp)-1:0] way_id;    \
    } bsg_cache_sbuf_entry_s 

  `define bsg_cache_sbuf_entry_width(addr_width_mp, data_width_mp, ways_mp) \
    (addr_width_mp+data_width_mp+(data_width_mp>>3)+`BSG_SAFE_CLOG2(ways_mp))

endpackage
