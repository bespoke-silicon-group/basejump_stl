
`include "bsg_defines.sv"

`define bsg_clkinv_macro(bits)                                   \
if (harden_p && (width_p==bits))                              \
  begin: macro                                                \
    for (genvar j = 0; j < width_p; j++)                      \
      begin : b                                               \
        CKND8BWP7T40P140 cb_BSG_RESIZE_OK (.I(i[j]), .ZN(o[j])); \
      end                                                     \
  end

module bsg_clkinv #(parameter `BSG_INV_PARAM(width_p)
                 , parameter harden_p=0
                 , parameter strength_p=8
                 )
   (input    [width_p-1:0] i
    , output [width_p-1:0] o
    );

   `bsg_clkinv_macro(89) else
   `bsg_clkinv_macro(88) else
   `bsg_clkinv_macro(87) else
   `bsg_clkinv_macro(86) else
   `bsg_clkinv_macro(85) else
   `bsg_clkinv_macro(84) else
   `bsg_clkinv_macro(83) else
   `bsg_clkinv_macro(82) else
   `bsg_clkinv_macro(81) else
   `bsg_clkinv_macro(80) else
   `bsg_clkinv_macro(79) else
   `bsg_clkinv_macro(78) else
   `bsg_clkinv_macro(77) else
   `bsg_clkinv_macro(76) else
   `bsg_clkinv_macro(75) else
   `bsg_clkinv_macro(74) else
   `bsg_clkinv_macro(73) else
   `bsg_clkinv_macro(72) else
   `bsg_clkinv_macro(71) else
   `bsg_clkinv_macro(70) else
   `bsg_clkinv_macro(69) else
   `bsg_clkinv_macro(68) else
   `bsg_clkinv_macro(67) else
   `bsg_clkinv_macro(66) else
   `bsg_clkinv_macro(65) else
   `bsg_clkinv_macro(64) else
   `bsg_clkinv_macro(63) else
   `bsg_clkinv_macro(62) else
   `bsg_clkinv_macro(61) else
   `bsg_clkinv_macro(60) else
   `bsg_clkinv_macro(59) else
   `bsg_clkinv_macro(58) else
   `bsg_clkinv_macro(57) else
   `bsg_clkinv_macro(56) else
   `bsg_clkinv_macro(55) else
   `bsg_clkinv_macro(54) else
   `bsg_clkinv_macro(53) else
   `bsg_clkinv_macro(52) else
   `bsg_clkinv_macro(51) else
   `bsg_clkinv_macro(50) else
   `bsg_clkinv_macro(49) else
   `bsg_clkinv_macro(48) else
   `bsg_clkinv_macro(47) else
   `bsg_clkinv_macro(46) else
   `bsg_clkinv_macro(45) else
   `bsg_clkinv_macro(44) else
   `bsg_clkinv_macro(43) else
   `bsg_clkinv_macro(42) else
   `bsg_clkinv_macro(41) else
   `bsg_clkinv_macro(40) else
   `bsg_clkinv_macro(39) else
   `bsg_clkinv_macro(38) else
   `bsg_clkinv_macro(37) else
   `bsg_clkinv_macro(36) else
   `bsg_clkinv_macro(35) else
   `bsg_clkinv_macro(34) else
   `bsg_clkinv_macro(33) else
   `bsg_clkinv_macro(32) else
   `bsg_clkinv_macro(31) else
   `bsg_clkinv_macro(30) else
   `bsg_clkinv_macro(29) else
   `bsg_clkinv_macro(28) else
   `bsg_clkinv_macro(27) else
   `bsg_clkinv_macro(26) else
   `bsg_clkinv_macro(25) else
   `bsg_clkinv_macro(24) else
   `bsg_clkinv_macro(23) else
   `bsg_clkinv_macro(22) else
   `bsg_clkinv_macro(21) else
   `bsg_clkinv_macro(20) else
   `bsg_clkinv_macro(19) else
   `bsg_clkinv_macro(18) else
   `bsg_clkinv_macro(17) else
   `bsg_clkinv_macro(16) else
   `bsg_clkinv_macro(15) else
   `bsg_clkinv_macro(14) else
   `bsg_clkinv_macro(13) else
   `bsg_clkinv_macro(12) else
   `bsg_clkinv_macro(11) else
   `bsg_clkinv_macro(10) else
   `bsg_clkinv_macro(9) else
   `bsg_clkinv_macro(8) else
   `bsg_clkinv_macro(7) else
   `bsg_clkinv_macro(6) else
   `bsg_clkinv_macro(5) else
   `bsg_clkinv_macro(4) else
   `bsg_clkinv_macro(3) else
   `bsg_clkinv_macro(2) else
   `bsg_clkinv_macro(1) else
       begin :notmacro
         BSG_SYNTH_HARDEN_ATTEMPT(harden_p)

         assign o = ~i;
      end
endmodule

`BSG_ABSTRACT_MODULE(bsg_clkinv)
