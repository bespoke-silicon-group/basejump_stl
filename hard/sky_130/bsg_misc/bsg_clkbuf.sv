
module bsg_clkbuf #(parameter width_p=1
                    , parameter strength_p=8
                    , parameter harden_p=1
                    )
   (input    [width_p-1:0] i
    , output [width_p-1:0] o
    );

  if (harden_p)
    begin : macro
      for (genvar j = 0; j < width_p; j++)
        sky130_fd_sc_hd__clkbuf b (.X(o[j]), .A(i[j]));
    end
  else
    begin : notmacro
        assign o = i;
    end

endmodule

