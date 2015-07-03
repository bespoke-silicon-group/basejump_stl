`define bsg_dff_macro(bits,strength)                      \
if (harden_p && (width_p==bits) && (strength_p==strength)) \
  begin: macro                                            \
     bsg_rp_tsmc_250_dff_s``strength``_b``bits dff(.*);   \
  end

module bsg_dff #(width_p=-1, harden_p=1, strength_p=1)
   (input   clock_i
    ,input  [width_p-1:0] data_i
    ,output [width_p-1:0] data_o
    );

   `bsg_dff_macro(32,1)
    else
   `bsg_dff_macro(32,2)
    else  
   `bsg_dff_macro(32,4)
    else
   `bsg_dff_macro(32,8)
   else
     `bsg_dff_macro(26,1)
   else
     `bsg_dff_macro(30,1)
   else
  `bsg_dff_macro(33,1)
     else
     begin: notmacro
        reg [width_p-1:0] data_r;

        assign data_o = data_r;

        always @(posedge clock_i)
          data_r <= data_i;
     end
endmodule
