/**
 *  bsg_cache_decode.v
 *
 */


`include "bsg_defines.v"

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
    || (opcode_i == LH)
    || (opcode_i == LW)
    || (opcode_i == LD)
    || decode_o.atomic_op;

  assign decode_o.ld_op = (opcode_i == LB)
    || (opcode_i == LH)
    || (opcode_i == LW)
    || (opcode_i == LD)
    || (opcode_i == LBU)
    || (opcode_i == LHU)
    || (opcode_i == LWU)
    || (opcode_i == LDU)
    || (opcode_i == LM);

  assign decode_o.st_op = (opcode_i == SB)
    || (opcode_i == SH)
    || (opcode_i == SW)
    || (opcode_i == SD)
    || (opcode_i == SM);

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
  always_comb begin
    decode_o.atomic_op = 1'b1;

    // These subopcodes are intended to match the low 4 bits of the
    //   corresponding bsg_cache_pkt opcode, to simplify decoding
    unique case (opcode_i)
      AMOSWAP_W, AMOSWAP_D: decode_o.amo_subop = e_cache_amo_swap;
      AMOADD_W, AMOADD_D: decode_o.amo_subop = e_cache_amo_add;
      AMOXOR_W, AMOXOR_D: decode_o.amo_subop = e_cache_amo_xor;
      AMOAND_W, AMOAND_D: decode_o.amo_subop = e_cache_amo_and;
      AMOOR_W, AMOOR_D: decode_o.amo_subop = e_cache_amo_or;
      AMOMIN_W, AMOMIN_D: decode_o.amo_subop = e_cache_amo_min;
      AMOMAX_W, AMOMAX_D: decode_o.amo_subop = e_cache_amo_max;
      AMOMINU_W, AMOMINU_D: decode_o.amo_subop = e_cache_amo_minu;
      AMOMAXU_W, AMOMAXU_D: decode_o.amo_subop = e_cache_amo_maxu;
      default: begin
        decode_o.atomic_op = 1'b0;
        decode_o.amo_subop = e_cache_amo_swap;
      end
    endcase
  end

endmodule
