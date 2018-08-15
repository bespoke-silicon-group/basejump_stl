/**
 * bsg_cache_pkg.v
 */

`ifndef BSG_CACHE_PKG_V
`define BSG_CACHE_PKG_V

package bsg_cache_pkg;

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

endpackage

`endif
