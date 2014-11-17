// MBT 11/10/14
//
// bsg_round_robin_n_to_1
//
// this is intended to merge the outputs of several fifos
// together to act as one.
//
// assumes a valid yumi interface
//

module bsg_round_robin_n_to_1 #(parameter width_p = -1
                                ,parameter num_in_p = 2)
   (input  clk_i
    , input  reset_i

    // to fifos
    , input  [num_in_p-1:0][width_p-1:0] data_i
    , input  [num_in_p-1:0] valid_i
    , output [num_in_p-1:0] yumi_o

    // to downstream
    , output [width_p-1:0] data_o
    , output valid_o
    , input  yumi_i
    );

   wire [$clog2(num_in_p)-1:0] ptr_r;

   bsg_circular_ptr #(.slots_p(num_in_p)
                      ,.max_add_p(1)
                      ) circular_ptr
     (.clk     (clk_i)
      ,.reset_i(reset_i)
      ,.add_i  (yumi_i)
      ,.o      (ptr_r)
      );

   assign valid_o = valid_i[ptr_r];
   assign data_o  = data_i [ptr_r];

   genvar 			 i;

   // binary to one hot
   assign yumi_o = (yumi_i << ptr_r);

endmodule

