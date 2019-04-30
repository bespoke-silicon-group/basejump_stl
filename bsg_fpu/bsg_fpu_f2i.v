/**
 *  bsg_fpu_f2i.v
 *
 *  @author Tommy Jung
 */

module bsg_fpu_f2i
  #(parameter width_p="inv")
  (
    input [width_p-1:0] a_i
    , input signed_i

    , output logic [width_p-1:0] z_o 
    , output logic invalid_o
  ); 

  if (width_p == 32) begin: f2i_bin32

    bsg_fpu_f2i_n #(
      .e_p(8)
      ,.m_p(23)
    ) f2i_bin32 (
      .a_i(a_i)
      ,.signed_i(signed_i)

      ,.z_o(z_o)
      ,.invalid_o(invalid_o)
    );

  end
  else if (width_p == 64) begin: f2i_bin64

    bsg_fpu_f2i_n #(
      .e_p(11)
      ,.m_p(52)
    ) f2i_bin64 (
      .a_i(a_i)
      ,.signed_i(signed_i)

      ,.z_o(z_o)
      ,.invalid_o(invalid_o)
    );

  end
  else if (width_p == 16) begin: f2i_bfloat16

    bsg_fpu_f2i_n #(
      .e_p(8)
      ,.m_p(7)
    ) f2i_bfloat16 (
      .a_i(a_i)
      ,.signed_i(signed_i)

      ,.z_o(z_o)
      ,.invalid_o(invalid_o)
    );

  end
  else begin
    initial begin
      assert ("width" == "unhandled") else $error("unhandled case for %m");
    end
  end

endmodule
