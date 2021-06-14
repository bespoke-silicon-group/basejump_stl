/**************************** TEST RATIONALE *******************************

1. STATE SPACE

	The number of possible inputs for each WIDTH_P is very large and moreover,
  the implementation of the DUT itself is independent of the value of input.
  So thermometer codes are used as test inputs and thus limiting the
  number of test inputs to WIDTH_P+1.

2. PARAMETERIZATION

	An arbitrary set of tests including edge cases might be sufficient. So a 
  minimum set of tests might be WIDTH_P = 1,2,3,4.

***************************************************************************/

module test_bsg 
#(parameter width_p=`WIDTH_P,
  parameter sim_clk_period_p=10,
  parameter reset_cycles_lo_p=0,
  parameter reset_cycles_hi_p=5
  );

  wire clk;
  wire reset;
<<<<<<< HEAD

<<<<<<< HEAD
  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_p)
                          )  clock_gen
                          (  .o(clk)
                          );
||||||| merged common ancestors
  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
   #(.cycle_time_p(sim_clk_period))
   clock_gen
    (.o(clk));
=======
  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
   #(.cycle_time_p(sim_clk_period_p))
   clock_gen
    (.o(clk));
>>>>>>> parameter name fix

||||||| merged common ancestors
  
  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_lp)
                          )  clock_gen
                          (  .o(clk)
                          );
    
=======

  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
   #(.cycle_time_p(sim_clk_period))
   clock_gen
    (.o(clk));

>>>>>>> bsg_dff verilatable testbench
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk) 
                           , .async_reset_o(reset)
                          );

  initial
  begin
    $display("\n\n\n");
    $display("============================================================\n");
    $display(  "testing with ...\n"
             , "WIDTH_P: %d\n", width_p
            );
  end

  logic [width_p-1:0] p_test_input, test_input, test_output;
  logic finish_r;

  always_ff @(posedge clk)
  begin
    if(reset)
      begin
        test_input <= width_p'(1'b0);
        finish_r   <= 1'b0;
      end
    else
      begin  
        test_input <= (test_input<<1)+1;
        if(p_test_input != test_output) 
          $error("mismatch on input %x", p_test_input);
      end
    
    p_test_input <= test_input;
    
    // $display("clk=%d reset=%d input=%d output=%d p_test_input=%d",clk,reset,test_input,test_output,p_test_input);

    if(&p_test_input)
      finish_r <= 1'b1;
    if(finish_r)
      begin
        $display("===========================================================\n");
        $finish;
      end
  end
    
  bsg_dff #(  .width_p(width_p)
           )  DUT 
           (  .clk_i(clk)
            , .data_i(test_input)
            , .data_o(test_output)
           );      
 
endmodule
