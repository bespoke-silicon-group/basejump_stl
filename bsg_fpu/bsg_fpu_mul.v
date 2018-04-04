/**
 *  bsg_fpu_mul.v
 *
 *  @author Tommy Jung
 */

module bsg_fpu_mul #(parameter width_p="inv")
  ( input clk_i
    , input rst_i
    , input en_i
    , input v_i
    , input yumi_i
    , input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , output logic ready_o
    , output logic v_o
    , output logic [width_p-1:0] z_o
    , output logic unimplemented_o
    , output logic invalid_o
    , output logic overflow_o
    , output logic underflow_o
    , output logic wr_en_2_o
    , output logic wr_en_3_o
  );

  if (width_p == 32)
    begin
      bsg_fpu_mul_32 mul32 (
        .clk_i(clk_i)
        ,.rst_i(rst_i)
        ,.en_i(en_i)
        ,.v_i(v_i)
        ,.yumi_i(yumi_i)
        ,.a_i(a_i)
        ,.b_i(b_i)
        ,.ready_o(ready_o)
        ,.v_o(v_o)
        ,.z_o(z_o)
        ,.unimplemented_o(unimplemented_o)
        ,.invalid_o(invalid_o)
        ,.overflow_o(overflow_o)
        ,.underflow_o(underflow_o)
        ,.wr_en_2_o(wr_en_2_o)
        ,.wr_en_3_o(wr_en_3_o)
        ); 
    end
  else initial assert ("width" == "unhandled") else $error("unhandled case for %m");



endmodule
