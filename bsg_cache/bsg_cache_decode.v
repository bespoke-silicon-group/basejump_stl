/**
 *  bsg_cache_decode.v
 *
 */


module bsg_cache_decode
  import bsg_cache_pkg::*;
  (
    input bsg_cache_opcode_e opcode_i
    , output bsg_cache_decode_s decode_o
  );


  always_comb begin
    case (opcode_i)
      // double
      AMOSWAP_D, AMOADD_D, AMOAND_D, AMOOR_D, AMOXOR_D,
      AMOMIN_D, AMOMAX_D, AMOMINU_D, AMOMAXU_D,
      LD, SD, LDU: decode_o.data_size_op = 2'b11;
      // word
      AMOSWAP_W, AMOADD_W, AMOAND_W, AMOOR_W, AMOXOR_W,
      AMOMIN_W, AMOMAX_W, AMOMINU_W, AMOMAXU_W,
      LW, SW, LWU: decode_o.data_size_op = 2'b10;
      // half
      LH, SH, LHU: decode_o.data_size_op = 2'b01;
      // byte
      LB, SB, LBU: decode_o.data_size_op = 2'b00;
      default: decode_o.data_size_op = 2'b00;
    endcase    
  end

  assign decode_o.mask_op = (opcode_i == LM) | (opcode_i == SM);

  assign decode_o.sigext_op = (opcode_i == LB)
    | (opcode_i == LH)
    | (opcode_i == LW)
    | (opcode_i == LD)
    | decode_o.atomic_op;

  assign decode_o.ld_op = (opcode_i == LB)
    | (opcode_i == LH)
    | (opcode_i == LW)
    | (opcode_i == LD)
    | (opcode_i == LBU)
    | (opcode_i == LHU)
    | (opcode_i == LWU)
    | (opcode_i == LDU)
    | (opcode_i == LM);

  assign decode_o.st_op = (opcode_i == SB)
    | (opcode_i == SH)
    | (opcode_i == SW)
    | (opcode_i == SD)
    | (opcode_i == SM);

  assign decode_o.tagst_op = (opcode_i == TAGST);
  assign decode_o.tagfl_op = (opcode_i == TAGFL);
  assign decode_o.taglv_op = (opcode_i == TAGLV);
  assign decode_o.tagla_op = (opcode_i == TAGLA);
  assign decode_o.afl_op = (opcode_i == AFL);
  assign decode_o.aflinv_op = (opcode_i == AFLINV);
  assign decode_o.ainv_op = (opcode_i == AINV);
  assign decode_o.alock_op = (opcode_i == ALOCK);
  assign decode_o.aunlock_op = (opcode_i == AUNLOCK);

  assign decode_o.tag_read_op = ~decode_o.tagst_op;

  // atomic extension
  assign decode_o.amoswap_op = (opcode_i == AMOSWAP_W) | (opcode_i == AMOSWAP_D);
  assign decode_o.amoadd_op = (opcode_i == AMOADD_W) | (opcode_i == AMOADD_D);
  assign decode_o.amoxor_op = (opcode_i == AMOXOR_W) | (opcode_i == AMOXOR_D);
  assign decode_o.amoand_op = (opcode_i == AMOAND_W) | (opcode_i == AMOAND_D);
  assign decode_o.amoor_op = (opcode_i == AMOOR_W) | (opcode_i == AMOOR_D);
  assign decode_o.amomin_op = (opcode_i == AMOMIN_W) | (opcode_i == AMOMIN_D);
  assign decode_o.amomax_op = (opcode_i == AMOMAX_W) | (opcode_i == AMOMAX_D);
  assign decode_o.amominu_op = (opcode_i == AMOMINU_W) | (opcode_i == AMOMINU_D);
  assign decode_o.amomaxu_op = (opcode_i == AMOMAXU_W) | (opcode_i == AMOMAXU_D);
  assign decode_o.atomic_op = decode_o.amoswap_op
    | decode_o.amoadd_op
    | decode_o.amoxor_op
    | decode_o.amoand_op
    | decode_o.amoor_op
    | decode_o.amomin_op
    | decode_o.amomax_op
    | decode_o.amominu_op
    | decode_o.amomaxu_op;

endmodule
