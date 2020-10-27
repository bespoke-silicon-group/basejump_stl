/**
 *  bsg_cache_non_blocking_pkg.v
 *  
 *  @author tommy
 */

`include "bsg_defines.v"

package bsg_cache_non_blocking_pkg;


  // cache opcode
  //
  typedef enum logic [4:0] {

    LB  = 5'b00000        // load byte   (signed)
    ,LH = 5'b00001        // load half   (signed)
    ,LW = 5'b00010        // load word   (signed)
    ,LD = 5'b00011        // load double (signed)

    ,LBU = 5'b00100       // load byte   (unsigned)
    ,LHU = 5'b00101       // load half   (unsigned)
    ,LWU = 5'b00110       // load word   (unsigned)

    ,SB  = 5'b01000       // store byte
    ,SH  = 5'b01001       // store half
    ,SW  = 5'b01010       // store word
    ,SD  = 5'b01011       // store double
    ,SM  = 5'b01101       // store mask

    ,BLOCK_LD = 5'b01110  // block load

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
    } bsg_cache_non_blocking_pkt_s


  `define bsg_cache_non_blocking_pkt_width(id_width_mp,addr_width_mp,data_width_mp) \
    ($bits(bsg_cache_non_blocking_opcode_e)+id_width_mp+addr_width_mp+data_width_mp+(data_width_mp>>3))


  // cache pkt decode
  //
  typedef struct packed {
    // 00 - byte
    // 01 - half
    // 10 - word
    // 11 - double
    logic [1:0] size_op;
    logic sigext_op;
    logic ld_op;
    logic st_op;
    logic block_ld_op;
    logic mask_op;

    logic tagst_op;
    logic taglv_op;
    logic tagla_op;

    logic tagfl_op;
    logic afl_op;
    logic aflinv_op;
    logic ainv_op;

    logic alock_op;
    logic aunlock_op;

    logic mgmt_op;
  } bsg_cache_non_blocking_decode_s;


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

  
  // tag info op
  //
  typedef enum logic [2:0] {
    e_tag_read                    // w_i = 0;
    ,e_tag_store                  // tagst
    ,e_tag_set_tag                // valid <= 1;
    ,e_tag_set_tag_and_lock       // valid <= 1; lock <= 1;
    ,e_tag_invalidate             // valid <= 0; lock <= 0;
    ,e_tag_lock                   // lock <= 1;
    ,e_tag_unlock                 // lock <= 0;
  } bsg_cache_non_blocking_tag_op_e;


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


  // stat op
  //
  typedef enum logic [2:0] {
    e_stat_read
    ,e_stat_clear_dirty
    ,e_stat_set_lru
    ,e_stat_set_lru_and_dirty
    ,e_stat_set_lru_and_clear_dirty
    ,e_stat_reset
  } bsg_cache_non_blocking_stat_op_e;


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


  // miss FIFO yumi op 
  //
  typedef enum logic [1:0] {
    e_miss_fifo_dequeue
    ,e_miss_fifo_skip
    ,e_miss_fifo_invalidate
  } bsg_cache_non_blocking_miss_fifo_op_e;


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


  // MHU FSM states
  typedef enum logic [3:0] {
    MHU_IDLE
    ,MGMT_OP
    ,SEND_MGMT_DMA
    ,WAIT_MGMT_DMA
    ,READ_TAG1
    ,SEND_DMA_REQ1
    ,WAIT_DMA_DONE
    ,DEQUEUE_MODE
    ,READ_TAG2
    ,SEND_DMA_REQ2
    ,SCAN_MODE 
    ,RECOVER
  } mhu_state_e;


endpackage
