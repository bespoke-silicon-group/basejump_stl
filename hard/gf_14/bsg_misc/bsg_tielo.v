`include "bsg_defines.sv"

module bsg_tielo

#(width_p="inv", harden_p=1)

(output [width_p-1:0] o
);

  if (harden_p)
    begin: hard
      for (genvar i = 0; i < width_p; i++)
        begin: w
          SC7P5T_TIELOX2_SSC16R
            BSG_DONT_TOUCH_TIE_LO
              (.Z(o));
        end: w
    end: hard
  else
    begin: syn
      assign o = { width_p {1'b0} };
    end: syn
   
endmodule

`BSG_ABSTRACT_MODULE(bsg_tielo)
