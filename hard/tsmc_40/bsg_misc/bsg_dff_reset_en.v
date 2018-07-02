// for whatever reason, strength 1 has very bad setup and hold times

`define bsg_dff_reset_en_macro(bits)                                    \
if (harden_p && width_p==bits)                                          \
  begin: macro                                                          \
     bsg_rp_tsmc_40_dff_nreset_en_s2_b``bits dff(.clk_i              \
                                               ,.data_i                 \
                                               ,.en_i                   \
                                               ,.nreset_i(~reset_i)     \
                                               ,.data_o);               \
  end

module bsg_dff_reset_en #(width_p=-1, harden_p=1)
   (input   clk_i
    ,input  reset_i    
    ,input  [width_p-1:0] data_i
    ,input  en_i
 
    ,output [width_p-1:0] data_o
    );

   `bsg_dff_reset_en_macro(33)
     else    `bsg_dff_reset_en_macro(32)
     else    `bsg_dff_reset_en_macro(31)
     else    `bsg_dff_reset_en_macro(30)
     else    `bsg_dff_reset_en_macro(29)
     else    `bsg_dff_reset_en_macro(28)
     else    `bsg_dff_reset_en_macro(27)
     else    `bsg_dff_reset_en_macro(26)
     else    `bsg_dff_reset_en_macro(25)
     else    `bsg_dff_reset_en_macro(24)
     else    `bsg_dff_reset_en_macro(23)
     else    `bsg_dff_reset_en_macro(22)
     else    `bsg_dff_reset_en_macro(21)
     else    `bsg_dff_reset_en_macro(20)
     else    `bsg_dff_reset_en_macro(19)
     else    `bsg_dff_reset_en_macro(18)
     else    `bsg_dff_reset_en_macro(17)
     else    `bsg_dff_reset_en_macro(16)
     else    `bsg_dff_reset_en_macro(15)
     else    `bsg_dff_reset_en_macro(14)
     else    `bsg_dff_reset_en_macro(13)
     else    `bsg_dff_reset_en_macro(12)
     else    `bsg_dff_reset_en_macro(11)
     else    `bsg_dff_reset_en_macro(10)
     else    `bsg_dff_reset_en_macro(9)
     else    `bsg_dff_reset_en_macro(8)
     else    `bsg_dff_reset_en_macro(7)
     else    `bsg_dff_reset_en_macro(6)
     else    `bsg_dff_reset_en_macro(5)
     else    `bsg_dff_reset_en_macro(4)
     else    `bsg_dff_reset_en_macro(3)
     else    `bsg_dff_reset_en_macro(2)
     else    `bsg_dff_reset_en_macro(1)
     else
     begin: notmacro
        reg [width_p-1:0] data_r;

        assign data_o = data_r;

        always @(posedge clk_i)
          begin
             if (reset_i)
               data_r <= width_p ' (0);
             else
               if (en_i)
                 data_r <= data_i;
          end
     end
endmodule
