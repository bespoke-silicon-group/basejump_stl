// creates an array of shift registers, with independently
// controlled three input muxes,
// 0=keep value, 1=get prev value,2=set new value
//
//

`define bsg_fifo_shift_datapath_macro(words,bits)                             \
        if (els_p == words && width_p == bits)                                \
          begin: macro                                                        \
             bsg_rp_tsmc_250_fifo_shift_w``words``_b``bits w``words``_b``bits \
               (.*                                                            \
                , .sel_one_hot_i(sel_onehot)                                  \
                );                                                            \
          end



module bsg_fifo_shift_datapath #(parameter  width_p    = "inv"
                                 ,parameter els_p      = "inv"
                                 ,parameter default_p  = { (width_p) {1'b0} }
                                 )
   (input   clk_i
    , input [width_p-1:0]    data_i
    , input [els_p-1:0][1:0] sel_i
    , output [width_p-1:0]   data_o
    );

   initial assert (default_p == 0) else $error("do not handle default_p != 0");

   logic [els_p*3-1:0] sel_onehot;

   genvar            i;

   for (i = 0; i < els_p; i++)
     begin: el
        assign sel_onehot[i*3+:3] = 3 ' (1 << sel_i[i]);
     end

   `bsg_fifo_shift_datapath_macro(16,32)
       else `bsg_fifo_shift_datapath_macro(8,32)
       else `bsg_fifo_shift_datapath_macro(4,32)
       else initial assert (1==0) else $error("unhandled case for tsmc 250 bsg_fifo_shift_datapath");

endmodule
