// for whatever reason, strength 1 has very bad setup and hold times

`define bsg_dff_reset_en_macro(bits)                                    \
if (harden_p && width_p==bits)                                          \
  begin: macro                                                          \
     bsg_rp_tsmc_250_dff_nreset_en_s2_b``bits dff(.clock_i              \
                                               ,.data_i                 \
                                               ,.en_i                   \
                                               ,.nreset_i(~reset_i)     \
                                               ,.data_o);               \
  end

module bsg_dff_reset_en #(width_p=-1, harden_p=1)
   (input   clock_i
    ,input  [width_p-1:0] data_i
    ,input  en_i
    ,input  reset_i
    ,output [width_p-1:0] data_o
    );

   `bsg_dff_reset_en_macro(32)
     else    `bsg_dff_reset_en_macro(33)
     else    `bsg_dff_reset_en_macro(30)
     else    `bsg_dff_reset_en_macro(29)
     else    `bsg_dff_reset_en_macro(16)
     else    `bsg_dff_reset_en_macro(15)
     else    `bsg_dff_reset_en_macro(8)
     else
     begin: notmacro
        reg [width_p-1:0] data_r;

        assign data_o = data_r;

        always @(posedge clock_i)
          begin
             if (reset_i)
               data_r <= width_p ' (0);
             else
               if (en_i)
                 data_r <= data_i;
          end
     end
endmodule
