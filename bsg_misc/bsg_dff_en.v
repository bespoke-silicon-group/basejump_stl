module bsg_dff_en #(width_p="inv"
                    , harden_p=1   // mbt fixme: maybe this should not be a default
                    , strength_p=1
                    )
   (input   clock_i
    ,input  [width_p-1:0] data_i
    ,input  en_i
    ,output [width_p-1:0] data_o
    );

   reg [width_p-1:0] data_r;

   assign data_o = data_r;

   always @(posedge clock_i)
     if (en_i)
       data_r <= data_i;

endmodule
