`define bsg_dff_reset_macro(bits)                                       \
if (harden_p && width_p==bits)                                          \
  begin: macro                                                          \
     bsg_rp_tsmc_40_dff_nreset_s1_b``bits dff(.clk_i                 \
                                               ,.data_i                 \
                                               ,.nreset_i(~reset_i)     \
                                               ,.data_o);               \
  end

module bsg_dff_reset #(width_p=-1, harden_p=1)
   (input   clk_i
    ,input  reset_i
    ,input  [width_p-1:0] data_i
    ,output [width_p-1:0] data_o
    );

    `bsg_dff_reset_macro(90)
     else    `bsg_dff_reset_macro(89)
     else    `bsg_dff_reset_macro(88)
     else    `bsg_dff_reset_macro(87)
     else    `bsg_dff_reset_macro(86)
     else    `bsg_dff_reset_macro(85)
     else    `bsg_dff_reset_macro(84)
     else    `bsg_dff_reset_macro(83)
     else    `bsg_dff_reset_macro(82)
     else    `bsg_dff_reset_macro(81)
     else    `bsg_dff_reset_macro(80)
     else    `bsg_dff_reset_macro(79)
     else    `bsg_dff_reset_macro(78)
     else    `bsg_dff_reset_macro(77)
     else    `bsg_dff_reset_macro(76)
     else    `bsg_dff_reset_macro(75)
     else    `bsg_dff_reset_macro(74)
     else    `bsg_dff_reset_macro(73)
     else    `bsg_dff_reset_macro(72)
     else    `bsg_dff_reset_macro(71)
     else    `bsg_dff_reset_macro(70)
     else    `bsg_dff_reset_macro(69)
     else    `bsg_dff_reset_macro(68)
     else    `bsg_dff_reset_macro(67)
     else    `bsg_dff_reset_macro(66)
     else    `bsg_dff_reset_macro(65)
     else    `bsg_dff_reset_macro(64)
     else    `bsg_dff_reset_macro(63)
     else    `bsg_dff_reset_macro(62)
     else    `bsg_dff_reset_macro(61)
     else    `bsg_dff_reset_macro(60)
     else    `bsg_dff_reset_macro(59)
     else    `bsg_dff_reset_macro(58)
     else    `bsg_dff_reset_macro(57)
     else    `bsg_dff_reset_macro(56)
     else    `bsg_dff_reset_macro(55)
     else    `bsg_dff_reset_macro(54)
     else    `bsg_dff_reset_macro(53)
     else    `bsg_dff_reset_macro(52)
     else    `bsg_dff_reset_macro(51)
     else    `bsg_dff_reset_macro(50)
     else    `bsg_dff_reset_macro(49)
     else    `bsg_dff_reset_macro(48)
     else    `bsg_dff_reset_macro(47)
     else    `bsg_dff_reset_macro(46)
     else    `bsg_dff_reset_macro(45)
     else    `bsg_dff_reset_macro(44)
     else    `bsg_dff_reset_macro(43)
     else    `bsg_dff_reset_macro(42)
     else    `bsg_dff_reset_macro(41)
     else    `bsg_dff_reset_macro(40)
     else    `bsg_dff_reset_macro(39)
     else    `bsg_dff_reset_macro(38)
     else    `bsg_dff_reset_macro(37)
     else    `bsg_dff_reset_macro(36)
     else    `bsg_dff_reset_macro(35)
     else    `bsg_dff_reset_macro(34)
     else    `bsg_dff_reset_macro(33)
     else    `bsg_dff_reset_macro(32)
     else    `bsg_dff_reset_macro(31)
     else    `bsg_dff_reset_macro(30)
     else    `bsg_dff_reset_macro(29)
     else    `bsg_dff_reset_macro(28)
     else    `bsg_dff_reset_macro(27)
     else    `bsg_dff_reset_macro(26)
     else    `bsg_dff_reset_macro(25)
     else    `bsg_dff_reset_macro(24)
     else    `bsg_dff_reset_macro(23)
     else    `bsg_dff_reset_macro(22)
     else    `bsg_dff_reset_macro(21)
     else    `bsg_dff_reset_macro(20)
     else    `bsg_dff_reset_macro(19)
     else    `bsg_dff_reset_macro(18)
     else    `bsg_dff_reset_macro(17)
     else    `bsg_dff_reset_macro(16)
     else    `bsg_dff_reset_macro(15)
     else    `bsg_dff_reset_macro(14)
     else    `bsg_dff_reset_macro(13)
     else    `bsg_dff_reset_macro(12)
     else    `bsg_dff_reset_macro(11)
     else    `bsg_dff_reset_macro(10)
     else    `bsg_dff_reset_macro(9)
     else    `bsg_dff_reset_macro(8)
     else    `bsg_dff_reset_macro(7)
     else    `bsg_dff_reset_macro(6)
     else    `bsg_dff_reset_macro(5)
     else    `bsg_dff_reset_macro(4)
     else    `bsg_dff_reset_macro(3)
     else
     begin: notmacro_dff_reset
        reg [width_p-1:0] data_r;

        assign data_o = data_r;

        always @(posedge clk_i)
          begin
             if (reset_i)
               data_r <= width_p ' (0);
             else
               data_r <= data_i;
          end
     end
endmodule
