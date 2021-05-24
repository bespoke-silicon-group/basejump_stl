`include "bsg_defines.v"

module bsg_inv #( width_p    = "inv"
                , harden_p   = 1
                , strength_p = 1
                , clock_p    = 0
		            , vertical_p = 1
                )
( input  [width_p-1:0] i
, output [width_p-1:0] o
);

  if (harden_p)
    begin: hard
      for (genvar n = 0; n < width_p; n++)
        begin: b
          if (strength_p == 1 && clock_p == 0) begin: x1
            SC7P5T_INVX1_SSC14R inv_BSG_DONT_TOUCH (.A(i[n]), .Z(o[n]));
          end else if (strength_p == 2 && clock_p == 0) begin: x2
            SC7P5T_INVX2_SSC14R inv_BSG_DONT_TOUCH (.A(i[n]), .Z(o[n]));
          end else if (strength_p == 4 && clock_p == 0) begin: x4
            SC7P5T_INVX4_SSC14R inv_BSG_DONT_TOUCH (.A(i[n]), .Z(o[n]));
          end else if (strength_p == 8 && clock_p == 0) begin: x8
            SC7P5T_INVX8_SSC14R inv_BSG_DONT_TOUCH (.A(i[n]), .Z(o[n]));
          end else if (strength_p == 1 && clock_p == 1) begin: x1
            SC7P5T_CKINVX1_SSC14R inv_BSG_DONT_TOUCH (.CLK(i[n]), .Z(o[n]));
          end else if (strength_p == 2 && clock_p == 1) begin: x2
            SC7P5T_CKINVX2_SSC14R inv_BSG_DONT_TOUCH (.CLK(i[n]), .Z(o[n]));
          end else if (strength_p == 4 && clock_p == 1) begin: x4
            SC7P5T_CKINVX4_SSC14R inv_BSG_DONT_TOUCH (.CLK(i[n]), .Z(o[n]));
          end else if (strength_p == 8 && clock_p == 1) begin: x8
            SC7P5T_CKINVX8_SSC14R inv_BSG_DONT_TOUCH (.CLK(i[n]), .Z(o[n]));
          end else begin
            $fatal( 1, "Error: there is no hardened cell for strength_p=%d, clock_p=%d", strength_p, clock_p );
          end
        end: b
    end: hard
  else
    begin
      assign o = ~i;
    end

endmodule
