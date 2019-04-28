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

  if (width_p == 32) begin
    bsg_fpu_add_sub_n #(
      .e_p(8)
      ,.m_p(23)
    ) add_sub_32 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.v_i(v_i)
      ,.yumi_i(yumi_i)
      ,.a_i(a_i)
      ,.b_i(b_i)
      ,.sub_i(sub_i)
      ,.v_o(v_o)
      ,.ready_o(ready_o)
      ,.z_o(z_o)
      ,.unimplemented_o(unimplemented_o)
      ,.invalid_o(invalid_o)
      ,.overflow_o(overflow_o)
      ,.underflow_o(underflow_o)
    ); 
  end
  else if (width_p == 64) begin
    bsg_fpu_add_sub_n #(
      .e_p(11)
      ,.m_p(52)
    ) add_sub_64 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.v_i(v_i)
      ,.yumi_i(yumi_i)
      ,.a_i(a_i)
      ,.b_i(b_i)
      ,.sub_i(sub_i)
      ,.v_o(v_o)
      ,.ready_o(ready_o)
      ,.z_o(z_o)
      ,.unimplemented_o(unimplemented_o)
      ,.invalid_o(invalid_o)
      ,.overflow_o(overflow_o)
      ,.underflow_o(underflow_o)
    ); 
  end
  else begin
    initial begin
      assert ("width" == "unhandled") else $error("unhandled case for %m");
    end
  end

endmodule
