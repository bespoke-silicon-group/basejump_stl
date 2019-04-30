/**
 *  bsg_fpu_add_sub.v
 *
 *  @author Tommy Jung
 */

module bsg_fpu_add_sub
  #(parameter width_p="inv")
  (
    input clk_i
    , input reset_i

    , input v_i 
    , input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , input sub_i
    , output logic ready_o

    , output logic v_o
    , output logic [width_p-1:0] z_o
    , output logic unimplemented_o
    , output logic invalid_o
    , output logic overflow_o
    , output logic underflow_o
    , input yumi_i
  );

  if (width_p == 32) begin: add_sub_bin32
    bsg_fpu_add_sub_n #(
      .e_p(8)
      ,.m_p(23)
    ) add_sub_bin32 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i(1'b1)

      ,.v_i(v_i)
      ,.a_i(a_i)
      ,.b_i(b_i)
      ,.sub_i(sub_i)
      ,.ready_o(ready_o)

      ,.v_o(v_o)
      ,.z_o(z_o)
      ,.unimplemented_o(unimplemented_o)
      ,.invalid_o(invalid_o)
      ,.overflow_o(overflow_o)
      ,.underflow_o(underflow_o)
      ,.yumi_i(yumi_i)
    ); 
  end
  else if (width_p == 64) begin: add_sub_bin64

    bsg_fpu_add_sub_n #(
      .e_p(11)
      ,.m_p(52)
    ) add_sub_bin64 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i(1'b1)

      ,.v_i(v_i)
      ,.a_i(a_i)
      ,.b_i(b_i)
      ,.sub_i(sub_i)
      ,.ready_o(ready_o)

      ,.v_o(v_o)
      ,.z_o(z_o)
      ,.unimplemented_o(unimplemented_o)
      ,.invalid_o(invalid_o)
      ,.overflow_o(overflow_o)
      ,.underflow_o(underflow_o)
      ,.yumi_i(yumi_i)
    ); 

  end
  else if (width == 16) begin: add_sub_bfloat16

    bsg_fpu_add_sub_n #(
      .e_p(8)
      ,.m_p(7)
    ) add_sub_bfloat16 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i(1'b1)

      ,.v_i(v_i)
      ,.a_i(a_i)
      ,.b_i(b_i)
      ,.sub_i(sub_i)
      ,.ready_o(ready_o)

      ,.v_o(v_o)
      ,.z_o(z_o)
      ,.unimplemented_o(unimplemented_o)
      ,.invalid_o(invalid_o)
      ,.overflow_o(overflow_o)
      ,.underflow_o(underflow_o)
      ,.yumi_i(yumi_i)
    ); 

  end 
  else begin
    // not tested
    initial begin
      assert ("width" == "unhandled") else $error("unhandled case for %m");
    end
  end

endmodule
