// MBT 8-15-2014
//
// Compare two values and swap them if they are not in order
//
// t_p .. t_b: inclusive range of bits
//
// cond_swap_on_equal_p enables a mode where we will conditional swap
// if the values are equal.
//
// This can be used to "fix" instability in a sorting network.
//
//
// FIXME: untested.
//


`include "bsg_defines.v"

module bsg_compare_and_swap #(parameter width_p="inv"
                             , parameter t_p = width_p-1
                             , parameter b_p = 0
                             , parameter cond_swap_on_equal_p=0)
(input    [1:0] [width_p-1:0] data_i
 , input  swap_on_equal_i
 , output logic [1:0] [width_p-1:0] data_o
 , output swapped_o
 );

   wire gt = data_i[0][t_p:b_p] > data_i[1][t_p:b_p];

   if (cond_swap_on_equal_p)
     begin
       wire eq = (data_i[0][t_p:b_p] == data_i[1][t_p:b_p]);
       assign swapped_o = gt | (eq & swap_on_equal_i);
     end
   else
     assign swapped_o = gt;

   always_comb
     begin
       if (swapped_o)
         data_o = { data_i[0], data_i[1] };
       else
         data_o = { data_i[1], data_i[0] };
     end

endmodule // bsg_compare_and_swap
