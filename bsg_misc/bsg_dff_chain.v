//====================================================================
// bsg_dff_chain.v
// 04/01/2018, shawnless.xie@gmail.com
//====================================================================
//
// Pass the input singal to a chainded  DFF registers

`include "bsg_defines.v"

module bsg_dff_chain #(
                 //the width of the input signal
                 parameter       width_p         =       -1

                 //the stages of the chained DFF register
                 //can be 0
                ,parameter       num_stages_p    =       1
        )
        (
                 input                           clk_i
                ,input [width_p-1:0]             data_i
                ,output[width_p-1:0]             data_o
        );

        if( num_stages_p == 0) begin:pass_through
                assign data_o   = data_i;
        end:pass_through

        else begin:chained
                // data_i -- delayed[0]
                //
                // data_o -- delayed[num_stages_p]
                logic [num_stages_p:0][width_p-1:0] data_delayed;

                assign data_delayed[0]  = data_i                        ;
                assign data_o           = data_delayed[num_stages_p]    ;

                genvar i;
                for(i=1; i<= num_stages_p; i++) begin
                        bsg_dff #( .width_p ( width_p ) )
                                ch_reg (
                                        .clk_i        ( clk_i                 )
                                       ,.data_i         ( data_delayed[ i-1 ]   )
                                       ,.data_o         ( data_delayed[ i   ]   )
                                );
                end

        end:chained

endmodule
