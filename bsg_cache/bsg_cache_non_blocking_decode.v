/**
 *  bsg_cache_non_blocking_pkt_decode.v
 *
 *  @author tommy
 *
 */


`include "bsg_defines.v"

module bsg_cache_non_blocking_decode
  import bsg_cache_non_blocking_pkg::*;
  (
    input bsg_cache_non_blocking_opcode_e opcode_i
    , output bsg_cache_non_blocking_decode_s decode_o
  );

  always_comb begin
    case (opcode_i)
      LD, SD: decode_o.size_op = 2'b11;
      LW, SW, LWU: decode_o.size_op = 2'b10;
      LH, SH, LHU: decode_o.size_op = 2'b01;
      LB, SB, LBU: decode_o.size_op = 2'b00;
      default: decode_o.size_op = 2'b00;
    endcase    
  end

  assign decode_o.sigext_op = (opcode_i == LB)
    | (opcode_i == LH)
    | (opcode_i == LW)
    | (opcode_i == LD);

  assign decode_o.ld_op = (opcode_i == LB)
    | (opcode_i == LH)
    | (opcode_i == LW)
    | (opcode_i == LD)
    | (opcode_i == LBU)
    | (opcode_i == LHU)
    | (opcode_i == LWU);

  assign decode_o.st_op = (opcode_i == SB)
    | (opcode_i == SH)
    | (opcode_i == SW)
    | (opcode_i == SD)
    | (opcode_i == SM);

  assign decode_o.mask_op = (opcode_i == SM);

  assign decode_o.block_ld_op = (opcode_i == BLOCK_LD);

  assign decode_o.tagst_op    = (opcode_i == TAGST);
  assign decode_o.tagfl_op    = (opcode_i == TAGFL);
  assign decode_o.taglv_op    = (opcode_i == TAGLV);
  assign decode_o.tagla_op    = (opcode_i == TAGLA);
  assign decode_o.afl_op      = (opcode_i == AFL);
  assign decode_o.aflinv_op   = (opcode_i == AFLINV);
  assign decode_o.ainv_op     = (opcode_i == AINV);
  assign decode_o.alock_op    = (opcode_i == ALOCK);
  assign decode_o.aunlock_op  = (opcode_i == AUNLOCK);

  assign decode_o.mgmt_op = ~(decode_o.ld_op | decode_o.st_op | decode_o.block_ld_op);

endmodule
