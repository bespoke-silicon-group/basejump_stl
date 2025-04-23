// MBT 11/10/14
//
// bsg_round_robin_1_to_n
//
// this is intended to take one input and send it to
// one of several channels in round robin order.
//
// assumings a valid/ready interface
//
// we omit the data part as it is just duplication.
//

`include "bsg_defines.sv"

module bsg_round_robin_1_to_n #(parameter `BSG_INV_PARAM(num_out_p ))
   (input  clk_i
    , input  reset_i

    // from one fifo
    , input               valid_i
    , output              ready_and_o
    
    // to many
    , output  [num_out_p-1:0]  valid_o
    , input   [num_out_p-1:0]  ready_and_i

    // to downstream
    );

   // If only one output, feed through the signals
   if (num_out_p == 1)
     begin: one_to_one
        assign valid_o = valid_i;
        assign ready_and_o = ready_and_i;
     end
   else
     begin: one_to_n
     
       wire [`BSG_SAFE_CLOG2(num_out_p)-1:0] ptr_r;
       // The data for the current fifo has been consumed
       wire yumi_li = valid_i & ready_and_o;
       
       bsg_circular_ptr #(.slots_p(num_out_p)
                          ,.max_add_p(1)
                          ) circular_ptr
         (.clk     (clk_i  )
          ,.reset_i(reset_i)
          ,.add_i  (yumi_li )
          ,.o      (ptr_r  )
          ,.n_o    ()
          );

       // bsg_decode_with_v could potentially be used to optimize this critical path 
       // at the cost of area
       assign valid_o = (valid_i << ptr_r);

       // binary to one hot
       assign ready_and_o = ready_and_i[ptr_r];
       
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_round_robin_1_to_n)

