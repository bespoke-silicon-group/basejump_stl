/**
 *  bsg_fpu_i2f.v
 *
 *  @author Tommy Jung
 *
 */

module bsg_fpu_i2f
  #(parameter width_p="inv")
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [width_p-1:0] a_i
    , input signed_i
    , output logic ready_o

    , output logic v_o
    , output logic [width_p-1:0] z_o
    , input yumi_i
  );

  if (width_p == 32) begin: i2f_bin32

    bsg_fpu_i2f_n #(
      .e_p(8)
      ,.m_p(23)
    ) i2f_bin32 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i(1'b1)
  
      ,.v_i(v_i)
      ,.signed_i(signed_i)
      ,.a_i(a_i)
      ,.ready_o(ready_o)
  
      ,.v_o(v_o)
      ,.z_o(z_o)
      ,.yumi_i(yumi_i)
    );

  end
  else if (width_p == 64) begin: i2f_bin64

    bsg_fpu_i2f_n #(
      .e_p(11)
      ,.m_p(52)
    ) i2f_bin64 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i(1'b1)
  
      ,.v_i(v_i)
      ,.signed_i(signed_i)
      ,.a_i(a_i)
      ,.ready_o(ready_o)
  
      ,.v_o(v_o)
      ,.z_o(z_o)
      ,.yumi_i(yumi_i)
    );

  end
  else if (width_p == 16) begin: i2f_bfloat16

    bsg_fpu_i2f_n #(
      .e_p(8)
      ,.m_p(7)
    ) i2f_bfloat16 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.en_i(1'b1)
  
      ,.v_i(v_i)
      ,.signed_i(signed_i)
      ,.a_i(a_i)
      ,.ready_o(ready_o)
  
      ,.v_o(v_o)
      ,.z_o(z_o)
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
