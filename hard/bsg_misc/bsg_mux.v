`define bsg_mux_gen_macro(words,bits)                           \
if (harden_p && els_p == words && width_p == bits)              \
begin: macro                                                    \
   wire [els_p-1:0] sel_onehot = els_p ' (1'b1 << sel_i);       \
                                                                \
   bsg_rp_tsmc_250_mux_w``words``_b``bits w``words``_b``bits    \
    (.*                                                         \
      , .sel_one_hot_i(sel_onehot)                              \
      );                                                        \
end

`define bsg_mux4_balanced_gen_macro(BITS)                                     \
   if (balanced_p && harden_p && (els_p==4))                                  \
     begin: macro                                                             \
        wire [width_p-1:0] lo;                                                \
                                                                              \
        /* A B C D S0 S1 Y                                                S1 S0   */  \
        bsg_rp_tsmc_250_MXI4X4_b``BITS b``BITS``_m (.i0 (data_i[0])     /* 0  0 A  */ \
                                                    ,.i1(data_i[1])     /* 0  1 B  */ \
                                                    ,.i2(data_i[2])     /* 1  0 C  */ \
                                                    ,.i3(data_i[3])     /* 1  1 D  */ \
                                                    ,.i4(sel_i[0] )     /*      S0 */ \
                                                    ,.i5(sel_i[1] )     /*      S1 */ \
                                                    ,.o (lo       )                   \
                                                    );                                \
        bsg_rp_tsmc_250_CLKINVX16_b``BITS b``BITS``_i(.i0(lo)                         \
                                                    ,.o(data_o)                       \
                                                    );                                \
     end


module bsg_mux #(parameter width_p="inv"
                 , els_p=1
                 , harden_p=1
                 , balanced_p=0
                 , lg_els_lp=`BSG_SAFE_CLOG2(els_p)
                 )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [lg_els_lp-1:0] sel_i
    ,output [width_p-1:0] data_o
    );

    `bsg_mux4_balanced_gen_macro(1)
    else `bsg_mux_gen_macro(2,33)
    else `bsg_mux_gen_macro(2,32)
    else `bsg_mux_gen_macro(2,30)
    else `bsg_mux_gen_macro(2,29)
    else `bsg_mux_gen_macro(2,20)
    else `bsg_mux_gen_macro(2,19)
    else `bsg_mux_gen_macro(2,18)
    else `bsg_mux_gen_macro(2,17)
    else `bsg_mux_gen_macro(2,16)
    else `bsg_mux_gen_macro(2,15)
    else `bsg_mux_gen_macro(2,14)
    else `bsg_mux_gen_macro(2,13)
    else `bsg_mux_gen_macro(2,12)
    else `bsg_mux_gen_macro(2,11)
    else `bsg_mux_gen_macro(2,10)
    else `bsg_mux_gen_macro(2,9)
    else `bsg_mux_gen_macro(2,8)
    else `bsg_mux_gen_macro(2,7)
    else `bsg_mux_gen_macro(2,6)
    else `bsg_mux_gen_macro(2,5)
    else `bsg_mux_gen_macro(2,4)
    else `bsg_mux_gen_macro(2,3)
    else `bsg_mux_gen_macro(2,2)
    else `bsg_mux_gen_macro(2,1)
    else `bsg_mux_gen_macro(4,32)
    else
      begin: notmacro
         initial assert (harden_p==0) else $error("## %m: warning, failed to harden bsg_mux width=%d, els=%d, balanced=%d",width_p, els_p, balanced_p);
         assign data_o = data_i[sel_i];
      end
endmodule

