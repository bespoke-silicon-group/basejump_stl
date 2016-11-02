`define bsg_tiehi_macro(bits)                       \
if (harden_p && (width_p==bits))                    \
  begin: macro                                      \
     bsg_rp_tsmc_250_TIEHI_b``bits tiehi (.o);      \
  end

module bsg_tiehi #(parameter width_p="inv"
                 , parameter harden_p=1
                 )
   (output [width_p-1:0] o
    );

   `bsg_tiehi_macro(34) else
   `bsg_tiehi_macro(33) else
   `bsg_tiehi_macro(32) else
   `bsg_tiehi_macro(31) else
   `bsg_tiehi_macro(30) else
   `bsg_tiehi_macro(29) else
   `bsg_tiehi_macro(28) else
   `bsg_tiehi_macro(27) else
   `bsg_tiehi_macro(26) else
   `bsg_tiehi_macro(25) else
   `bsg_tiehi_macro(24) else
   `bsg_tiehi_macro(23) else
   `bsg_tiehi_macro(22) else
   `bsg_tiehi_macro(21) else
   `bsg_tiehi_macro(20) else
   `bsg_tiehi_macro(19) else
   `bsg_tiehi_macro(18) else
   `bsg_tiehi_macro(17) else
   `bsg_tiehi_macro(16) else
   `bsg_tiehi_macro(15) else
   `bsg_tiehi_macro(14) else
   `bsg_tiehi_macro(13) else
   `bsg_tiehi_macro(12) else
   `bsg_tiehi_macro(11) else
   `bsg_tiehi_macro(10) else
   `bsg_tiehi_macro(9) else
   `bsg_tiehi_macro(8) else
   `bsg_tiehi_macro(7) else
   `bsg_tiehi_macro(6) else
   `bsg_tiehi_macro(5) else
   `bsg_tiehi_macro(4) else
   `bsg_tiehi_macro(3) else
   `bsg_tiehi_macro(2) else
   `bsg_tiehi_macro(1) else
       begin :notmacro
          assign o = { width_p {1'b1} };

          // synopsys translate_off
          initial assert(harden_p==0) else $error("## %m wanted to harden but no macro");
          // synopsys translate_on

      end
endmodule
