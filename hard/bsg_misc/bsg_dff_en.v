`define bsg_dff_en_macro(bits)                                          \
if (harden_p && width_p==bits)                                          \
  begin: macro                                                          \
     bsg_rp_tsmc_250_dff_en_s1_b``bits dff(.clock_i                     \
                                               ,.data_i                 \
                                               ,.en_i                   \
                                               ,.data_o);               \
  end



module bsg_dff_en #(width_p="inv"
		    , harden_p=1
		    )
   (input   clock_i
    ,input  [width_p-1:0] data_i
    ,input  en_i
    ,output [width_p-1:0] data_o
    );

   `bsg_dff_en_macro(40)
   else `bsg_dff_en_macro(39)
   else `bsg_dff_en_macro(38)
   else `bsg_dff_en_macro(37)
   else `bsg_dff_en_macro(16)
   else `bsg_dff_en_macro(15)
   else `bsg_dff_en_macro(14)
   else `bsg_dff_en_macro(12)
   else `bsg_dff_en_macro(11)
   else `bsg_dff_en_macro(10)
   else `bsg_dff_en_macro(8)
   else `bsg_dff_en_macro(7)
   else `bsg_dff_en_macro(6)
   else `bsg_dff_en_macro(5)
   else `bsg_dff_en_macro(4)
   else
   begin : notmacro
      reg [width_p-1:0] data_r;

      assign data_o = data_r;

      always @(posedge clock_i)
	if (en_i)
	  data_r <= data_i;
   end
endmodule
