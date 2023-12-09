`include "bsg_defines.sv"

module bsg_decode_with_v #(parameter `BSG_INV_PARAM(num_out_p))
   (

    input [`BSG_SAFE_CLOG2(num_out_p)-1:0] i
    ,input v_i
    ,output [num_out_p-1:0] o
    );

   wire [num_out_p-1:0]                    lo;

   bsg_decode #(.num_out_p(num_out_p)
                ) bd
     (.i
      ,.o(lo)
      );

   assign o = { (num_out_p) { v_i } } & lo;

endmodule

`BSG_ABSTRACT_MODULE(bsg_decode_with_v)
