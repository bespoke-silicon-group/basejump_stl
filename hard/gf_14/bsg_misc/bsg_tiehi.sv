`include "bsg_defines.sv"

module bsg_tiehi

#(width_p="inv", harden_p=1)

(output [width_p-1:0] o
);

  if (harden_p)
    begin: hard
      for (genvar i = 0; i < width_p; i++)
        begin: w
          SC7P5T_TIEHIX2_SSC16R
            BSG_DONT_TOUCH_TIE_HI
              (.Z(o));
        end: w
    end: hard
  else
    begin: syn
      assign o = { width_p {1'b1} };
    end: syn
   
endmodule

`BSG_ABSTRACT_MODULE(bsg_tiehi)
