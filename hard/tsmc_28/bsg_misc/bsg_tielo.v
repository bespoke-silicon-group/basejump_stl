`include "bsg_defines.sv"

module bsg_tielo

#(`BSG_INV_PARAM(width_p), harden_p=1)

(output [width_p-1:0] o
);

  if (harden_p)
    begin: hard
      for (genvar i = 0; i < width_p; i++)
        begin: w
          TIELBWP7T40P140
            TIE_LO_BSG_DONT_TOUCH
              (.ZN(o));
        end: w
    end: hard
  else
    begin: syn
      assign o = { width_p {1'b0} };
    end: syn
   
endmodule

`BSG_ABSTRACT_MODULE(bsg_tielo)
