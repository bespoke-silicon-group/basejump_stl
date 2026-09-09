
module bsg_buf #(parameter width_p=1
                 , parameter harden_p=1
                 )
   (input    [width_p-1:0] i
    , output [width_p-1:0] o
    );

  if (harden_p)
    begin : macro
      for (genvar j = 0; j < width_p; j++)
        sky130_fd_sc_hd__buf_1 b (.X(o[j]), .A(i[j]));
    end
  else
    begin : notmacro
        assign o = i;
    end

endmodule

