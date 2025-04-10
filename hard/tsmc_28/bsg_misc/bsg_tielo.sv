`include "bsg_defines.sv"

module bsg_tielo

#(`BSG_INV_PARAM(width_p), harden_p=0)

(output [width_p-1:0] o
);

  if (harden_p)
    begin: macro
      for (genvar i = 0; i < width_p; i++)
        begin: x
          TIELBWP7T40P140
            TIE_LO_BSG_DONT_TOUCH
              (.ZN(o[i]));
        end
    end
  else
    begin: notmacro
      `BSG_SYNTH_HARDEN_ATTEMPT(harden_p)

      assign o = { width_p {1'b0} };
    end
   
endmodule

`BSG_ABSTRACT_MODULE(bsg_tielo)
