`define bsg_buf_macro(bits)                                   \
if (harden_p && (width_p==bits) && vertical_p)                \
  begin: macro                                                \
     bsg_rp_tsmc_40_BUFFD8BWP_b``bits buf_gate (.i0(i),.o);      \
  end                                                         \
else                                                          \
if (harden_p && (width_p==bits) && ~vertical_p)               \
  begin: macro                                                \
     bsg_rp_tsmc_40_BUFFD8BWP_horiz_b``bits buf_gate (.i0(i),.o);\
   end

module bsg_buf #(parameter width_p="inv"
                 , parameter harden_p=1
		 , parameter vertical_p=1
                 )
   (input    [width_p-1:0] i
    , output [width_p-1:0] o
    );

   `bsg_buf_macro(89) else
   `bsg_buf_macro(88) else
   `bsg_buf_macro(87) else
   `bsg_buf_macro(86) else
   `bsg_buf_macro(85) else
   `bsg_buf_macro(84) else
   `bsg_buf_macro(83) else
   `bsg_buf_macro(82) else
   `bsg_buf_macro(81) else
   `bsg_buf_macro(80) else
   `bsg_buf_macro(79) else
   `bsg_buf_macro(78) else
   `bsg_buf_macro(77) else
   `bsg_buf_macro(76) else
   `bsg_buf_macro(75) else
   `bsg_buf_macro(74) else
   `bsg_buf_macro(73) else
   `bsg_buf_macro(72) else
   `bsg_buf_macro(71) else
   `bsg_buf_macro(70) else
   `bsg_buf_macro(69) else
   `bsg_buf_macro(68) else
   `bsg_buf_macro(67) else
   `bsg_buf_macro(66) else
   `bsg_buf_macro(65) else
   `bsg_buf_macro(64) else
   `bsg_buf_macro(63) else
   `bsg_buf_macro(62) else
   `bsg_buf_macro(61) else
   `bsg_buf_macro(60) else
   `bsg_buf_macro(59) else
   `bsg_buf_macro(58) else
   `bsg_buf_macro(57) else
   `bsg_buf_macro(56) else
   `bsg_buf_macro(55) else
   `bsg_buf_macro(54) else
   `bsg_buf_macro(53) else
   `bsg_buf_macro(52) else
   `bsg_buf_macro(51) else
   `bsg_buf_macro(50) else
   `bsg_buf_macro(49) else
   `bsg_buf_macro(48) else
   `bsg_buf_macro(47) else
   `bsg_buf_macro(46) else
   `bsg_buf_macro(45) else
   `bsg_buf_macro(44) else
   `bsg_buf_macro(43) else
   `bsg_buf_macro(42) else
   `bsg_buf_macro(41) else
   `bsg_buf_macro(40) else
   `bsg_buf_macro(39) else
   `bsg_buf_macro(38) else
   `bsg_buf_macro(37) else
   `bsg_buf_macro(36) else
   `bsg_buf_macro(35) else
   `bsg_buf_macro(34) else
   `bsg_buf_macro(33) else
   `bsg_buf_macro(32) else
   `bsg_buf_macro(31) else
   `bsg_buf_macro(30) else
   `bsg_buf_macro(29) else
   `bsg_buf_macro(28) else
   `bsg_buf_macro(27) else
   `bsg_buf_macro(26) else
   `bsg_buf_macro(25) else
   `bsg_buf_macro(24) else
   `bsg_buf_macro(23) else
   `bsg_buf_macro(22) else
   `bsg_buf_macro(21) else
   `bsg_buf_macro(20) else
   `bsg_buf_macro(19) else
   `bsg_buf_macro(18) else
   `bsg_buf_macro(17) else
   `bsg_buf_macro(16) else
   `bsg_buf_macro(15) else
   `bsg_buf_macro(14) else
   `bsg_buf_macro(13) else
   `bsg_buf_macro(12) else
   `bsg_buf_macro(11) else
   `bsg_buf_macro(10) else
   `bsg_buf_macro(9) else
   `bsg_buf_macro(8) else
   `bsg_buf_macro(7) else
   `bsg_buf_macro(6) else
   `bsg_buf_macro(5) else
   `bsg_buf_macro(4) else
   `bsg_buf_macro(3) else
   `bsg_buf_macro(2) else
   `bsg_buf_macro(1) else
       begin :notmacro
          initial assert(harden_p==0) else $error("## %m wanted to harden but no macro");

             assign o = i;
      end
endmodule
