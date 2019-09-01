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
    
    , output logic [1:0] data_size_op_o
    , output logic mask_op_o

    , output logic ld_op_o
    , output logic st_op_o

    , output logic tagst_op_o
    , output logic taglv_op_o
    , output logic tagla_op_o
    , output logic tagfl_op_o

    , output logic afl_op_o
    , output logic aflinv_op_o
    , output logic ainv_op_o

    , output logic tag_read_op_o

    , output logic alock_op_o
    , output logic aunlock_op_o
  );


  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);
  bsg_cache_pkt_s cache_pkt;

  assign cache_pkt = cache_pkt_i;

  always_comb begin
    case (cache_pkt.opcode)
      LD, SD: data_size_op_o = 2'b11;
      LW, SW: data_size_op_o = 2'b10;
      LH, SH: data_size_op_o = 2'b01;
      LB, SB: data_size_op_o = 2'b00;
      default: data_size_op_o = 2'b00;
    endcase    
  end

  assign mask_op_o = (cache_pkt.opcode == LM) | (cache_pkt.opcode == SM);

  assign ld_op_o = (cache_pkt.opcode == LB)
    | (cache_pkt.opcode == LH)
    | (cache_pkt.opcode == LW)
    | (cache_pkt.opcode == LD)
    | (cache_pkt.opcode == LM);

  assign st_op_o = (cache_pkt.opcode == SB)
    | (cache_pkt.opcode == SH)
    | (cache_pkt.opcode == SW)
    | (cache_pkt.opcode == SD)
    | (cache_pkt.opcode == SM);

  assign tagst_op_o = (cache_pkt.opcode == TAGST);
  assign tagfl_op_o = (cache_pkt.opcode == TAGFL);
  assign taglv_op_o = (cache_pkt.opcode == TAGLV);
  assign tagla_op_o = (cache_pkt.opcode == TAGLA);
  assign afl_op_o = (cache_pkt.opcode == AFL);
  assign aflinv_op_o = (cache_pkt.opcode == AFLINV);
  assign ainv_op_o = (cache_pkt.opcode == AINV);
  assign alock_op_o = (cache_pkt.opcode == ALOCK);
  assign aunlock_op_o = (cache_pkt.opcode == AUNLOCK);

  assign tag_read_op_o = ld_op_o | st_op_o
    | tagfl_op_o | taglv_op_o | tagla_op_o
    | afl_op_o | aflinv_op_o | ainv_op_o
    | alock_op_o | aunlock_op_o;

endmodule
