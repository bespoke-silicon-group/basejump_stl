`define bsg_dff_en_macro(bits,womp)                                          \
if (harden_p && width_p==bits && (strength_p==womp))                         \
  begin: macro                                                               \
     bsg_rp_tsmc_40_EDFD``womp``BWP_b``bits dff(.i0(data_i)                   \
                                                 ,.i1({ width_p { en_i }  }) \
                                                 ,.i2({ width_p {clk_i} }) \
                                                 ,.o(data_o)                 \
                                               );                            \
  end


module bsg_dff_en #(width_p="inv"
                    , harden_p=1
                    , strength_p=1
                    )
   (input   clk_i
    ,input  [width_p-1:0] data_i
    ,input  en_i
    ,output [width_p-1:0] data_o
    );

   `bsg_dff_en_macro(40,1) else
   `bsg_dff_en_macro(39,1) else
   `bsg_dff_en_macro(38,1) else
   `bsg_dff_en_macro(37,1) else
   `bsg_dff_en_macro(36,1) else
   `bsg_dff_en_macro(35,1) else
   `bsg_dff_en_macro(34,1) else
   `bsg_dff_en_macro(33,1) else
   `bsg_dff_en_macro(32,1) else
   `bsg_dff_en_macro(31,1) else
   `bsg_dff_en_macro(30,1) else
   `bsg_dff_en_macro(29,1) else
   `bsg_dff_en_macro(28,1) else
   `bsg_dff_en_macro(27,1) else
   `bsg_dff_en_macro(26,1) else
   `bsg_dff_en_macro(25,1) else
   `bsg_dff_en_macro(24,1) else
   `bsg_dff_en_macro(23,1) else
   `bsg_dff_en_macro(22,1) else
   `bsg_dff_en_macro(21,1) else
   `bsg_dff_en_macro(20,1) else
   `bsg_dff_en_macro(19,1) else
   `bsg_dff_en_macro(18,1) else
   `bsg_dff_en_macro(17,1) else
   `bsg_dff_en_macro(16,1) else
   `bsg_dff_en_macro(15,1) else
   `bsg_dff_en_macro(14,1) else
   `bsg_dff_en_macro(13,1) else
   `bsg_dff_en_macro(12,1) else
   `bsg_dff_en_macro(11,1) else
   `bsg_dff_en_macro(10,1) else
   `bsg_dff_en_macro(9,1) else
   `bsg_dff_en_macro(8,1) else
   `bsg_dff_en_macro(7,1) else
   `bsg_dff_en_macro(6,1) else
   `bsg_dff_en_macro(5,1) else
   `bsg_dff_en_macro(4,1) else
   `bsg_dff_en_macro(3,1) else
   `bsg_dff_en_macro(2,1) else
   `bsg_dff_en_macro(1,1) else
   `bsg_dff_en_macro(40,2) else
   `bsg_dff_en_macro(39,2) else
   `bsg_dff_en_macro(38,2) else
   `bsg_dff_en_macro(37,2) else
   `bsg_dff_en_macro(36,2) else
   `bsg_dff_en_macro(35,2) else
   `bsg_dff_en_macro(34,2) else
   `bsg_dff_en_macro(33,2) else
   `bsg_dff_en_macro(32,2) else
   `bsg_dff_en_macro(31,2) else
   `bsg_dff_en_macro(30,2) else
   `bsg_dff_en_macro(29,2) else
   `bsg_dff_en_macro(28,2) else
   `bsg_dff_en_macro(27,2) else
   `bsg_dff_en_macro(26,2) else
   `bsg_dff_en_macro(25,2) else
   `bsg_dff_en_macro(24,2) else
   `bsg_dff_en_macro(23,2) else
   `bsg_dff_en_macro(22,2) else
   `bsg_dff_en_macro(21,2) else
   `bsg_dff_en_macro(20,2) else
   `bsg_dff_en_macro(19,2) else
   `bsg_dff_en_macro(18,2) else
   `bsg_dff_en_macro(17,2) else
   `bsg_dff_en_macro(16,2) else
   `bsg_dff_en_macro(15,2) else
   `bsg_dff_en_macro(14,2) else
   `bsg_dff_en_macro(13,2) else
   `bsg_dff_en_macro(12,2) else
   `bsg_dff_en_macro(11,2) else
   `bsg_dff_en_macro(10,2) else
   `bsg_dff_en_macro(9,2) else
   `bsg_dff_en_macro(8,2) else
   `bsg_dff_en_macro(7,2) else
   `bsg_dff_en_macro(6,2) else
   `bsg_dff_en_macro(5,2) else
   `bsg_dff_en_macro(4,2) else
   `bsg_dff_en_macro(3,2) else
   `bsg_dff_en_macro(2,2) else
   `bsg_dff_en_macro(1,2) else
   `bsg_dff_en_macro(40,4) else
   `bsg_dff_en_macro(39,4) else
   `bsg_dff_en_macro(38,4) else
   `bsg_dff_en_macro(37,4) else
   `bsg_dff_en_macro(36,4) else
   `bsg_dff_en_macro(35,4) else
   `bsg_dff_en_macro(34,4) else
   `bsg_dff_en_macro(33,4) else
   `bsg_dff_en_macro(32,4) else
   `bsg_dff_en_macro(31,4) else
   `bsg_dff_en_macro(30,4) else
   `bsg_dff_en_macro(29,4) else
   `bsg_dff_en_macro(28,4) else
   `bsg_dff_en_macro(27,4) else
   `bsg_dff_en_macro(26,4) else
   `bsg_dff_en_macro(25,4) else
   `bsg_dff_en_macro(24,4) else
   `bsg_dff_en_macro(23,4) else
   `bsg_dff_en_macro(22,4) else
   `bsg_dff_en_macro(21,4) else
   `bsg_dff_en_macro(20,4) else
   `bsg_dff_en_macro(19,4) else
   `bsg_dff_en_macro(18,4) else
   `bsg_dff_en_macro(17,4) else
   `bsg_dff_en_macro(16,4) else
   `bsg_dff_en_macro(15,4) else
   `bsg_dff_en_macro(14,4) else
   `bsg_dff_en_macro(13,4) else
   `bsg_dff_en_macro(12,4) else
   `bsg_dff_en_macro(11,4) else
   `bsg_dff_en_macro(10,4) else
   `bsg_dff_en_macro(9,4) else
   `bsg_dff_en_macro(8,4) else
   `bsg_dff_en_macro(7,4) else
   `bsg_dff_en_macro(6,4) else
   `bsg_dff_en_macro(5,4) else
   `bsg_dff_en_macro(4,4) else
   `bsg_dff_en_macro(3,4) else
   `bsg_dff_en_macro(2,4) else
   `bsg_dff_en_macro(1,4) else

   begin : notmacro
      reg [width_p-1:0] data_r;

      assign data_o = data_r;

      always @(posedge clk_i)
        if (en_i)
          data_r <= data_i;
   end
endmodule
