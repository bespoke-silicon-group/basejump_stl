`define bsg_dff_reset_macro(bits)                                       \
if (harden_p && width_p==bits)                                          \
  begin: macro                                                          \
     bsg_rp_tsmc_250_dff_nreset_s1_b``bits dff(.clock_i                 \
                                               ,.data_i                 \
                                               ,.nreset_i(~reset_i)     \
                                               ,.data_o);               \
  end

module bsg_dff_reset #(width_p=-1, harden_p=1)
   (input   clock_i
    ,input  [width_p-1:0] data_i
    ,input  reset_i
    ,output [width_p-1:0] data_o
    );

   `bsg_dff_reset_macro(33)
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

        always @(posedge clock_i)
          begin
             if (reset_i)
               data_r <= width_p ' (0);
             else
               data_r <= data_i;
          end
     end
endmodule
