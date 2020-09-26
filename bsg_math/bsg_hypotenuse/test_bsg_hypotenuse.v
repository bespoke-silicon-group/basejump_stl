


`include "bsg_defines.v"

module test_bsg_hypotenuse;

//`include "test_bsg_clock_params.v"

   localparam cycle_time_lp = 20;

   wire clk;
   wire reset;
   localparam width_lp = 12;

   bsg_nonsynth_clock_gen #(.cycle_time_p(cycle_time_lp)) clock_gen
   (.o(clk));

   bsg_nonsynth_reset_gen #(.reset_cycles_lo_p(5)
                           ,.reset_cycles_hi_p(5)
                           ) reset_gen
     (.clk_i(clk)
      ,.async_reset_o(reset)
      );

   logic [width_lp*2-1:0] test_inputs, test_inputs_delayed, test_inputs_delayed_r;
   wire [width_lp:0]     test_output;

   always_ff @(posedge clk)
     begin
        test_inputs_delayed_r <= test_inputs_delayed;

        if (~(|test_inputs_delayed) & (&test_inputs_delayed_r))
          $finish();
     end

   bsg_cycle_counter #(.width_p(width_lp*2)) bcc
     (.clk_i(clk)
      ,.reset_i(reset)
      ,.ctr_r_o(test_inputs)
      );

   bsg_hypotenuse #(.width_p(width_lp)) bed
   (.clk(clk)
    ,.x_i(test_inputs[0+:width_lp])
    ,.y_i(test_inputs[width_lp+:width_lp])
    ,.o  (test_output)
    );

   wire bsg_v;

   // we use this to pass meta data in parallel
   // to the values being computed. this
   // might be a return packet header if we were
   // using this inside a bsg_test_node
   //
   
   bsg_shift_reg #(.width_p(width_lp*2)
                   ,.stages_p(width_lp+4)
                   ) bsr
     (.clk     (clk)
      ,.reset_i(reset)
      ,.valid_i(1'b1)
      ,.data_i (test_inputs)
      ,.valid_o(bsg_v)
      ,.data_o (test_inputs_delayed)
      );

   localparam width_p1_lp = width_lp + 1;

   bsg_nonsynth_ascii_writer
     #(.width_p(width_lp+1)
       ,.values_p(3)
       ,.filename_p("output.log")
       ,.format_p("w")
       ) ascii_writer
   (.clk     (clk)
    ,.reset_i(reset)
    ,.valid_i(bsg_v)
    ,.data_i ({ test_output
                , width_p1_lp ' (test_inputs_delayed[0+:width_lp])
                , width_p1_lp ' (test_inputs_delayed[width_lp+:width_lp])
                }
              )
    );

endmodule

