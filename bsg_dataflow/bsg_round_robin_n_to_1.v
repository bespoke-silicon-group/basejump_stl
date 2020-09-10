// MBT 11/10/14
//
// bsg_round_robin_n_to_1
//
// this is intended to merge the outputs of several fifos
// together to act as one.
//
// assumes a valid yumi interface
//
// strict_p: determines whether the round_robin
// module blocks until the head FIFO is valid, or if it just
// goes to the next one.
//
//

`include "bsg_defines.v"

module bsg_round_robin_n_to_1 #(parameter width_p = -1
                                ,parameter num_in_p = -1
                                ,parameter strict_p = "inv" 
                                ,parameter tag_width_lp = `BSG_SAFE_CLOG2(num_in_p)
                                )
   (input  clk_i
    , input  reset_i

    // to fifos
    , input  [num_in_p-1:0][width_p-1:0] data_i
    , input  [num_in_p-1:0] v_i
    , output [num_in_p-1:0] yumi_o

    // to downstream
    , output v_o
    , output [width_p-1:0]     data_o
    , output [tag_width_lp-1:0] tag_o
    , input  yumi_i
    );

   if (strict_p)
     begin : strict
        wire [tag_width_lp-1:0] ptr_r;

        bsg_circular_ptr #(.slots_p(num_in_p)
                           ,.max_add_p(1)
                           ) circular_ptr
          (.clk     (clk_i  )
           ,.reset_i(reset_i)
           ,.add_i  (yumi_i )
           ,.o      (ptr_r  )
           ,.n_o    ()
           );

        assign v_o = v_i [ptr_r];
        assign data_o  = data_i  [ptr_r];

        assign tag_o = ptr_r;

        // binary to one hot
        assign yumi_o = (num_in_p) ' (yumi_i << tag_o);

     end
   else
     begin : greedy

        wire [num_in_p-1:0] grants_lo;

        // we have valid output if any input is valid
        // we do not need the arb to determine this
        // the signal yumi_i is computed from this

        // assign v_o = | v_i;

        bsg_round_robin_arb #(.inputs_p(num_in_p))
        rr_arb_ctrl
          (.clk_i
           ,.reset_i
           ,.grants_en_i(1'b1)

	   // "data plane"
           ,.reqs_i   (v_i  ) // from each of the nodes
           ,.grants_o (grants_lo)
           ,.sel_one_hot_o()

           ,.v_o     ( v_o  )
           ,.tag_o   (tag_o    )
           ,.yumi_i  (yumi_i & v_o )  // based on v_o, downstream
                                  // node decides if it will accept
           );

        bsg_crossbar_o_by_i #(.i_els_p (num_in_p)
                              ,.o_els_p(1       )
                              ,.width_p(width_p)
                              ) xbar
          (.i                (data_i   )
           ,.sel_oi_one_hot_i(grants_lo)
           ,.o               (data_o   )
           );

        // mask grants with yumi signal
        assign yumi_o = grants_lo & { num_in_p { yumi_i }};

     end


endmodule

