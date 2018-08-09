/**
 * bsg_cache_pkg.v
 */

`ifndef BSG_CACHE_PKG_V
`define BSG_CACHE_PKG_V

package bsg_cache_pkg;

  typedef enum logic [3:0] {
    LB = 4'd0
    ,LH = 4'd1
    ,LW = 4'd2
    ,LM = 4'd3
    ,SB = 4'd4
    ,SH = 4'd5
    ,SW = 4'd6
    ,SM = 4'd7
    ,TAGST = 4'd8
    ,TAGFL = 4'd9
    ,TAGLV = 4'd10
    ,TAGLA = 4'd11
    ,AFL = 4'd12
    ,AFLINV = 4'd13
    ,AINV = 4'd14 
  } bsg_cache_opcode_e;

  typedef struct packed {
    logic sigext;
    logic [3:0] wmask;
    bsg_cache_opcode_e opcode;
    logic [31:0] addr;
    logic [31:0] data;
  } bsg_cache_pkt_s;

endpackage

`endif
