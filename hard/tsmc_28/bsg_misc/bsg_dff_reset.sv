
`include "bsg_defines.sv"

`define bsg_dff_reset_macro(bits,strength)                      \
if (harden_p && (width_p==bits) && (strength_p==strength) && (reset_val_p==0)) \
  begin: macro                                                \
    for (genvar j = 0; j < width_p; j++)                      \
      begin : d                                               \
        DFKCNQD``strength``BWP7T40P140 d_BSG_DONT_TOUCH (.CP(clk_i), .CN(reset_i), .D(data_i[j]), .Q(data_o[j])); \
      end                                                     \
  end

module bsg_dff_reset #(`BSG_INV_PARAM(width_p), harden_p=0, reset_val_p=0, strength_p=1)
    (input clk_i
    , input reset_i
    , input [width_p-1:0] data_i
    , output [width_p-1:0] data_o
    );

   `bsg_dff_reset_macro(80,1) else
   `bsg_dff_reset_macro(79,1) else
   `bsg_dff_reset_macro(78,1) else
   `bsg_dff_reset_macro(77,1) else
   `bsg_dff_reset_macro(76,1) else
   `bsg_dff_reset_macro(75,1) else
   `bsg_dff_reset_macro(74,1) else
   `bsg_dff_reset_macro(73,1) else
   `bsg_dff_reset_macro(72,1) else
   `bsg_dff_reset_macro(71,1) else
   `bsg_dff_reset_macro(70,1) else
   `bsg_dff_reset_macro(69,1) else
   `bsg_dff_reset_macro(68,1) else
   `bsg_dff_reset_macro(67,1) else
   `bsg_dff_reset_macro(66,1) else
   `bsg_dff_reset_macro(65,1) else
   `bsg_dff_reset_macro(64,1) else
   `bsg_dff_reset_macro(63,1) else
   `bsg_dff_reset_macro(62,1) else
   `bsg_dff_reset_macro(61,1) else
   `bsg_dff_reset_macro(60,1) else
   `bsg_dff_reset_macro(59,1) else
   `bsg_dff_reset_macro(58,1) else
   `bsg_dff_reset_macro(57,1) else
   `bsg_dff_reset_macro(56,1) else
   `bsg_dff_reset_macro(55,1) else
   `bsg_dff_reset_macro(54,1) else
   `bsg_dff_reset_macro(53,1) else
   `bsg_dff_reset_macro(52,1) else
   `bsg_dff_reset_macro(51,1) else
   `bsg_dff_reset_macro(50,1) else
   `bsg_dff_reset_macro(49,1) else
   `bsg_dff_reset_macro(48,1) else
   `bsg_dff_reset_macro(47,1) else
   `bsg_dff_reset_macro(46,1) else
   `bsg_dff_reset_macro(45,1) else
   `bsg_dff_reset_macro(44,1) else
   `bsg_dff_reset_macro(43,1) else
   `bsg_dff_reset_macro(42,1) else
   `bsg_dff_reset_macro(41,1) else      
   `bsg_dff_reset_macro(40,1) else
   `bsg_dff_reset_macro(39,1) else
   `bsg_dff_reset_macro(38,1) else
   `bsg_dff_reset_macro(37,1) else
   `bsg_dff_reset_macro(36,1) else
   `bsg_dff_reset_macro(35,1) else
   `bsg_dff_reset_macro(34,1) else
   `bsg_dff_reset_macro(33,1) else
   `bsg_dff_reset_macro(32,1) else
   `bsg_dff_reset_macro(31,1) else
   `bsg_dff_reset_macro(30,1) else
   `bsg_dff_reset_macro(29,1) else
   `bsg_dff_reset_macro(28,1) else
   `bsg_dff_reset_macro(27,1) else
   `bsg_dff_reset_macro(26,1) else
   `bsg_dff_reset_macro(25,1) else
   `bsg_dff_reset_macro(24,1) else
   `bsg_dff_reset_macro(23,1) else
   `bsg_dff_reset_macro(22,1) else
   `bsg_dff_reset_macro(21,1) else      
   `bsg_dff_reset_macro(20,1) else
   `bsg_dff_reset_macro(19,1) else
   `bsg_dff_reset_macro(18,1) else
   `bsg_dff_reset_macro(17,1) else
   `bsg_dff_reset_macro(16,1) else
   `bsg_dff_reset_macro(15,1) else
   `bsg_dff_reset_macro(14,1) else
   `bsg_dff_reset_macro(13,1) else
   `bsg_dff_reset_macro(12,1) else
   `bsg_dff_reset_macro(11,1) else
   `bsg_dff_reset_macro(10,1) else
   `bsg_dff_reset_macro(9,1) else
   `bsg_dff_reset_macro(8,1) else
   `bsg_dff_reset_macro(7,1) else
   `bsg_dff_reset_macro(6,1) else
   `bsg_dff_reset_macro(5,1) else
   `bsg_dff_reset_macro(4,1) else
   `bsg_dff_reset_macro(3,1) else
   `bsg_dff_reset_macro(2,1) else
   `bsg_dff_reset_macro(1,1) else
   `bsg_dff_reset_macro(40,2) else
   `bsg_dff_reset_macro(39,2) else
   `bsg_dff_reset_macro(38,2) else
   `bsg_dff_reset_macro(37,2) else
   `bsg_dff_reset_macro(36,2) else
   `bsg_dff_reset_macro(35,2) else
   `bsg_dff_reset_macro(34,2) else
   `bsg_dff_reset_macro(33,2) else
   `bsg_dff_reset_macro(32,2) else
   `bsg_dff_reset_macro(31,2) else
   `bsg_dff_reset_macro(30,2) else
   `bsg_dff_reset_macro(29,2) else
   `bsg_dff_reset_macro(28,2) else
   `bsg_dff_reset_macro(27,2) else
   `bsg_dff_reset_macro(26,2) else
   `bsg_dff_reset_macro(25,2) else
   `bsg_dff_reset_macro(24,2) else
   `bsg_dff_reset_macro(23,2) else
   `bsg_dff_reset_macro(22,2) else
   `bsg_dff_reset_macro(21,2) else      
   `bsg_dff_reset_macro(20,2) else
   `bsg_dff_reset_macro(19,2) else
   `bsg_dff_reset_macro(18,2) else
   `bsg_dff_reset_macro(17,2) else
   `bsg_dff_reset_macro(16,2) else
   `bsg_dff_reset_macro(15,2) else
   `bsg_dff_reset_macro(14,2) else
   `bsg_dff_reset_macro(13,2) else
   `bsg_dff_reset_macro(12,2) else
   `bsg_dff_reset_macro(11,2) else
   `bsg_dff_reset_macro(10,2) else
   `bsg_dff_reset_macro(9,2) else
   `bsg_dff_reset_macro(8,2) else
   `bsg_dff_reset_macro(7,2) else
   `bsg_dff_reset_macro(6,2) else
   `bsg_dff_reset_macro(5,2) else
   `bsg_dff_reset_macro(4,2) else
   `bsg_dff_reset_macro(3,2) else
   `bsg_dff_reset_macro(2,2) else
   `bsg_dff_reset_macro(1,2) else
   `bsg_dff_reset_macro(40,4) else
   `bsg_dff_reset_macro(39,4) else
   `bsg_dff_reset_macro(38,4) else
   `bsg_dff_reset_macro(37,4) else
   `bsg_dff_reset_macro(36,4) else
   `bsg_dff_reset_macro(35,4) else
   `bsg_dff_reset_macro(34,4) else
   `bsg_dff_reset_macro(33,4) else
   `bsg_dff_reset_macro(32,4) else
   `bsg_dff_reset_macro(31,4) else
   `bsg_dff_reset_macro(30,4) else
   `bsg_dff_reset_macro(29,4) else
   `bsg_dff_reset_macro(28,4) else
   `bsg_dff_reset_macro(27,4) else
   `bsg_dff_reset_macro(26,4) else
   `bsg_dff_reset_macro(25,4) else
   `bsg_dff_reset_macro(24,4) else
   `bsg_dff_reset_macro(23,4) else
   `bsg_dff_reset_macro(22,4) else
   `bsg_dff_reset_macro(21,4) else
   `bsg_dff_reset_macro(20,4) else
   `bsg_dff_reset_macro(19,4) else
   `bsg_dff_reset_macro(18,4) else
   `bsg_dff_reset_macro(17,4) else
   `bsg_dff_reset_macro(16,4) else
   `bsg_dff_reset_macro(15,4) else
   `bsg_dff_reset_macro(14,4) else
   `bsg_dff_reset_macro(13,4) else
   `bsg_dff_reset_macro(12,4) else
   `bsg_dff_reset_macro(11,4) else
   `bsg_dff_reset_macro(10,4) else
   `bsg_dff_reset_macro(9,4) else
   `bsg_dff_reset_macro(8,4) else
   `bsg_dff_reset_macro(7,4) else
   `bsg_dff_reset_macro(6,4) else
   `bsg_dff_reset_macro(5,4) else
   `bsg_dff_reset_macro(4,4) else
   `bsg_dff_reset_macro(3,4) else
   `bsg_dff_reset_macro(2,4) else
   `bsg_dff_reset_macro(1,4) else
   `bsg_dff_reset_macro(32,2)
    else
   `bsg_dff_reset_macro(32,8)
     else
     begin: notmacro
        logic [width_p-1:0] data_r;

        assign data_o = data_r;

        always @(posedge clk_i)
          if (reset_i)
            data_r <= width_p'(reset_val_p);
          else
            data_r <= data_i;
     end
endmodule

`BSG_ABSTRACT_MODULE(bsg_dff_reset)
