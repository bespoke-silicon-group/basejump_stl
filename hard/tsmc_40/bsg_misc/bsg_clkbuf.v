`define bsg_clkbuf_macro(bits,strength)                        \
if (harden_p && (width_p==bits) && (strength==strength_p))     \
  begin: macro                                                 \
     bsg_rp_tsmc_40_CLKBUFX``strength``_b``bits clkbuf_gate (.i0(i),.o); \
  end

module bsg_clkbuf #(parameter width_p=1
		 , parameter strength_p=8
                 , parameter harden_p=1
                 )
   (input    [width_p-1:0] i
    , output [width_p-1:0] o
    );

   `bsg_clkbuf_macro(1,20) else
   `bsg_clkbuf_macro(1,16) else
   `bsg_clkbuf_macro(1,12) else
   `bsg_clkbuf_macro(1,8) else
   `bsg_clkbuf_macro(1,4) else
   `bsg_clkbuf_macro(1,3) else
   `bsg_clkbuf_macro(1,2) else
   `bsg_clkbuf_macro(1,1) else
       begin :notmacro

        assign o = i;

        // synopsys translate_off

        initial assert(harden_p==0) else $error("## %m wanted to harden but no macro");

        // synopsys translate_on

      end
endmodule
