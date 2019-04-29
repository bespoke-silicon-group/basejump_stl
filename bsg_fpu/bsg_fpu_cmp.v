/**
 *  bsg_fpu_cmp.v
 *
 *  @author Tommy Jung
 */

module bsg_fpu_cmp
  import bsg_fpu_pkg::*;
  #(parameter width_p="inv")
  ( 
    input [width_p-1:0] a_i
    , input [width_p-1:0] b_i

    , output logic eq_o
    , output logic lt_o
    , output logic le_o

    , output logic lt_le_invalid_o
    , output logic eq_invalid_o

    , output logic [width_p-1:0] min_o
    , output logic [width_p-1:0] max_o
    , output logic min_max_invalid_o
  );

  if (width_p == 32) begin: cmp32

    bsg_fpu_cmp_n #(
      .e_p(8)
      ,.m_p(23)
    ) cmp32 (
      .a_i(a_i)
      ,.b_i(b_i)

      ,.eq_o(eq_o)
      ,.lt_o(lt_o)
      ,.le_o(le_o)

      ,.lt_le_invalid_o(lt_le_invalid_o)
      ,.eq_invalid_o(eq_invalid_o)

      ,.min_o(min_o)
      ,.max_o(max_o)
      ,.min_max_invalid_o(min_max_invalid_o)
    );

  end
  else if (width_p == 64) begin: cmp64

    bsg_fpu_cmp_n #(
      .e_p(11)
      ,.m_p(52)
    ) cmp64 (
      .a_i(a_i)
      ,.b_i(b_i)

      ,.eq_o(eq_o)
      ,.lt_o(lt_o)
      ,.le_o(le_o)

      ,.lt_le_invalid_o(lt_le_invalid_o)
      ,.eq_invalid_o(eq_invalid_o)

      ,.min_o(min_o)
      ,.max_o(max_o)
      ,.min_max_invalid_o(min_max_invalid_o)
    );

  end
  else begin
    // not tested
    initial begin
      assert ("width" == "unhandled") else $error("unhandled case for %m");
    end
  end

endmodule
