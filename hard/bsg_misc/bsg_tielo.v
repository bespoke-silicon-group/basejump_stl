`define bsg_tielo_macro(bits)                       \
if (harden_p && (width_p==bits))                    \
  begin: macro                                      \
     bsg_rp_tsmc_250_TIELO_b``bits tielo (.o);      \
  end

module bsg_tielo #(parameter width_p="inv"
                 , parameter harden_p=1
                 )
   (output [width_p-1:0] o
    );

   `bsg_tielo_macro(34) else
   `bsg_tielo_macro(33) else
   `bsg_tielo_macro(32) else
   `bsg_tielo_macro(31) else
   `bsg_tielo_macro(30) else
   `bsg_tielo_macro(29) else
   `bsg_tielo_macro(28) else
   `bsg_tielo_macro(27) else
   `bsg_tielo_macro(26) else
   `bsg_tielo_macro(25) else
   `bsg_tielo_macro(24) else
   `bsg_tielo_macro(23) else
   `bsg_tielo_macro(22) else
   `bsg_tielo_macro(21) else
   `bsg_tielo_macro(20) else
   `bsg_tielo_macro(19) else
   `bsg_tielo_macro(18) else
   `bsg_tielo_macro(17) else
   `bsg_tielo_macro(16) else
   `bsg_tielo_macro(15) else
   `bsg_tielo_macro(14) else
   `bsg_tielo_macro(13) else
   `bsg_tielo_macro(12) else
   `bsg_tielo_macro(11) else
   `bsg_tielo_macro(10) else
   `bsg_tielo_macro(9) else
   `bsg_tielo_macro(8) else
   `bsg_tielo_macro(7) else
   `bsg_tielo_macro(6) else
   `bsg_tielo_macro(5) else
   `bsg_tielo_macro(4) else
   `bsg_tielo_macro(3) else
   `bsg_tielo_macro(2) else
   `bsg_tielo_macro(1) else
       begin :notmacro
          assign o = { width_p {1'b0} };

          // synopsys translate_off

          initial assert(harden_p==0) else $error("## %m wanted to harden but no macro");

          // synopsys translate_on

      end
endmodule
