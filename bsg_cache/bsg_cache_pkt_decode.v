/**
 *  bsg_cache_pkt_decode.v
 *
 */


module bsg_cache_pkt_decode
  import bsg_cache_pkg::*;
  #(parameter data_width_p="inv"
    , parameter addr_width_p="inv"
    
    , localparam bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(addr_width_p,data_width_p)
  )
  (
    input [bsg_cache_pkt_width_lp-1:0] cache_pkt_i

    , output bsg_cache_pkt_decode_s decode_o
  );


  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);
  bsg_cache_pkt_s cache_pkt;

  assign cache_pkt = cache_pkt_i;

  always_comb begin
    case (cache_pkt.opcode)
      LD, SD, LDU: decode_o.data_size_op = 2'b11;
      LW, SW, LWU: decode_o.data_size_op = 2'b10;
      LH, SH, LHU: decode_o.data_size_op = 2'b01;
      LB, SB, LBU: decode_o.data_size_op = 2'b00;
      default: decode_o.data_size_op = 2'b00;
    endcase    
  end

  assign decode_o.mask_op = (cache_pkt.opcode == LM) | (cache_pkt.opcode == SM);

  assign decode_o.block_ld_op = (cache_pkt.opcode == BLOCK_LD);

  assign decode_o.sigext_op = (cache_pkt.opcode == LB)
    | (cache_pkt.opcode == LH)
    | (cache_pkt.opcode == LW)
    | (cache_pkt.opcode == LD);

  assign decode_o.ld_op = (cache_pkt.opcode == LB)
    | (cache_pkt.opcode == LH)
    | (cache_pkt.opcode == LW)
    | (cache_pkt.opcode == LD)
    | (cache_pkt.opcode == LBU)
    | (cache_pkt.opcode == LHU)
    | (cache_pkt.opcode == LWU)
    | (cache_pkt.opcode == LDU)
    | (cache_pkt.opcode == LM);

  assign decode_o.st_op = (cache_pkt.opcode == SB)
    | (cache_pkt.opcode == SH)
    | (cache_pkt.opcode == SW)
    | (cache_pkt.opcode == SD)
    | (cache_pkt.opcode == SM);

  assign decode_o.tagst_op = (cache_pkt.opcode == TAGST);
  assign decode_o.tagfl_op = (cache_pkt.opcode == TAGFL);
  assign decode_o.taglv_op = (cache_pkt.opcode == TAGLV);
  assign decode_o.tagla_op = (cache_pkt.opcode == TAGLA);
  assign decode_o.afl_op = (cache_pkt.opcode == AFL);
  assign decode_o.aflinv_op = (cache_pkt.opcode == AFLINV);
  assign decode_o.ainv_op = (cache_pkt.opcode == AINV);
  assign decode_o.alock_op = (cache_pkt.opcode == ALOCK);
  assign decode_o.aunlock_op = (cache_pkt.opcode == AUNLOCK);

  assign decode_o.tag_read_op = ~decode_o.tagst_op;
  assign decode_o.l2_bypass_op = cache_pkt.l2_bypass;

endmodule
