/**
 *  bsg_cache_non_blocking_pkg.sv
 *  
 *  @author tommy
 */

`include "bsg_defines.sv"

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


  // miss FIFO yumi op 
  //
  typedef enum logic [1:0] {
    e_miss_fifo_dequeue
    ,e_miss_fifo_skip
    ,e_miss_fifo_invalidate
  } bsg_cache_non_blocking_miss_fifo_op_e;


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
