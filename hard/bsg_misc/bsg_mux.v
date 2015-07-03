`define bsg_mux_gen_macro(words,bits)                           \
if (harden_p && els_p == words && width_p == bits)              \
begin: macro                                                    \
   wire [els_p-1:0] sel_onehot = els_p ' (1'b1 << sel_i);       \
                                                                \
   bsg_rp_tsmc_250_mux_w``words``_b``bits w``words``_b``bits    \
     (.*                                                        \
      , .sel_one_hot_i(sel_onehot)                              \
      );                                                        \
end


module bsg_mux #(parameter width_p="inv"
		 , els_p=1
		 , harden_p=1
		 , lg_els_lp=`BSG_SAFE_CLOG2(els_p)
		 )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [lg_els_lp-1:0] sel_i
    ,output [width_p-1:0] data_o
    );

   `bsg_mux_gen_macro(2,33)
    else `bsg_mux_gen_macro(2,32)
    else `bsg_mux_gen_macro(2,30)
    else `bsg_mux_gen_macro(2,29)
    else `bsg_mux_gen_macro(2,18)
    else `bsg_mux_gen_macro(2,17)
    else `bsg_mux_gen_macro(2,14)
    else `bsg_mux_gen_macro(2,13)
    else `bsg_mux_gen_macro(2,12)
    else `bsg_mux_gen_macro(4,32)
    else
       assign data_o = data_i[sel_i];

endmodule

