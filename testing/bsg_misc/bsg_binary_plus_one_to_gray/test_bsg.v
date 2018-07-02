`define WIDTH_P 12


module test_bsg;

//`include "test_bsg_clock_params.v"

   localparam cycle_time_lp = 20;

   wire clk;
   wire reset;
   localparam width_lp = `WIDTH_P;

   bsg_nonsynth_clock_gen #(.cycle_time_p(cycle_time_lp)) clock_gen
   (.o(clk));

   bsg_nonsynth_reset_gen #(.reset_cycles_lo_p(5)
                           ,.reset_cycles_hi_p(5)
                           ) reset_gen
     (.clk_i(clk)
      ,.async_reset_o(reset)
      );

   logic [width_lp-1:0] test_inputs, test_inputs_r;
   wire [width_lp-1:0]     test_output;

   wire [width_lp-1:0] 	   tip1 = (test_inputs + 1'b1);

   always_ff @(posedge clk)
     begin
	assert (test_output == (tip1>>1)^tip1)
	  else $error("mismatch on input %x",test_inputs);

        test_inputs_r <= test_inputs;

        if (~(|test_inputs) & (&test_inputs_r))
          $finish();
     end

   bsg_cycle_counter #(.width_p(width_lp)) bcc
     (.clk_i(clk)
      ,.reset_i(reset)
      ,.ctr_r_o(test_inputs)
      );

   bsg_binary_plus_one_to_gray #(.width_p(width_lp)) dut
     (
      .binary_i(test_inputs)
      ,.gray_o  (test_output)
      );




   bsg_nonsynth_ascii_writer
     #(.width_p(width_lp)
       ,.values_p(3)
       ,.filename_p("output.log")
       ,.fopen_param_p("w")
       ,.format_p("%x  ")
       ) ascii_writer
   (.clk     (clk)
    ,.reset_i(reset)
    ,.valid_i(1'b1)
    ,.data_i ({ test_output,
		(tip1 >> 1) ^ tip1,
                test_inputs
                }
              )
    );

endmodule
